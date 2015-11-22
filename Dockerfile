FROM python:3.4
MAINTAINER Benjamin Hutchins <ben@hutchins.co>

# Install nginx
ENV NGINX_VERSION 1.9.6-1~jessie
COPY nginx_signing.key /tmp
RUN apt-key add /tmp/nginx_signing.key
RUN echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list
RUN set -x; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        ca-certificates \
        wget \
        nginx=${NGINX_VERSION} \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales
COPY conf/locale.gen /etc/locale.gen

# Add user to run the application
RUN adduser taiga --disabled-password

# copy sources to destination
COPY taiga-back /home/taiga/taiga-back
COPY taiga-front-dist/ /home/taiga/taiga-front-dist
COPY docker-settings.py /home/taiga/taiga-back/settings/docker.py

# Setup symbolic links for configuration files on data volume
RUN for a in conf media; do if test ! -d /data/$a; then mkdir -p /data/$a ; fi; done
RUN if test ! -L /home/taiga/media; then ln -s /data/media /home/taiga/media ; fi
RUN mkdir -p /home/taiga/static
COPY conf/taiga/requirements-extra.txt /data/conf/requirements-extra.txt
COPY conf/taiga/frontend-extra-download.sh /data/conf/frontend-extra-download.sh
COPY conf/taiga/local.py /data/conf/local.py
COPY conf/taiga/conf.json /data/conf/conf.json
RUN ln -s /data/conf/local.py /home/taiga/taiga-back/settings/local.py
RUN ln -s /data/conf/conf.json /home/taiga/taiga-front-dist/dist/js/conf.json

# nginx config
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx/taiga.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx/ssl.conf /etc/nginx/ssl.conf
COPY conf/nginx/taiga-events.conf /etc/nginx/taiga-events.conf

# install python packages
WORKDIR /home/taiga/taiga-back
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r /data/conf/requirements-extra.txt

# setup locale
RUN echo "LANG=en_US.UTF-8" > /etc/default/locale
RUN echo "LC_TYPE=en_US.UTF-8" > /etc/default/locale
RUN echo "LC_MESSAGES=POSIX" >> /etc/default/locale
RUN echo "LANGUAGE=en" >> /etc/default/locale
ENV LANG en_US.UTF-8
ENV LC_TYPE en_US.UTF-8

# download extra frontend files
WORKDIR /home/taiga/taiga-front-dist/dist/js
RUN chmod +x /data/conf/frontend-extra-download.sh
RUN /data/conf/frontend-extra-download.sh

# collect/generate static files
WORKDIR /home/taiga/taiga-back
RUN python manage.py collectstatic --noinput

# all files belong to app-user
RUN chown -R taiga:taiga /home/taiga/

# regenerate locales
RUN locale -a

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

COPY checkdb.py /checkdb.py
COPY docker-entrypoint.sh /docker-entrypoint.sh

VOLUME ["/data"]
EXPOSE 80 443
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
