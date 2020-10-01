FROM hevelop/php:7.4-fpm-buster

ARG UNAME=www-data
ARG UID=1000
ARG GID=1000

RUN if grep -q $GID /etc/group; then GROUP_NAME=$(grep :$GID: /etc/group | sed -En "s/(.*):x:$GID:/\1/p") && delgroup $GROUP_NAME; fi;
RUN if grep -q $UNAME /etc/group; then groupmod -g $GID $UNAME; else groupadd -g $GID $UNAME; fi;

RUN usermod -u $UID $UNAME

# Install Xdebug (but don't enable)
RUN pecl install -o -f xdebug

# Install pdo_mysql
RUN docker-php-ext-install pdo_mysql mysqli

# Install netstat for dynamic xdebug remote_host from entrypoint.sh
RUN apt-get update \
    && apt-get install -y net-tools

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /var/www/html

CMD ["php-fpm", "-F", "-R"]
