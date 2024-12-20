FROM php:8.1-fpm-alpine3.17

LABEL maintainer="Mile Panić"

WORKDIR /var/www/html

ARG HOST_UID
ARG XDEBUG_ENABLE

ENV XDEBUG_ENABLE ${XDEBUG_ENABLE}

# ------------------------ Nginx & Common PHP Dependencies ------------------------
RUN apk update && apk add \
        tzdata \
        nginx \
        # see https://github.com/docker-library/php/issues/880
        oniguruma-dev \
        # needed for gd
        freetype-dev libpng-dev libwebp-dev libjpeg libjpeg-turbo-dev \
		# needed for xdebug
		$PHPIZE_DEPS \
        # install node & npm
        nodejs npm \
        # install redis
        pcre-dev \
        git \
        curl \
        zsh \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del pcre-dev ${PHPIZE_DEPS} \
    && rm -rf /tmp/pear \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # Installing common Laravel dependencies \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install exif mbstring pdo_mysql gd

# ------------------------ Set Timezone ------------------------
ENV TZ=Europe/Sarajevo

# ------------------------ Composer ------------------------
COPY --from=composer:2.5.4 /usr/bin/composer /usr/bin/composer

# ------------------------ Add s6 overlay ------------------------
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.2/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# ------------------------ Install xdebug if enabled ------------------------
RUN if [ "$XDEBUG_ENABLE" = "true" ]; then \
	pecl install xdebug-3.0.0; \
    docker-php-ext-enable xdebug; \
    echo "[xdebug]" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "xdebug.mode=develop,debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
	mv /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled; \
	fi

# ------------------------ Start php-fpm & nginx ------------------------
COPY .docker/s6-overlay/services.d /etc/services.d
COPY .docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY .docker/nginx/php.conf /etc/nginx/conf.d/default.conf

COPY .docker/php/dev/php.ini /usr/local/etc/php/php.ini
COPY .docker/php/dev/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

ADD .docker/nginx/healthcheck.ini /usr/local/etc/php/healthcheck.ini

RUN rm -rf /var/cache/apk/* && \
        rm -rf /tmp/*

# ------------------------ Create user based on provided user id and chown all files ------------------------
RUN adduser --disabled-password --gecos "" --uid $HOST_UID dkuser \
    && chown -R dkuser:dkuser /var/www/html

# Uses "Spaceship" theme with some customization. Uses some bundled plugins and installs some more from github
USER dkuser
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
    -t robbyrussell \
    -a 'alias art="php artisan"' \
    -p git \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions

USER root

EXPOSE 80

ENTRYPOINT ["/init"]
CMD []
