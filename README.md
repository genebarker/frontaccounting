## FrontAccounting

FrontAccounting ([FA][1]) on Debian 8 (Jessie) with support for HTTP, HTTPS, and [HSTS][2].

For more infomation, see my article: [Why FrontAccounting][6].

### Improvements

Updated to support FA 2.4! Over 5.4K pulls on [docker][7]. Thank you.

- upgraded FA to 2.4.3 (default)
- upgraded OS to Debian 8.10
- updated Quick Start and notes to use MySQL 5.6
- improved help and this readme

Please note, that this image remains on Debian 8 and recommends MySQL 5.6 to avoid open issues with FA.

## Quick Start

(1) Spin-up mysql container and create database for FA:

```text
$ docker pull mysql:5.6
$ docker run -d -P --name fa_db -e MYSQL_ROOT_PASSWORD=quickDIRTY mysql:5.6
$ docker exec -it fa_db mysqladmin -u root -p create fa24
  (enter quickDIRTY for password)
```

(2) Spin-up FA container:

```text
$ docker pull genebarker/frontaccounting
$ docker run -d -p 80:80 --link fa_db:fa_db genebarker/frontaccounting --http
```

(3) Open browser, enter your host's URL, and on Step 2: Database Server Settings:

- Server Host: `fa_db`
- Database Name: `fa24`
- Database User: `root`
- Database Password: `quickDIRTY`

(4) Enjoy!

## How to Use

For usage info, just run the image without a command:

```text
$ docker run --rm genebarker/frontaccounting
```

Which produces the following:

```text
frontaccounting - FrontAccounting on Debian 8 Docker Container

usage: genebarker/frontaccounting [options]

Options:
  -p, --http         Run FA using plain HTTP (port 80)
  -s, --https FQDN   Run FA using HTTPS (port 443)
  -S, --hsts FQDN    Run FA using HSTS (ports 80 and 443)
  -t, --tag TAG      Version of FA webapp to use
                     (defaults to 2.4.3)
  -b, --branch NAME  Use latest commit in given branch of
                     FA webapp repository
  -O, --overwrite    Overwrite existing FA webapp content with
                     the repository's version (careful!)
  -h, --help         Display this message

To use FA webapp content on the host, mount it, i.e.:
  $ docker run -d -p 80:80 \
      -v /home/me/frontacc:/var/www/html \
      genebarker/frontaccounting --http

  (if host dir empty, the container will initialize it)

To run FA with HTTPS creating new self-signed keys:
  $ docker run -d -p 443:443 \
      genebarker/frontaccounting --https mybox.example.com

To run FA with HTTPS using your own keys, mount them, i.e.:
  $ docker run -d -p 443:443 \
      -v /etc/ssl:/etc/ssl \
      genebarker/frontaccounting --https mybox.example.com

  (the cert's CN must match the FQDN)

To run FA with HSTS, map both web ports, i.e.:
  $ docker run -d -p 80:80 -p 443:443 \
      genebarker/frontaccounting --hsts mybox.example.com

To link FA with a MySQL container named 'fa_db', i.e.:
  $ docker run -d -p 80:80 \
      --link fa_db:fa_db \
      genebarker/frontaccounting --http

  (then use 'fa_db' for the MySQL hostname)

To bypass script, just enter desired command, i.e.:
  $ docker run -it genebarker/frontaccounting bash

FA webapp repository:
  https://github.com/genebarker/FA (see its Wiki)

Key paths in the container:
  /var/www/html  - FA webapp content
  /etc/ssl       - SSL keys and certificates
  /etc/ssl/private/ssl-cert-snakeoil.key  - Private SSL key
  /etc/ssl/certs/ssl-cert-snakeoil.pem    - Public SSL cert

FA requires a MySQL DB for data storage, we recommend using:
  mysql:5.6 at https://hub.docker.com/_/mysql/
```

## Notes

- [FA][1] requires a MySQL 5.6 database for data storage. This FA container does not include such a database - this is best served by using your own or even better, using the official MySQL container image ([mysql][3]).
- The `--tag` and `--branch` options allow you to use this docker image for the different versions of FA. Check the source repository's [Wiki][5] to see the tags and branches currently available.
- This image uses a forked copy [genebarker/FA][4] of the official FA repository. I use this fork to tag the official releases and hold copies of my changes in different branches. For more, see the repository's [Wiki][5].

[1]: http://frontaccounting.com/fawiki/
[2]: http://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
[3]: https://hub.docker.com/_/mysql/
[4]: https://github.com/genebarker/FA
[5]: https://github.com/genebarker/FA/wiki
[6]: http://architect.madman.com/2015/04/why-frontaccounting.html
[7]: https://hub.docker.com/r/genebarker/frontaccounting/
