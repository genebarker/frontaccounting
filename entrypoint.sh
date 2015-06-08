#!/bin/bash
set -e
echo "initialize deb8frontacc container"

WEBROOT="/var/www/html"
OLDINDEX="/root/oldfiles/index.html"
OLDKEY="/root/oldfiles/ssl-cert-snakeoil.key"
OLDCERT="/root/oldfiles/ssl-cert-snakeoil.pem"
SSLKEY="/etc/ssl/private/ssl-cert-snakeoil.key"
SSLCERT="/etc/ssl/certs/ssl-cert-snakeoil.pem"

init_content ()
{
    cp -R /root/FA/* /var/www/html
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
}

if [ "$#" != "0" ]; then
    CMD="$1"
    if [ "$CMD" == '--http' ]; then
        echo "run FA using plain HTTP..."
        # initialize webapp if no content present
        if [ ! "$(ls -A $WEBROOT)" ]; then
            init_content
        fi
        # start apache2
        exec apache2ctl -D FOREGROUND
        exit
    elif [ "$CMD" == '--hsts' ]; then
        echo "run FA using HTTPS only..."
        if [ "$#" == "1" ]; then
            echo "error: no FQDN provided."
            exit 1
        fi
        FQDN="$2"
	# check if new key and cert needed
        set +e
	cmp $OLDKEY $SSLKEY > /dev/null
        SAMEKEY=$?
        cmp $OLDCERT $SSLCERT > /dev/null
        SAMECERT=$?
        set -e
	if [[ $SAMEKEY -eq 0 ]] || [[ $SAMECERT -eq 0 ]]; then
            # create new self-signed secure ones
            openssl genrsa -out $SSLKEY 2048
            openssl req -new -x509 -sha256 -days 3653 -key $SSLKEY -out $SSLCERT -subj "/CN=$FQDN"
        fi
        # set apache ServerName globally
        sed -i "/# Global configuration/a ServerName $FQDN" /etc/apache2/apache2.conf
	# set accepetable SSL ciphers
	sed -i 's/SSLCipherSuite HIGH:!aNULL.*/SSLCipherSuite ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS/' /etc/apache2/mods-available/ssl.conf
	# set to redirect HTTP to HTTPS (HSTS Strict Transport Security)
	sed -i "s/DocumentRoot \/var\/www\/html.*/Redirect permanent \/ https:\/\/$FQDN\//" /etc/apache2/sites-available/000-default.conf
	# enable SSL
	a2enmod ssl
	# enable SSL site
	ln -sf /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf
        # initialize webapp if no content present
        if [ ! "$(ls -A $WEBROOT)" ]; then
            init_content
        fi
	# start apache2
	exec apache2ctl -D FOREGROUND
        exit
    elif [ $CMD == '--help' ]; then
        echo "show help"
    else
        # initialize webapp if no content present
        if [ ! "$(ls -A $WEBROOT)" ]; then
            init_content
        fi
        exec "$@"
        exit
    fi
fi

echo
echo "usage: genebarker/deb8frontacc [OPTION]"
echo
echo "The available OPTIONs are:"
echo "   --http        Run FA using plain HTTP"
echo "   --hsts FQDN   Run FA using HTTPS only"
echo "                 (must provide FQDN, i.e. mybox.example.com)"
echo "   --help        Display this message"
echo
echo "Note: FA requires a mysql DB for data storage. If you wish to"
echo "      run this DB as a container, see the official mysql repo at"
echo "      https://registry.hub.docker.com/_/mysql/"
echo
echo "Key paths in the container:"
echo "   /var/www/html  - FA webapp content"
echo "   /etc/ssl       - SSL keys and certificates"
echo "   /etc/ssl/private/ssl-cert-snakeoil.key  - Private SSL key"
echo "   /etc/ssl/certs/ssl-cert-snakeoil.pem    - Public SSL cert"
echo
echo "To use FA webapp content on the host, mount it, i.e.:"
echo "   $ docker run -d -p 80:80 \\"
echo "       -v /home/elvis/frontacc:/var/www/html \\"
echo "       genebarker/deb8frontacc --http"
echo
echo "   (if host dir empty, the container will initialize it)"
echo
echo "To run FA with strict HTTPS creating new self-signed keys:"
echo "   $ docker run -d -p 80:80 -p 443:443 \\"
echo "       genebarker/deb8frontacc --hsts mybox.example.com"
echo
echo "To run FA with strict HTTPS using your own keys, mount them, i.e.:"
echo "   $ docker run -d -p 80:80 -p 443:443 \\"
echo "       -v /etc/ssl:/etc/ssl \\"
echo "       genebarker/deb8frontacc --hsts mybox.example.com"
echo
echo "   (the cert's CN must match the FQDN)"
echo
echo "To bypass script, just enter desired command, i.e.:"
echo "   $ docker run -i -t genebarker/deb8frontacc /bin/bash"
echo
exit 0
