#!/bin/bash
set -e
echo "frontaccounting - FrontAccounting on Debian 8 Docker Container"

# set constants
FA_PROD_TAG="2.4.3"
MYSQL_TAG="5.6"
WEBROOT="/var/www/html"
OLDINDEX="/root/oldfiles/index.html"
OLDKEY="/root/oldfiles/ssl-cert-snakeoil.key"
OLDCERT="/root/oldfiles/ssl-cert-snakeoil.pem"
SSLKEY="/etc/ssl/private/ssl-cert-snakeoil.key"
SSLCERT="/etc/ssl/certs/ssl-cert-snakeoil.pem"

show_usage ()
{
    echo
    echo "usage: genebarker/frontaccounting [options]"
    echo
    echo "Options:"
    echo "  -p, --http         Run FA using plain HTTP (port 80)"
    echo "  -s, --https FQDN   Run FA using HTTPS (port 443)"
    echo "  -S, --hsts FQDN    Run FA using HSTS (ports 80 and 443)"
    echo "  -t, --tag TAG      Version of FA webapp to use"
    echo "                     (defaults to $FA_PROD_TAG)"
    echo "  -b, --branch NAME  Use latest commit in given branch of "
    echo "                     FA webapp repository"
    echo "  -O, --overwrite    Overwrite existing FA webapp content with"
    echo "                     the repository's version (careful!)"
    echo "  -h, --help         Display this message"
    echo
    echo "To use FA webapp content on the host, mount it, i.e.:"
    echo "  $ docker run -d -p 80:80 \\"
    echo "      -v /home/me/frontacc:/var/www/html \\"
    echo "      genebarker/frontaccounting --http"
    echo
    echo "  (if host dir empty, the container will initialize it)"
    echo
    echo "To run FA with HTTPS creating new self-signed keys:"
    echo "  $ docker run -d -p 443:443 \\"
    echo "      genebarker/frontaccounting --https mybox.example.com"
    echo
    echo "To run FA with HTTPS using your own keys, mount them, i.e.:"
    echo "  $ docker run -d -p 443:443 \\"
    echo "      -v /etc/ssl:/etc/ssl \\"
    echo "      genebarker/frontaccounting --https mybox.example.com"
    echo
    echo "  (the cert's CN must match the FQDN)"
    echo
    echo "To run FA with HSTS, map both web ports, i.e.:"
    echo "  $ docker run -d -p 80:80 -p 443:443 \\"
    echo "      genebarker/frontaccounting --hsts mybox.example.com"
    echo
    echo "To link FA with a MySQL container named 'fa_db', i.e.:"
    echo "  $ docker run -d -p 80:80 \\"
    echo "      --link fa_db:fa_db \\"
    echo "      genebarker/frontaccounting --http"
    echo
    echo "  (then use 'fa_db' for the MySQL hostname)"
    echo
    echo "To bypass script, just enter desired command, i.e.:"
    echo "  $ docker run -it genebarker/frontaccounting bash"
    echo
    echo "FA webapp repository:"
    echo "  https://github.com/genebarker/FA (see its Wiki)"
    echo
    echo "Key paths in the container:"
    echo "  /var/www/html  - FA webapp content"
    echo "  /etc/ssl       - SSL keys and certificates"
    echo "  /etc/ssl/private/ssl-cert-snakeoil.key  - Private SSL key"
    echo "  /etc/ssl/certs/ssl-cert-snakeoil.pem    - Public SSL cert"
    echo
    echo "FA requires a MySQL DB for data storage, we recommend using:"
    echo "  mysql:$MYSQL_TAG image at https://hub.docker.com/_/mysql/"
}

