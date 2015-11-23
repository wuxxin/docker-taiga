#!/bin/bash
set -e

CONF_DIR=/app/taiga-back
WSGI_FILE=${CONF_DIR}/wsgi.py

if [ ! -e "$WSGI_FILE" ]; then
    echo "Expected to find $WSGI_FILE"
    exit 1
fi

pushd ${CONF_DIR} >> /dev/null

. /app/taiga_prepare.sh
pythonpath = '/home/app_user/code'
exec /usr/bin/gunicorn -b 127.0.0.1:8000 --pythonpath ${CONF_DIR} taiga.qwsgi:application

popd >> /dev/null
