#!/bin/bash
set -ex -o pipefail
bundle exec rake manifest:download

# https://docs.docker.com/config/containers/multi-service_container/
# /var/www/discourse/log/production.log
touch log/unicorn.stderr.log log/unicorn.stdout.log
tail -f  log/* &
# bin/unicorn
bundle exec unicorn -c config/unicorn.conf.rb
# bundle exec rails server -b 0.0.0.0 -p 80 &
# bundle exec sidekiq -q critical,8 -q default,4 -q low,2 -q ultra_low,1 --verbose &


# https://stackoverflow.com/questions/3004811/how-do-you-run-multiple-programs-in-parallel-from-a-bash-script
#(trap 'kill 0' SIGINT;  $@)

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
