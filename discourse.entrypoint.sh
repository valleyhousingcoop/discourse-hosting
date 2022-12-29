#!/bin/bash
set -ex

[[ -z "${RENDER}" ]] && protocol='http' || protocol="https"

export DISCOURSE_S3_ENDPOINT=$protocol://$DISCOURSE_HOSTNAME  DISCOURSE_S3_CDN_URL=//assets.$DISCOURSE_HOSTNAME

exec "$@"
