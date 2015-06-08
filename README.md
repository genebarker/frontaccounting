deb8frontacc
------------
FrontAccounting on Debian 8 (Jessie) with support for strict HTTPS (HSTS).

For usage info, just run the image without a command:

```text
$ docker run --rm genebarker/deb8frontacc
```

Which produces the following:

```text
deb8frontacc - a FrontAccounting on Debian 8 Docker Container

usage: genebarker/deb8frontacc [OPTION]

The available OPTIONs are:
   --http        Run FA using plain HTTP
   --hsts FQDN   Run FA using HTTPS only
                 (must provide FQDN, i.e. mybox.example.com)
   --help        Display this message

Note: FA requires a mysql DB for data storage. If you wish to
      run this DB as a container, see the official mysql repo at
      https://registry.hub.docker.com/_/mysql/

Key paths in the container:
   /var/www/html  - FA webapp content
   /etc/ssl       - SSL keys and certificates
   /etc/ssl/private/ssl-cert-snakeoil.key  - Private SSL key
   /etc/ssl/certs/ssl-cert-snakeoil.pem    - Public SSL cert

To use FA webapp content on the host, mount it, i.e.:
   $ docker run -d -p 80:80 \
       -v /home/elvis/frontacc:/var/www/html \
       genebarker/deb8frontacc --http

   (if host dir empty, the container will initialize it)

To run FA with strict HTTPS creating new self-signed keys:
   $ docker run -d -p 80:80 -p 443:443 \
       genebarker/deb8frontacc --hsts mybox.example.com

To run FA with strict HTTPS using your own keys, mount them, i.e.:
   $ docker run -d -p 80:80 -p 443:443 \
       -v /etc/ssl:/etc/ssl \
       genebarker/deb8frontacc --hsts mybox.example.com

   (the cert's CN must match the FQDN)

To bypass script, just enter desired command, i.e.:
   $ docker run -i -t genebarker/deb8frontacc /bin/bash
```