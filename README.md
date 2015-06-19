FrontAccounting
---------------
FrontAccounting ([FA]) on Debian 8 (Jessie) with support for strict HTTPS ([HSTS]).

For usage info, just run the image without a command:

```text
$ docker run --rm genebarker/frontaccounting
```

Which produces the following:

```text
frontaccounting - a FrontAccounting on Debian 8 Docker Container

usage: genebarker/frontaccounting [OPTION]

The available OPTIONs are:
   --http        Run FA using plain HTTP
   --hsts FQDN   Run FA using HTTPS only
                 (must provide FQDN, i.e. mybox.example.com)
   --help        Display this message

To use FA webapp content on the host, mount it, i.e.:
   $ docker run -d -p 80:80 \
       -v /home/elvis/frontacc:/var/www/html \
       --name fa_web \
       genebarker/frontaccounting --http

   (if host dir empty, the container will initialize it)

To run FA with strict HTTPS creating new self-signed keys:
   $ docker run -d -p 80:80 -p 443:443 \
       --name fa_web \
       genebarker/frontaccounting --hsts mybox.example.com

To run FA with strict HTTPS using your own keys, mount them, i.e.:
   $ docker run -d -p 80:80 -p 443:443 \
       -v /etc/ssl:/etc/ssl \
       --name fa_web \
       genebarker/frontaccounting --hsts mybox.example.com

   (the cert's CN must match the FQDN)

To link FA with a MySQL container named 'fa_db', i.e.:
   $ docker run -d -p 80:80 \
       --name fa_web
       --link fa_db:fa_db
       genebarker/frontaccounting --http

   (then use 'fa_db' for the MySQL hostname)

To lockdown FA installation scripts after configuration:
   $ docker exec fa_web /lockdown.sh

To bypass script, just enter desired command, i.e.:
   $ docker run -i -t genebarker/frontaccounting bash

Key paths in the container:
   /var/www/html  - FA webapp content
   /etc/ssl       - SSL keys and certificates
   /etc/ssl/private/ssl-cert-snakeoil.key  - Private SSL key
   /etc/ssl/certs/ssl-cert-snakeoil.pem    - Public SSL cert

Note: FA requires a MySQL DB for data storage. We recommend the
      use of the official container images found here:
      https://registry.hub.docker.com/_/mysql/
```

### MySQL ###

[FA] requires a MySQL database for data storage. As per best practice, this [FA] container does not include such a database - this is best served by using your own or even better, using the official MySQL container image ([mysql]).

### Quick Start ###

(1) Spin-up mysql container and create database for FA:

```text
$ docker pull mysql
$ docker run -d -P --name fa_db -e MYSQL_ROOT_PASSWORD=quickDIRTY mysql 
$ docker exec -it fa_db mysqladmin -u root -p create fa23
  (enter quickDIRTY for password)
```

(2) Spin-up FA container:

```text
$ docker pull genebarker/frontaccounting
$ docker run -d -p 80:80 --name fa_web --link fa_db:fa_db genebarker/frontaccounting --http
```

(3) Open browser, enter your host's URL, and on Step 2: Database Server Settings:

- Server Host: `fa_db`
- Database User: `root`
- Database Password: `quickDIRTY`
- Database Name: `fa23`

(4) Enjoy!

[FA]:http://frontaccounting.com/fawiki/
[HSTS]:http://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
[mysql]:https://registry.hub.docker.com/_/mysql/
