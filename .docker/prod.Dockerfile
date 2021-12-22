# Install composer dependencies
FROM composer:2.1.12 AS composer-build

WORKDIR /var/www/html

COPY composer.json composer.lock /var/www/html/

RUN mkdir -p /var/www/html/database/{factories,seeds} \
    && composer install --no-dev --prefer-dist --no-scripts --no-autoloader --no-progress --ignore-platform-reqs

# Install NPM dependencies
FROM node:16 AS npm-build

WORKDIR /var/www/html

COPY package.json package-lock.json webpack.mix.js /var/www/html/
COPY resources /var/www/html/resources/
COPY public /var/www/html/public/

RUN npm ci
RUN npm run production

FROM php:8.0-fpm-alpine3.15

LABEL maintainer="Mile Panić"

WORKDIR /var/www/html

# ------------------------ Nginx & Common PHP Dependencies ------------------------
RUN apk update && apk add \
        nginx \
        # see https://github.com/docker-library/php/issues/880
        oniguruma-dev \
        # needed for gd
        libpng-dev libjpeg-turbo-dev \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # Installing common Laravel dependencies
    && docker-php-ext-install mbstring pdo_mysql gd \
    	# Adding opcache
    	opcache

# ------------------------ Add s6 overlay ------------------------
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.2/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# ------------------------ Start php-fpm & nginx ------------------------
COPY .docker/s6-overlay/services.d /etc/services.d
COPY .docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY .docker/nginx/php.conf /etc/nginx/conf.d/default.conf

COPY .docker/php/prod/php.ini /usr/local/etc/php/php.ini
COPY .docker/php/prod/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

ADD .docker/php/prod/opcache.ini /usr/local/etc/php/opcache.ini

# TODO test
ADD .docker/nginx/healthcheck.ini /usr/local/etc/php/healthcheck.ini

RUN rm -rf /var/cache/apk/* && \
        rm -rf /tmp/*

COPY --from=composer:2.1.12 /usr/bin/composer /usr/bin/composer

COPY --chown=www-data --from=composer-build /var/www/html/vendor/ /var/www/html/vendor/
COPY --chown=www-data --from=npm-build /var/www/html/public/ /var/www/html/public/
COPY --chown=www-data . /var/www/html/

RUN composer dumpautoload -o \
    && composer check-platform-reqs \
    && rm -f /usr/bin/composer

EXPOSE 80

ENTRYPOINT ["/init"]
CMD []
