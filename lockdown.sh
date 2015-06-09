#!/bin/bash
set -e
echo "lockdown this deb8frontacc Docker Container"

# switch to FA root directory
cd /var/www/html

# archive the install directory
tar -zcvf install.tar.gz install
rm -rf install

# change the config files to read only
chmod 444 config*.php