FROM postgres:latest

RUN echo 'CREATE DATABASE glitchtip;' >  /docker-entrypoint-initdb.d/1-create-db.sql
