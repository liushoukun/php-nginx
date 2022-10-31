FROM liushoukun/php-nginx-base:8.1



# install application dependencies
WORKDIR /var/www/app
COPY ./src/composer.json ./src/composer.lock* ./
RUN composer install --no-scripts --no-autoloader --ansi --no-interaction --no-dev

# add custom php-fpm pool settings, these get written at entrypoint startup
ENV FPM_PM_MAX_CHILDREN=20 \
    FPM_PM_START_SERVERS=2 \
    FPM_PM_MIN_SPARE_SERVERS=1 \
    FPM_PM_MAX_SPARE_SERVERS=3



# copy entrypoint files
#COPY ./docker/docker-php-* /usr/local/bin/
#RUN dos2unix /usr/local/bin/docker-php-entrypoint
#RUN dos2unix /usr/local/bin/docker-php-entrypoint-dev
#
#RUN  chmod 755 /usr/local/bin/docker-php-entrypoint \
#    && chmod 755 /usr/local/bin/docker-php-entrypoint-dev

# copy php config files
COPY docker/php-fpm/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/php-fpm/laravel.ini /usr/local/etc/php/conf.d
COPY docker/php-fpm/xlaravel.pool.conf /usr/local/etc/php-fpm.d/

# copy nginx configuration
COPY docker/config/nginx.conf /etc/nginx/nginx.conf
COPY docker/config/default.conf /etc/nginx/conf.d/default.conf

# copy application code
WORKDIR /var/www/app
COPY ./src .
RUN composer dump-autoload -o \
    && chown -R :www-data /var/www/app \
    && chmod -R 775 /var/www/app/storage /var/www/app/bootstrap/cache


COPY docker/supervisord/supervisord.conf /etc/supervisord.conf
COPY docker/supervisord/conf/*  /etc/supervisord/

EXPOSE 80

# run supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
