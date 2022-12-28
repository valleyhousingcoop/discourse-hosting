#!/usr/bin/env sh


set -ex


server --address :80 --console-address :9001 /data &
until mc alias set local http://localhost minioadmin ${MINIO_ROOT_PASSWORD:-minioadmin}; do
    sleep 0.5;
done;

# Set bucket to allow downloads
# https://github.com/rishabhnambiar/discourse-docs/blob/master/minio.md#step-4-setting-an-upload-bucket-policy-skip-if-not-using-minio-for-image-uploads

mc mb --quiet local/assets/;
mc anonymous set download local/assets;
wait
