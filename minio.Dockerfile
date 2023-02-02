FROM minio/minio:latest

ENV MINIO_ROOT_USER minioadmin
ENV MINIO_ROOT_PASSWORD minioadmin

VOLUME [ "/data" ]

# Create containers with a volume mounted at /data
# https://stackoverflow.com/a/72905958/907060
COPY --from=docker.io/minio/mc:latest /usr/bin/mc /usr/bin/mc
COPY minio.start.sh /usr/bin/minio.start.sh
RUN /usr/bin/minio.start.sh

EXPOSE 80 9001
CMD ["server", "--address", ":80", "--console-address", ":9001", "/data"]

