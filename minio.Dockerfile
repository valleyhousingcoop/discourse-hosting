FROM minio/minio:latest


# https://stackoverflow.com/a/72905958/907060
COPY --from=docker.io/minio/mc:latest /usr/bin/mc /usr/bin/mc
COPY minio.start.sh /usr/bin/minio.start.sh

EXPOSE 80 9001
ENTRYPOINT ["/usr/bin/minio.start.sh"]

