# Install composer dependencies
FROM composer:2.5.4 AS composer-builder

WORKDIR /var/www/html

COPY composer.json composer.lock /var/www/html/

RUN mkdir -p /var/www/html/database/{factories,seeds} \
    && composer install --no-dev --prefer-dist --no-scripts --no-autoloader --no-progress --ignore-platform-reqs

# Install NPM dependencies
FROM node:16 AS npm-builder

WORKDIR /var/www/html

COPY package.json package-lock.json webpack.mix.js /var/www/html/
COPY resources /var/www/html/resources/
COPY public /var/www/html/public/

RUN npm ci
RUN npm run production

# Build production image
FROM php:8.1-fpm-alpine3.17 as final

LABEL maintainer="Mile Panić"

WORKDIR /var/www/html

# ------------------------ Nginx & Common PHP Dependencies ------------------------
RUN apk update && apk add \
        tzdata \
        nginx \
        # see https://github.com/docker-library/php/issues/880
        oniguruma-dev \
        # needed for gd
        freetype-dev libpng-dev libjpeg libjpeg-turbo-dev \
        # install redis
        pcre-dev \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del pcre-dev ${PHPIZE_DEPS} \
    && rm -rf /tmp/pear \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # Installing common Laravel dependencies
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install exif mbstring pdo_mysql gd \
    	# Adding opcache
    	opcache

# ------------------------ Set Timezone ------------------------
ENV TZ=Europe/Sarajevo

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

COPY --from=composer:2.5.4 /usr/bin/composer /usr/bin/composer

COPY --chown=www-data --from=composer-builder /var/www/html/vendor/ /var/www/html/vendor/
COPY --chown=www-data --from=npm-builder /var/www/html/public/ /var/www/html/public/
COPY --chown=www-data . /var/www/html/

RUN composer dumpautoload -o \
    && composer check-platform-reqs \
    && rm -f /usr/bin/composer \
    && rm -rf tests

ENTRYPOINT ["/init"]

# Testing stage for CI
FROM final as testing

LABEL test="true"

COPY ./tests /var/www/html/tests/
COPY --from=final /var/www/html/ /var/www/html/

RUN apk update && apk add pcre-dev ${PHPIZE_DEPS} \
  && pecl install xdebug \
  && docker-php-ext-enable xdebug \
  && apk del pcre-dev ${PHPIZE_DEPS} \
  && echo "[xdebug]xdebug.mode=coverage" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

COPY --from=composer:2.5.4 /usr/bin/composer /usr/bin/composer
RUN composer require phpunit/phpunit:^10.0
