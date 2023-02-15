#!/bin/bash
set -ex -o pipefail

# Remove PID if it exists on a hard restart from tilt
rm -f /var/www/discourse/tmp/pids/unicorn.pid

exec bundle exec unicorn -c config/unicorn.conf.rb
