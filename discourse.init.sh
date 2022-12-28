#!/bin/bash
set -ex

bundle exec rake --trace \
    db:migrate \
    themes:update \
    assets:precompile \
    s3:upload_assets \
    manifest:upload

bundle exec rails r SiteSetting.notification_email=\'${EMAIL_ADDRESS}\'
bundle exec rails r SiteSetting.content_security_policy=false
