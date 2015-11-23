FROM python:3.4
MAINTAINER Benjamin Hutchins <ben@hutchins.co>

# Install nginx from custom repository
ENV NGINX_VERSION 1.9.6-1~jessie
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
        nginx=${NGINX_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# setup locale
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales
COPY conf/locale.gen /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/default/locale
RUN echo "LC_TYPE=en_US.UTF-8" > /etc/default/locale
RUN echo "LC_MESSAGES=POSIX" >> /etc/default/locale
RUN echo "LANGUAGE=en" >> /etc/default/locale
ENV LANG en_US.UTF-8
ENV LC_TYPE en_US.UTF-8

# Add user to run the application
RUN adduser app --disabled-password --home /app

# copy sources to destination
COPY taiga-back /app/taiga-back
COPY taiga-front-dist/ /app/taiga-front-dist

# Setup symbolic links for configuration files on data volume
RUN for a in conf media; do if test ! -d /data/$a; then mkdir -p /data/$a ; fi; done
RUN if test ! -L /app/media; then ln -s /data/media /app/media ; fi
RUN mkdir -p /app/static
COPY conf/taiga/requirements-extra.txt /data/conf/requirements-extra.txt
COPY conf/taiga/frontend-extra-download.sh /data/conf/frontend-extra-download.sh
COPY conf/taiga/local.py /data/conf/local.py
COPY conf/taiga/conf.json /data/conf/conf.json
COPY conf/taiga/docker-settings.py /app/taiga-back/settings/docker.py
RUN ln -s /data/conf/local.py /app/taiga-back/settings/local.py
RUN ln -s /data/conf/conf.json /app/taiga-front-dist/dist/js/conf.json

# nginx config
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx/taiga.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx/ssl.conf /etc/nginx/ssl.conf
COPY conf/nginx/taiga-events.conf /etc/nginx/taiga-events.conf
RUN  service nginx stop

# install python packages
WORKDIR /app/taiga-back
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r /data/conf/requirements-extra.txt

# download extra frontend files
RUN chmod +x /data/conf/frontend-extra-download.sh
RUN /data/conf/frontend-extra-download.sh

# collect/generate static files
RUN python manage.py collectstatic --noinput

# all files belong to app-user
RUN chown -R app:app /app/

# regenerate locales
RUN locale -a

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

COPY bin/checkdb.py /app/checkdb.py
COPY bin/gunicorn_start.sh /app/gunicorn_start.sh
COPY bin/taiga_prepare.sh /app/taiga_prepare.sh

ENV WEB_CONCURRENCY=2

VOLUME ["/data"]
EXPOSE 80 443
ENTRYPOINT ["supervisord -c /app/supervisord.conf"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
