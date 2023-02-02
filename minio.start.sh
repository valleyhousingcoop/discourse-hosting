#!/usr/bin/env sh


set -ex

docker-entrypoint.sh server --address :80 /data &
PID=$!
until mc alias set local http://localhost ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}; do
    sleep 0.1;
done;

# Set bucket to allow downloads
# https://github.com/rishabhnambiar/discourse-docs/blob/master/minio.md#step-4-setting-an-upload-bucket-policy-skip-if-not-using-minio-for-image-uploads

mc mb --quiet local/assets/ || true
mc mb --quiet local/backup/ || true
mc anonymous set download local/assets;
kill $PID
