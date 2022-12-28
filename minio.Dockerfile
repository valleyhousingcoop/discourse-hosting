FROM minio/minio:latest


# https://stackoverflow.com/a/72905958/907060
COPY --from=docker.io/minio/mc:latest /usr/bin/mc /usr/bin/mc
COPY minio.entrypoint.sh /usr/bin/minio.entrypoint.sh

EXPOSE 80 9001
CMD ["/usr/bin/minio.entrypoint.sh"]

