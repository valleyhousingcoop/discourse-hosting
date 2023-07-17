FROM postgres:15

RUN apt-get update \
      && apt-get install -y --no-install-recommends \
           postgresql-15-pgvector \
      && rm -rf /var/lib/apt/lists/*

RUN echo 'CREATE DATABASE glitchtip;' >  /docker-entrypoint-initdb.d/1-create-db.sql
