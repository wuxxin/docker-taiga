import os, sys, psycopg2, dj_database_url

DB_NAME = os.getenv('TAIGA_DB_NAME')
DB_HOST = os.getenv('POSTGRES_PORT_5432_TCP_ADDR') or os.getenv('TAIGA_DB_HOST')
DB_USER = os.getenv('TAIGA_DB_USER')
DB_PASS = os.getenv('POSTGRES_ENV_POSTGRES_PASSWORD') or os.getenv('TAIGA_DB_PASSWORD')

if os.getenv('DATABASE_URL'):
    d= dj_database_url()
    DB_NAME= d['NAME']
    DB_HOST= d['HOST']
    DB_USER= d['USER']
    DB_PASS= d['PASSWORD']

conn = psycopg2.connect("dbname='" + DB_NAME + "' user='" + DB_USER + "' host='" + DB_HOST + "' password='" + DB_PASS + "'")
cur = conn.cursor()

cur.execute("select * from information_schema.tables where table_name=%s", ('django_migrations',))
exists = bool(cur.rowcount)

if exists is False:
    print('Database does not appear to be setup.')
    sys.exit(2)
