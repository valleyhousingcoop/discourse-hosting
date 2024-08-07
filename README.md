# Discourse Hosting

This repository provides a way to host Discourse on a server.

**UPDATE**: I found it too hard to maintain this setup especially accross discourse updates. I have since switched to the [standard discourse hosting setup](https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md), locally on a machine in my basement. That is much more stable and I have had no issues upgrading things. I would highly reccomend someone trying to approach to have a second thought about it, unless you have a very high amount of time investment available. I spent months on getting this working. I think long term for this kind of setup to work, it would have to be upstreamed into discourse and offically supported so that it stays working.

## Goals

When I set out to setup a forum for a local group I am a part of, I quickly settled on Discourse, since it was open
source, had a nice UX, was actively updated, and had a large community. However, I couldn't find an existing
hosting solution that met these goals:

* Support existing tools (Docker Compose, etc)
* Keep each image as close to single responsibility as possible
* Free (or as close to as possible) hosting
* Easy to setup and upgrade, i.e. little implicit state
* Ability to support any Discourse plugin
* Email sending and recieving


The online supported hosting would easily be $100+ per month for a forum with some plugins, which was a no-go for our organization to start.

Alternatively, [the supported way of hosting Discourse](https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md) uses a custom installer script. There is [a long standing issue about having a more standard way of deploying Discourse](https://meta.discourse.org/t/can-discourse-ship-frequent-docker-images-that-do-not-need-to-be-bootstrapped/33205).


## Solution

So I decided to:

1. Build my own Docker image for Discourse so I had more control over what was shipped in it and the bootstrapping process
2. Host it on a laptop sitting at my friends host. At first I had it running on [Render](https://render.com/) as well as [Digital Ocean App Platform](https://www.digitalocean.com/products/app-platform), but the pricing for setting up a couple services as well as the DB and redis quickly added up. I also found it much harder to debug when things went wrong (oh and things did go wrong...).
3. Use Docker Compose to manage the deployment, along with [Tilt](https://tilt.dev/) to help with the development process. I had considered using Swarm, but it doesn't seem too maintained, and also I only needed to host it on one machine. I had also considered Kubernetes, but it seemed like overkill (both in terms of complixity and resource usage) for my use case at the time.



## How to get started

### Pre-requisites
Before you get started with your forum, you will need a few things:

1. A domain to host this at! This can be a top level domain or a subdomain. You can get this for free most likely if you would like.
2. A [SendGrid](https://sendgrid.com/) account! Sending and recieveing emails is one of the things that I coudn't do locally. Most residentials ISPs block port 25, and I have heard there is a lot of voodoo magic for getting all the right settings and earning trust around spam blockers. All of our email fits under Sengrid's free tier, so that's nice `:)`
3. A computer with at least 4 GB of ram which can run Docker. I am running this on a 2017 13 inch Macbook air. I also assume that you will be developing this on a different computer, which can SSH into that computer.
4. An internet provider which will allow you to open up ports 22 (SSH), 80 (HTTP), and 443 (HTTPS), as well as port 8080 for email forwarding.
5. A free Cloudflare account, which we will use for DNS. I have another domain provider, but switched my nameservers to use them. You could also use another DNS provider, you just might have to change a few things.

### Remote Server

1. Use `configs/daemon.json` for your docker daemon config. This changes logging to be more performant.
2. Use `configs/sshd_config` as a secure SSH config
3. Setup docker to connect with the server over ssh


### First Launch

Start up services:

```shell
docker compose up -d db redis minio
docker compose run --rm --no-deps glitchtip-migrate
docker compose run --rm --no-deps migrate
docker compose run --rm --no-deps upload_assets
docker compose up -d --no-deps glitchtip-web glitchtip-worker web mail-reciever ddclient email-relay
docker compose up -d --no-deps nginx
```

Open glitchtip, sign up for an account, copy DSN to `.env`.

Rebuild web with DSN and re-copy assets:

```shell
docker compose run --rm --no-deps --build upload_assets
docker compose up -d --no-deps web
```


### Restroring from a local backup file

```shell
docker compose run --rm --no-deps web ./script/discourse enable_restore
# Must preserve file name
docker cp /path/to/<name>.sql.gz discourse-hosting-web-1:/var/www/discourse/public/backups/default/
docker exec -it discourse-hosting-web-1 env DISCOURSE_BACKUP_LOCATION=local ./script/discourse restore ./<name>.sql.gz
docker compose run --rm --no-deps web ./script/discourse disable_restore
docker compose run --rm --no-deps web bundle exec rake posts:rebake
```

# Remove Computer


local Computer

Remote computer

Sendgrid
- domain DNS
- Callback for emails


Software setup

locally: set env variables
tilt up

use docker context






## Things I learned about Discourse


## Local Development with Docker Compose

First populate the .env file with the following:

```shell
SEND_GRID_API_KEY=...
HOSTNAME=forum.mydomain.com
EMAIL=my-email@gmail.com
# Run openssl rand -hex 32 to generate a new secret key
SECRET_KEY=...
# Generated by the glitchtip server after creating an account
DSN=http://...@glitchtip.${HOSTNAME}/1
```

Then make modify your `/etc/hosts` file to alias your domain to localhost:

```shell
127.0.0.1 forum.mydomain.com
127.0.0.1 assets.forum.mydomain.com
127.0.0.1 glitchtip.forum.mydomain.com
```

Then run the following commands:


```shell
docker compose run --rm glitchtip-migrate
docker compose run --rm migrate
docker compose run --rm upload_assets
docker compose run --rm install_themes
docker compose up web glitchtip-worker
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

### Ruby Debugger

We also include the `debug` gem, which you can invoke to start a bundle command with debugging:

```bash
docker compose run --rm upload_assets rdbg -c --  bundle exec rake s3:upload_assets
```
