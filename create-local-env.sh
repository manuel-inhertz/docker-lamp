#!/bin/bash

echo "- Automate procedure to create a local development environment with docker - "

if [ "$#" -lt "1" ]; then
	echo "> Usage: sudo ./create-local-env.sh project-name php-v"
	exit 1;
fi

if [ "$#" -lt "2" ]; then
    echo "> Please specify a php version from either these: php54, php56, php71, php72, php73, php74"
    exit 1;
fi

# Controllo se esiste gia il vhost conf nel server
echo "> Enter the domain name which the webserver will respond followed by ENTER:"
read ADDRESS

DIR="$(pwd)/$1"

echo
echo "> Creating the root folder $DIR..."
mkdir $DIR
mkdir $DIR/public_html
mkdir $DIR/private_html

echo "> Copying docker configurations"

cp -R ./docker $DIR/docker

touch $DIR/docker/.env

echo "# Please Note: 
# - In PHP Versions <= 7.4 MySQL8 is not supported due to lacking pdo support

# To determine the name of your containers
COMPOSE_PROJECT_NAME=$1

# Possible values: php54, php56, php71, php72, php73, php74
PHPVERSION=$2
DOCUMENT_ROOT=$DIR
VHOSTS_DIR=./config/vhosts
APACHE_LOG_DIR=./logs/apache2
PHP_INI=./config/php/php.ini

# Possible values: mariadb, mysql, mysql8
DATABASE=mariadb
MYSQL_DATA_DIR=./data/mysql
MYSQL_LOG_DIR=./logs/mysql

# If you already have the port 80 in use, you can change it (for example if you have Apache)
HOST_MACHINE_UNSECURE_HOST_PORT=80
HOST_MACHINE_SECURE_HOST_PORT=443

# If you already have the port 3306 in use, you can change it (for example if you have MySQL)
HOST_MACHINE_MYSQL_PORT=3306

# If you already have the port 8080 in use, you can change it
HOST_MACHINE_PMA_PORT=8080

# If you already has the port 6379 in use, you can change it (for example if you have Redis)
HOST_MACHINE_REDIS_PORT=6379

# MySQL root user password
MYSQL_ROOT_PASSWORD=root

# Database settings: Username, password and database name
MYSQL_USER=docker
MYSQL_PASSWORD=docker
MYSQL_DATABASE=$1" >> $DIR/docker/.env

FILE_VHOST="./docker/config/vhosts/$1.conf"
touch $FILE_VHOST

echo "> Creating the Apache configuration..."
echo 
echo "> Inserting, if any, the Alias (separated by a space):"
read ALIAS

echo "<VirtualHost *:80>" >> $FILE_VHOST
echo "DocumentRoot /var/www/html/public_html" >> $FILE_VHOST
echo "ServerName $ADDRESS" >> $FILE_VHOST

# Aggiungo gli alias al file vhost solo se presenti
if [ -n "$ALIAS" ]; then echo "ServerAlias $ALIAS" >> $FILE_VHOST;
fi

echo "<Directory /var/www/html/public_html>" >> $FILE_VHOST
echo "allow from all" >> $FILE_VHOST
echo "Options FollowSymLinks MultiViews" >> $FILE_VHOST
echo "AllowOverride All" >> $FILE_VHOST
echo "Require all granted" >> $FILE_VHOST
echo "####################
# Mod expire
####################
<ifModule mod_gzip.c>
    mod_gzip_on Yes
    mod_gzip_dechunk Yes
    mod_gzip_item_include file .(html?|txt|css|js|php|pl)$
    mod_gzip_item_include handler ^cgi-script$
    mod_gzip_item_include mime ^text/.*
    mod_gzip_item_include mime ^application/x-javascript.*
    mod_gzip_item_exclude mime ^image/.*
    mod_gzip_item_exclude rspheader ^Content-Encoding:.*gzip.*
</ifModule>

####################
# Expire headers
####################
<ifModule mod_expires.c>
    ExpiresActive On
    ExpiresDefault \"access plus 5 seconds\"
    ExpiresByType image/x-icon \"access plus 2592000 seconds\"
    ExpiresByType image/jpeg \"access plus 2592000 seconds\"
    ExpiresByType image/png \"access plus 2592000 seconds\"
    ExpiresByType image/gif \"access plus 2592000 seconds\"
    ExpiresByType application/x-shockwave-flash \"access plus 2592000 seconds\"
    ExpiresByType text/css \"access plus 86400 seconds\"
    ExpiresByType text/javascript \"access plus 86400 seconds\"
    ExpiresByType application/javascript \"access plus 86400 seconds\"
    ExpiresByType application/x-javascript \"access plus 86400 seconds\"
    ExpiresByType text/html \"access plus 600 seconds\"
    ExpiresByType application/xhtml+xml \"access plus 600 seconds\"

    AddType application/vnd.ms-fontobject .eot
    AddType application/x-font-ttf .ttf
    AddType application/x-font-opentype .otf
    AddType application/x-font-woff .woff .woff2
    AddType image/svg+xml .svg

    ExpiresByType application/vnd.ms-fontobject \"access plus 2592000 seconds\"
    ExpiresByType application/x-font-ttf \"access plus 2592000 seconds\"
    ExpiresByType application/x-font-opentype \"access plus 2592000 seconds\"
    ExpiresByType application/x-font-woff \"access plus 2592000 seconds\"
    ExpiresByType image/svg+xml \"access plus 2592000 seconds\"
</ifModule>

########################
# Cache-Control Headers
########################
<ifModule mod_headers.c>
    <filesMatch \"\.(ico|jpe?g|png|gif|swf)$\">
      Header set Cache-Control \"public\"
    </filesMatch>
    <filesMatch \"\.(css)$\">
      Header set Cache-Control \"public\"
    </filesMatch>
    <filesMatch \"\.(js)$\">
      Header set Cache-Control \"private\"
    </filesMatch>
    <filesMatch \"\.(x?html?|php)$\">
      Header set Cache-Control \"private, must-revalidate\"
    </filesMatch>
</ifModule>" >> $FILE_VHOST
echo "</Directory>" >> $FILE_VHOST
echo "</VirtualHost>" >> $FILE_VHOST

echo "> Creating a dns record on the local hosts file"

echo "127.0.0.1 $ADDRESS $ALIAS" >> /etc/hosts

echo "> Run docker configurations"

cd $DIR/docker/

docker-compose up -d

echo "> Here's all the configurations that are running:

## apache2
You can visit your site at:

http://$ADDRESS

## phpMyAdmin

phpMyAdmin is configured to run on port 8080. Use following default credentials.

http://localhost:8080/  

USER=docker
PASSWORD=docker
DATABASE=$1

## Redis

It comes with Redis. It runs on default port '6379'."

echo "DONE!"
