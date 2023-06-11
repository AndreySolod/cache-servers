#!/bin/bash

if [ ! -f /root/.devpi/server/.nodeinfo ]; then
echo "file devpi is not exist"
    devpi-init
    devpi-gen-config --port 3143 --host 0.0.0.0
    mv ./gen-config/supervisor-devpi.conf /etc/supervisor/conf.d/devpi.conf
fi

exec /usr/bin/supervisord -nc /etc/supervisor/supervisord.conf
