# Discourse Hosting


First populate the .env file with the following:

```shell
# Developer email to create an account for
EMAIL=me@gmail.com
# Hostname to use for the site
HOSTNAME=forum.mydomain.com
# API Key for Sendgrid
# https://app.sendgrid.com/settings/api_keys
SEND_GRID_API_KEY=SEND_GRID_API_KEY
# Hostname for sendgrid email
EMAIL_HOSTNAME=mydomain.com
```

Then make modify your `/etc/hosts` file to alias your domain to localhost:

```shell
127.0.0.1 forum.mydomain.com
```


```shell
mkdir web-log sidekiq-log assets
docker-compose run -e LOAD_PLUGINS=0 --rm web bundle exec rake plugin:pull_compatible_all
docker-compose run --rm web bundle exec rake db:migrate
docker-compose run --rm web bundle exec rake themes:update assets:precompile
docker-compose run --rm web bundle exec rails r  "SiteSetting.notification_email='forum@mydomain.com'"
docker-compose up
```


Now open your browser to http://forum.mydomain.com:3000 and you should see the Discourse setup page.

You can also visit `/logs` to see the logs and `/sidekiq` to see the sidekiq dashboard.

You can also visist http://localhost:8001 to see the redis GUI, use the password `password`.
