#!/usr/bin/env sh


set -ex

# https://veithen.io/2014/11/16/sigterm-propagation.html
trap 'kill -TERM $PID' TERM INT

docker-entrypoint.sh server --address :80 --console-address :9001 /data &
PID=$!
until mc alias set local http://localhost minioadmin ${MINIO_ROOT_PASSWORD:-minioadmin}; do
    sleep 0.5;
done;

# Set bucket to allow downloads
# https://github.com/rishabhnambiar/discourse-docs/blob/master/minio.md#step-4-setting-an-upload-bucket-policy-skip-if-not-using-minio-for-image-uploads

mc mb --quiet local/assets/ || true
mc anonymous set download local/assets;
wait $PID
