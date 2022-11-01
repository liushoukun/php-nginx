FROM liushoukun/php-nginx-base:8.1


ARG APP_CODE_PATH=./
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
# install application dependencies
WORKDIR /var/www/app
COPY ${APP_CODE_PATH}composer.json ${APP_CODE_PATH}composer.lock* ./
RUN composer install --no-scripts --no-autoloader --ansi --no-interaction --no-dev -vvv

# copy php config files
COPY docker/php-fpm/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/php-fpm/laravel.ini /usr/local/etc/php/conf.d
COPY docker/php-fpm/xlaravel.pool.conf /usr/local/etc/php-fpm.d/

# copy nginx configuration
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# copy application code
WORKDIR /var/www/app
COPY ${APP_CODE_PATH} .
RUN composer dump-autoload -o \
    && chown -R :www-data /var/www/app \
    && chmod -R 775 /var/www/app/storage /var/www/app/bootstrap/cache


COPY docker/supervisord/supervisord.conf /etc/supervisord.conf
COPY docker/supervisord/conf/*  /etc/supervisord/


###########################################################################
# Crontab
###########################################################################


COPY ./docker/crontab /etc/cron.d

RUN chmod -R 644 /etc/cron.d

EXPOSE 80

# run supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
