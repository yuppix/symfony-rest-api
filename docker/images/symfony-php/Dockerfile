FROM php:8.3-fpm AS base

RUN sed -i \
    -e "s/^# \(export LS_OPTIONS='--color=auto'\)/\1/g" \
    -e "s/^# \(alias ls='ls \$LS_OPTIONS'\)/\1/g" \
    -e "s/^# \(alias rm='rm -i'\)/\1/g" \
    /root/.bashrc

RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        acl \
        bc \
        gettext-base \
        git \
        unzip \
    && apt-get install -y libfcgi0ldbl \
    && rm -rf /var/lib/apt/lists/*

RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        libbz2-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libxslt-dev \
        libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        bz2 \
        exif \
        gd \
        intl \
        pcntl \
        pdo_mysql \
        soap \
        sockets \
        xsl \
        zip \
    && pecl install \
        apcu \
        igbinary \
    && pecl bundle redis \
    && cd redis \
    && phpize \
    && ./configure --enable-redis-igbinary --enable-redis-lzf \
    && make \
    && make install \
    && docker-php-ext-enable \
        apcu \
        igbinary \
        opcache \
        redis \
    && ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini \
    && rm -rf /var/lib/apt/lists/* /var/www/html/*

COPY ./docker/images/symfony-php/symfony.ini /usr/local/etc/php/conf.d/
COPY ./docker/images/symfony-php/zz-www.conf /usr/local/etc/php-fpm.d/

COPY ./docker/images/symfony-php/docker-entrypoint.sh /usr/local/bin/

RUN mkdir -p var/cache var/log \
    && chmod +x \
        /usr/local/bin/docker-entrypoint.sh

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer        

VOLUME /var/www/html/var

HEALTHCHECK --interval=30s --timeout=15s --start-period=30s --retries=10 \
    CMD SCRIPT_NAME=/status SCRIPT_FILENAME=/status QUERY_STRING=full REQUEST_METHOD=GET \
        /usr/bin/cgi-fcgi -bind -connect 127.0.0.1:9000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]




FROM base as dev

RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        jq \
    && rm -rf /var/lib/apt/lists/*




FROM base as api

ARG APP_ENV=prod
ENV APP_ENV=${APP_ENV}

ENV SYMFONY_INI=/usr/local/etc/php/conf.d/symfony.ini

RUN sed -i \
        -e "s/^# \(apc.stat =\)/\1/g" \
        -e "s/^# \(opcache.preload =\)/\1/g" \
        -e "s/^# \(opcache.validate_timestamps =\)/\1/g" \
        ${SYMFONY_INI}
