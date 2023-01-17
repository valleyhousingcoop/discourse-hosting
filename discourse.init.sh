#!/bin/bash
set -ex -o pipefail

bundle exec rake --trace \
    db:migrate \
    s3:upload_assets

bundle exec rails r SiteSetting.notification_email=\'${EMAIL_ADDRESS}\'
