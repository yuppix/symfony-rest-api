#!/bin/bash -e

set_up_pm() {
    local cpu_cores=${FPM_CPU_CORES:-1}
    local total_ram=${FPM_TOTAL_RAM:-1024}
    local process_size=${FPM_PROCESS_SIZE:-32}

    if [[ $(echo "${cpu_cores}<0.5" | bc) -eq 1 ]]; then
        echo 'Misconfiguration: $FPM_CPU_CORES should be greater than or equal to 0.5'
        exit 1
    fi

    export FPM_MAX_CHILDREN=$(($total_ram / $process_size))
    export FPM_MIN_SERVERS=$(echo "${cpu_cores}*2/1" | bc)
    export FPM_MAX_SERVERS=$(echo "${cpu_cores}*4/1" | bc)

    if [[ $FPM_MAX_SERVERS -gt $FPM_MAX_CHILDREN ]]; then
        echo 'Misconfiguration: $FPM_TOTAL_RAM / $FPM_PROCESS_SIZE should be greater than or equal to $FPM_CPU_CORES * 4'
        exit 1
    fi

    local www_conf=/usr/local/etc/php-fpm.d/zz-www.conf
    envsubst < $www_conf > /tmp/zz-www.conf && mv /tmp/zz-www.conf $www_conf
}

set_up_pm

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

if [[ "$1" = 'php-fpm' ]] || [[ "$1" =~ ^bin/ ]]; then
    PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-production"
    if [[ ! "$APP_ENV" =~ 'prod|stage' ]]; then
        PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-development"
    fi
    ln -sf "$PHP_INI_RECOMMENDED" "$PHP_INI_DIR/php.ini"

    #mkdir -p var/cache var/log
    #setfacl -R -m u:www-data:rwX -m u:"$(whoami)":rwX var
    #setfacl -dR -m u:www-data:rwX -m u:"$(whoami)":rwX var

    # Permissions hack because setfacl does not work on Mac and Windows
    chown -R www-data var
fi

exec docker-php-entrypoint "$@"
