# Importing common provides default settings, see:
# https://github.com/taigaio/taiga-back/blob/master/settings/common.py
from .common import *
import dj_database_url, re

DEBUG = os.getenv('TAIGA_DEBUG', 'false').lower() == 'true'
TEMPLATE_DEBUG = os.getenv('TAIGA_TEMPLATE_DEBUG', 'false').lower() == 'true'
PUBLIC_REGISTER_ENABLED = os.getenv('TAIGA_PUBLIC_REGISTER_ENABLED', 'false').lower() == 'true'

if os.getenv('DATABASE_URL'):
    DATABASES = {'default': dj_database_url.config() }
    DATABASES['default']['ENGINE'] = 'django.db.backends.postgresql'
else:
    DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('TAIGA_DB_NAME'),
        'HOST': os.getenv('POSTGRES_PORT_5432_TCP_ADDR') or os.getenv('TAIGA_DB_HOST'),
        'USER': os.getenv('TAIGA_DB_USER'),
        'PASSWORD': os.getenv('POSTGRES_ENV_POSTGRES_PASSWORD') or os.getenv('TAIGA_DB_PASSWORD')
        }
    }

if os.getenv('MEMCACHED_URL'):
    CACHES = {
        'default': {
            'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
            'LOCATION': os.getenv('MEMCACHED_URL').split('//')[1],
        }
    }

TAIGA_HOSTNAME = os.getenv('TAIGA_HOSTNAME')

SITES['api']['domain'] = TAIGA_HOSTNAME
SITES['front']['domain'] = TAIGA_HOSTNAME

MEDIA_URL  = 'http://' + TAIGA_HOSTNAME + '/media/'
STATIC_URL = 'http://' + TAIGA_HOSTNAME + '/static/'

if os.getenv('TAIGA_SSL').lower() == 'true':
    SITES['api']['scheme'] = 'https'
    SITES['front']['scheme'] = 'https'

    MEDIA_URL  = 'https://' + TAIGA_HOSTNAME + '/media/'
    STATIC_URL = 'https://' + TAIGA_HOSTNAME + '/static/'

SECRET_KEY = os.getenv('TAIGA_SECRET_KEY')

if os.getenv('EMAIL_ENABLED','false').lower() == "true":
    EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
    DJMAIL_REAL_BACKEND = EMAIL_BACKEND
    EMAIL_HOST = os.getenv('EMAIL_HOST')
    EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER')
    EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD')
    EMAIL_PORT = int(os.getenv('EMAIL_PORT'))
    EMAIL_USE_TLS = os.getenv('EMAIL_USE_TLS','false').lower() == 'true'

if os.getenv('RABBIT_PORT') is not None and os.getenv('REDIS_PORT') is not None:
    from .celery import *

    BROKER_URL = 'amqp://guest:guest@rabbit:5672'
    CELERY_RESULT_BACKEND = 'redis://redis:6379/0'
    CELERY_ENABLED = True

    EVENTS_PUSH_BACKEND = "taiga.events.backends.rabbitmq.EventsPushBackend"
    EVENTS_PUSH_BACKEND_OPTIONS = {"url": "amqp://guest:guest@rabbit:5672"}