init_content ()
{
    # check for existing content
    if [ "$(ls -A $WEBROOT)" ]; then
        echo "info: found existing webapp content at '$WEBROOT'"
        if [ $overwrite == 0 ]; then
            echo "info: using existing webapp content"
            return
        else
            echo "info: overwriting existing FA webapp content"
        fi
    fi
    # select correct content in repository
    cd /root/FA
    if [ -z "$branch" ]; then
        # use tag method
        if git checkout -b thisone $tag ; then
            echo "info: FA version '$tag' checked-out successfully"
        else
            echo "error: FA version '$tag' does not exist or can't be checked-out" >&2
            exit 1
        fi
    else
        # use branch method
        if git checkout $branch ; then
            echo "info: FA branch '$branch' checked-out successfully"
        else
            echo "error: FA branch '$branch' does not exist or can't be checked out" >&2
            exit 1
        fi
    fi
    # copy content from repository
    cp -R /root/FA/* /var/www/html
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    echo "info: FA webapp content initialized successfully"
}

config_ssl ()
{
    # check if new key and cert needed
    set +e
    cmp $OLDKEY $SSLKEY > /dev/null
    SAMEKEY=$?
    cmp $OLDCERT $SSLCERT > /dev/null
    SAMECERT=$?
    set -e
    if [[ $SAMEKEY -eq 0 ]] || [[ $SAMECERT -eq 0 ]]; then
        echo "info: no existing keys found, so creating..."
        # create new self-signed secure ones
        openssl genrsa -out $SSLKEY 2048
        openssl req -new -x509 -sha256 -days 3653 -key $SSLKEY -out $SSLCERT -subj "/CN=$fqdn"
        echo "info: created new self-signed keys successfully"
    else
        echo "info: found existing keys"
    fi
    # set apache ServerName globally
    sed -i "/# Global configuration/a ServerName $fqdn" /etc/apache2/apache2.conf
    echo "info: set server name to '$fqdn'"
    # set accepetable SSL ciphers
    sed -i 's/SSLCipherSuite HIGH:!aNULL.*/SSLCipherSuite ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS/' /etc/apache2/mods-available/ssl.conf
    echo "info: set server to use secure ciphers"
    # enable SSL
    a2enmod ssl
    # enable SSL site
    ln -sf /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf
    echo "info: ssl setup successfully"
}

# initialize var's that can be set via options
protocol=
fqdn=
tag=$FA_PROD_TAG
branch=
overwrite=0

# if no arguments provided, just show usage
if [ "$#" == "0" ]; then
    show_usage
    exit 1
fi

# if first argument is not an option, execute it as a command
if [[ $1 != -* ]]; then
    init_content
    exec "$@"
    exit
fi

# evaluate options
while true; do
    case "$1" in
        -p|--http)
            protocol=http
            ;;
        -s|--https)
            if [ -n "$2" ]; then
                protocol=https
                fqdn=$2
                shift
            else
                echo 'error: "--https" option requires a FQDN' >&2
                exit 1
            fi
            ;;
        -S|--hsts)
            if [ -n "$2" ]; then
                protocol=hsts
                fqdn=$2
                shift
            else
                echo "error: '--hsts' option requires a FQDN" >&2
                exit 1
            fi
            ;;
        -t|--tag)
            if [ -n "$2" ]; then
                tag=$2
                shift
            else
                echo "error: '--tag' option requires a tag name" >&2
                exit 1
            fi
            ;;
        -b|--branch)
            if [ -n "$2" ]; then
                branch=$2
                shift
            else
                echo "error: '--branch' option requires a branch name" >&2
                exit 1
            fi
            ;;
        -O|--overwrite)
            overwrite=1
            ;;
        -h|-\?|--help)
            show_usage
            exit
            ;;
        --) # end of all options
            shift
            break
            ;;
        -?*) # unknown option
            echo "error: unknown option found '$1'" >&2
            exit 1
            ;;
        *)  # no more options
            break
    esac
    # consume option
    shift
done

if [ -z "$protocol" ]; then
    echo "error: a '--http' , '--https', or '--hsts' protocol option must be selected" >&2
    exit 1
elif [ "$protocol" == 'http' ]; then
    # initialize FA webapp content
    init_content
    # start apache2
    exec apache2ctl -D FOREGROUND
    exit
elif [ "$protocol" == 'https' ]; then
    # initialize FA webapp content
    init_content
    # configure SSL
    config_ssl
    # start apache2
    exec apache2ctl -D FOREGROUND
    exit
elif [ "$protocol" == 'hsts' ]; then
    # initialize FA webapp content
    init_content
    # setup the HTTP redirect
    sed -i "s/DocumentRoot \/var\/www\/html.*/Redirect permanent \/ https:\/\/$fqdn\//" /etc/apache2/sites-available/000-default.conf
    # configure SSL
    config_ssl
    # start apache2
    exec apache2ctl -D FOREGROUND
    exit
else
    echo "fatal: bug in script" >&2
    exit 1
fi
