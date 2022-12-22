#!/bin/bash
set -ex -o pipefail
# https://docs.docker.com/config/containers/multi-service_container/
touch /var/www/discourse/log/production.log

bundle exec rake manifest:download

# https://stackoverflow.com/questions/3004811/how-do-you-run-multiple-programs-in-parallel-from-a-bash-script
(trap 'kill 0' SIGINT; tail -f /var/www/discourse/log/production.log & $@)
exit $?
