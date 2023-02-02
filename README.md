# Discourse Hosting

This repository contains the code for running Discourse locally and on Render.

This does not use the Docker images provided by discourse, instead opting to build a new one, so that each
service can be broken up into its own docker container and we can build it with more traditional Docker tools
instead of the wrapper provided by Discourse.


## Hosted with Render

This repository can be deployed as a blueprint on Render.

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/saulshanabrook/discourse-hosting)


After deploying, you probably want to run the initial migrations and trigger the static build of assets:



## Local Development with Docker Compose

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
127.0.0.1 assets.forum.mydomain.com
```

Then run the following commands:


```shell
docker compose run --rm web init.sh
docker compose up
```


Now open your browser to http://forum.mydomain.com and you should see the Discourse setup page.

You can also visit `/logs` to see the logs and `/sidekiq` to see the sidekiq dashboard.

You can also visit http://localhost:8001 to see the redis GUI, use the password `password`.

The Minio GUI is available at http://localhost:9001. The default username and pw is `minioadmin`.

To import emails:

```shell
mkdir -p data/import/emails
cp some-mailbox.mbox data/import/emails
# Copy the default settings to the `data/import/` setting.
docker-compose run -v $PWD/data/import:/shared/import/data --rm web bundle exec ruby script/import_scripts/mbox.rb /shared/import/data/settings.yml
```

To remove all the data, run:

```shell
docker compose down -v
rm -rf data/*/**
```


## Debugging

### Network Traffic

If you want to see the network traffic from one of the containers, for debugging purposes, you can use tcpdump and wireshark:

```bash
dc run --rm --name tmp web bash -i
docker run --net=container:tmp maintained/tcpdump -i any -w - | wireshark -k -i -
# create network traffic in initial container
#  bundle exec rake s3:upload_assets
```

## Rails Console

If we want to check how something works on the ruby side, we can do that with rails console. Here is an example of how to do that
to see how the `preload_script` helper works:

```shell
docker compose run --rm web bundle exec rails c
```


```ruby
require 'mock_redis'
require 'rspec-html-matchers'
require "ostruct"
require_relative './spec/rails_helper'
helper.request = OpenStruct.new(:env => {'HTTP_ACCEPT_ENCODING' => 'gzip, deflate'})
helper.preload_script("vendor")
ActionController::Base.helpers.asset_path("vendor.js")
```

## About

We run the sidekiq alongside the web process in the same container. This is so that they can share a mounted volume [in Render](https://render.com/docs/disks) which cannot be shared accross containers. Alternatively,
we could set everything up to use a third party service like S3 for uploads and assets.


TODO: Add two rake tasks, one to upload manifest, the other to download manifest
* https://github.com/rails/sprockets-rails/issues/107#issuecomment-34535325
* Upload it just as one filename.
* https://github.com/rails/sprockets/blob/1276b431e2e4c1099dae1b3ff76adc868c863ddd/lib/sprockets/manifest_utils.rb#L10

* Actually just create an initializer that does this. If there is no manifest file, download it. If there is one,
  and its ID is not 00000000000000000000000000000000, then upload it.

This way it will only be downloaded if it hasn't been already.

Like this file `/var/www/discourse/public/assets/.sprockets-manifest-c1adc4e851d160658421ecf1ba8e8d55.json`

