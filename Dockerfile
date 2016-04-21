FROM python:3
MAINTAINER Wuxxin <wuxxin@gmail.com>

# Install nginx from custom repository
COPY conf/nginx_signing.key /tmp
RUN apt-key add /tmp/nginx_signing.key
RUN echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list

# install packages
RUN set -x; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        ca-certificates \
        wget \
        supervisor \
        gettext \
        nginx \
        sudo \
        subversion \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

# prepare locale
RUN locale-gen en_US.UTF-8 en_us && dpkg-reconfigure locales && dpkg-reconfigure locales && locale-gen C.UTF-8 && /usr/sbin/update-locale LANG=C.UTF-8
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

# setup fallback env
ENV TAIGA_SSL False
ENV TAIGA_HOSTNAME localhost
ENV TAIGA_SECRET_KEY "!!!REPLACE-ME-j1598u1J^U*(y251u98u51u5981urf98u2o5uvoiiuzhlit3)!!!"
ENV TAIGA_DB_NAME postgres
ENV TAIGA_DB_USER postgres
# gunicorn uses WEB_CONCURRENCY
ENV WEB_CONCURRENCY=4

# Add user to run the application
RUN adduser app --disabled-password --home /app

# copy sources to destination
COPY taiga-back /app/taiga-back
COPY taiga-front-dist/ /app/taiga-front-dist

# install python packages
WORKDIR /app/taiga-back
RUN pip install --no-cache-dir -r requirements.txt
COPY conf/taiga/requirements-extra.txt /app/requirements-extra.txt
RUN pip install --no-cache-dir -r /app/requirements-extra.txt

# download extra frontend files
COPY conf/taiga/frontend-extra-download.sh /app/frontend-extra-download.sh
RUN chmod +x /app/frontend-extra-download.sh
RUN /app/frontend-extra-download.sh

# copy local config files
COPY conf/taiga/local.py /app/local.py
COPY conf/taiga/conf.json /app/conf.json
COPY conf/taiga/docker-settings.py /app/taiga-back/settings/docker.py

# Setup symbolic links for conf and files on data volume
RUN for a in conf media; do if test ! -d /data/$a; then mkdir -p /data/$a ; fi; done
RUN if test ! -L /app/taiga-back/media; then ln -s /data/media /app/taiga-back/media ; fi
RUN ln -s /app/local.py /app/taiga-back/settings/local.py
RUN ln -s /app/conf.json /app/taiga-front-dist/dist/conf.json

# all files belong to app-user
RUN chown -R app:app /app/

USER app

# collect/generate static files
RUN python manage.py compilemessages
RUN python manage.py collectstatic --noinput

USER root

# nginx config
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx/taiga.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx/ssl.conf /etc/nginx/ssl.conf
COPY conf/nginx/taiga-events.conf /etc/nginx/taiga-events.conf
RUN  service nginx stop
# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# container startup files
COPY conf/supervisord.conf /app/supervisord.conf
COPY bin/gunicorn_start.sh /app/gunicorn_start.sh
COPY bin/taiga_prepare.sh /app/taiga_prepare.sh
COPY bin/docker-entrypoint.sh /docker-entrypoint.sh
COPY bin/checkdb.py /app/checkdb.py
RUN for i in gunicorn_start.sh taiga_prepare.sh checkdb.py; do chmod +x /app/$i; done
RUN chmod +x /docker-entrypoint.sh

VOLUME ["/data"]
EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["web"]
