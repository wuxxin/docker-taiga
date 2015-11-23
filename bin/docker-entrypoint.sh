#!/bin/bash
set -e

if test "$1" = "web"; then
  shift
  exec /usr/bin/supervisord -c /app/supervisord.conf "$@"
else
  exec "$@"
fi
