FROM hevelop/php-devtools:7.4-1.1.0

RUN echo "memory_limit=3G" >> /usr/local/etc/php/conf.d/zz-php.ini

RUN docker-php-ext-enable xdebug

RUN apt-get remove -y nodejs

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get install -y nodejs \
    && npm i -g grunt-cli yarn

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["php", "-A"]
