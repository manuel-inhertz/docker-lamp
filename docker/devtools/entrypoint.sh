#!/usr/bin/env bash

set -e

# Configure Xdebug
if [ "$XDEBUG_CONFIG" ]; then
    XDEBUG_INI=/usr/local/etc/php/conf.d/zz-xdebug.ini
    XDEBUG_REMOTE_HOST_CONFIG=remote_host

    echo "" > $XDEBUG_INI
    for config in $XDEBUG_CONFIG; do
        echo "xdebug.$config" >> $XDEBUG_INI
    done

    if [[ ! "$XDEBUG_CONFIG" =~ "$XDEBUG_REMOTE_HOST_CONFIG"  ]]; then
        REMOTE_HOST=$(netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}')
        echo "xdebug.remote_host=${REMOTE_HOST}" >> $XDEBUG_INI
    fi
fi

# Execute the supplied command
exec "$@"