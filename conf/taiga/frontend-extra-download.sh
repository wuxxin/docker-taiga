#!/bin/bash
mkdir -p /app/taiga-front-dist/dist/plugins
cd /app/taiga-front-dist/dist/plugins
svn export "https://github.com/taigaio/taiga-contrib-gogs/tags/$(pip show taiga-contrib-gogs | awk '/^Version: /{print $2}')/front/dist" "gogs"
# wget "https://raw.githubusercontent.com/taigaio/taiga-contrib-gogs/$(pip show taiga-contrib-gogs | awk '/^Version: /{print $2}')/front/dist/gogs.js"
