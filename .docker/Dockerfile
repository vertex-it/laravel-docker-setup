FROM php:8.0-fpm-alpine3.13

LABEL maintainer="Mile Panić"

WORKDIR /var/www/html

ARG HOST_UID
ARG APP_ENV
ARG XDEBUG_ENABLE

ENV APP_ENV ${APP_ENV}
ENV XDEBUG_ENABLE ${XDEBUG_ENABLE}

COPY --from=composer:2.1.12 /usr/bin/composer /usr/bin/composer

# ------------------------ Nginx & Common PHP Dependencies ------------------------
RUN apk update && apk add \
        nginx \
        # see https://github.com/docker-library/php/issues/880
        oniguruma-dev \
        # needed for gd
        libpng-dev libjpeg-turbo-dev \
		# needed for xdebug
		$PHPIZE_DEPS \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # Installing common Laravel dependencies
    && docker-php-ext-install mbstring pdo_mysql gd \
    	# Adding opcache
    	opcache \
    && mkdir -p /home/www-data/.composer/cache \
    && chown -R www-data:www-data /home/www-data/ /var/www/html

# ------------------------ add s6 ------------------------
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.2/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# ------------------------ xdebug ------------------------
RUN if [ "$XDEBUG_ENABLE" = "true" ]; then \
	pecl install xdebug-3.0.0; \
    docker-php-ext-enable xdebug; \
    echo "[xdebug]" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "xdebug.mode=develop,debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
	mv /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled; \
	fi


# ------------------------ start fpm/nginx ------------------------

COPY .docker/s6-overlay/services.d /etc/services.d
COPY .docker/nginx/nginx.conf /etc/nginx/nginx.conf
# TODO Could be named php.conf instead of default.conf?
COPY .docker/nginx/php.conf /etc/nginx/conf.d/default.conf

COPY .docker/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Adding the opcache configuration into the wrong directory intentionally.
# This is enabled at runtime
ADD .docker/php/opcache.ini /usr/local/etc/php/opcache_disabled.ini

ADD .docker/nginx/healthcheck.ini /usr/local/etc/php/healthcheck.ini

RUN rm -rf /var/cache/apk/* && \
        rm -rf /tmp/*

# ------------------------ create user based on provided user id ------------------------
RUN adduser --disabled-password --gecos "" --uid $HOST_UID demouser

# TODO chown needed?
ADD --chown=demouser:demouser . /var/www/html

# ------------------------ change file permission ------------------------
RUN if [ "$APP_ENV" = "production" ]; then \
    find /var/www/html -type d -exec chmod -R 555 {} \; \
        && find /var/www/html -type f -exec chmod -R 444 {} \; \
        && find /var/www/html/storage /var/www/html/bootstrap/cache -type d -exec chmod -R 755 {} \; \
        && find /var/www/html/storage /var/www/html/bootstrap/cache -type f -exec chmod -R 644 {}; \
    fi

EXPOSE 80

ENTRYPOINT ["/init"]
CMD []
