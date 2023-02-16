FROM postgres:15

RUN echo 'CREATE DATABASE glitchtip;' >  /docker-entrypoint-initdb.d/1-create-db.sql
