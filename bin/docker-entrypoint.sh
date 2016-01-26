#!/bin/bash
set -e

if test "$1" = "web"; then
  shift
  . /app/taiga_prepare.sh

  exec /usr/bin/supervisord -c /app/supervisord.conf "$@"
else
  exec "$@"
fi
