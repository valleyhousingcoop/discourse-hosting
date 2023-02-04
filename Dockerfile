# syntax=docker/dockerfile:1
# https://github.com/discourse/discourse/blob/main/docs/DEVELOPER-ADVANCED.md
# https://hub.docker.com/_/ruby

# Use Ruby < 3.1 to avoid missing net/pop error
# https://github.com/discourse/discourse/pull/15692/files
FROM ruby:3.1
LABEL org.opencontainers.image.source="https://github.com/saulshanabrook/discourse-hosting"

ENV LANG C.UTF-8

# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md#example-cache-apt-packages
# RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
# RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    # --mount=type=cache,target=/var/lib/apt,sharing=locked \
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y jpegoptim optipng jhead nodejs pngquant brotli gnupg locales locales-all pngcrush imagemagick libmagickwand-dev cmake pkg-config libgit2-dev libsqlite3-dev postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/oxipng-install
RUN wget https://github.com/shssoichiro/oxipng/releases/download/v5.0.1/oxipng-5.0.1-x86_64-unknown-linux-musl.tar.gz \
 && tar -xzf oxipng-5.0.1-x86_64-unknown-linux-musl.tar.gz \
 && cp oxipng-5.0.1-x86_64-unknown-linux-musl/oxipng /usr/local/bin \
 && rm -rf /tmp/oxipng-install

RUN npm install -g svgo terser uglify-js

ENV BUNDLER_VERSION='2.3.22'
RUN gem install bundler --no-document -v '2.3.22'


WORKDIR /home/discourse/discourse
RUN mkdir -p tmp/sockets log tmp/pids

WORKDIR /var/www/discourse

# Only fetch one commit to reduce size
# https://stackoverflow.com/a/43136160/907060
RUN git config --global http.sslVerify false && \
    git clone https://github.com/discourse/discourse.git --depth 1 --branch tests-passed /var/www/discourse && \
    cd /var/www/discourse && \
    git fetch --depth 1 origin e6a41150e24f3163d61d32f86834acae8098dead && \
    git checkout FETCH_HEAD


RUN corepack enable
RUN yarn install --production --frozen-lockfile && yarn cache clean
ENV RAILS_ENV production
RUN bundle config --local without test development
RUN bundle add mock_redis sqlite3 debug sentry-ruby sentry-rails sentry-sidekiq --skip-install && bundler install --no-cache
COPY discourse.install-plugins.sh plugins.txt ./
RUN ./discourse.install-plugins.sh
RUN bundle exec rake plugin:install_all_gems
RUN env LOAD_PLUGINS=0 bundle exec rake plugin:pull_compatible_all



ARG DISCOURSE_HOSTNAME
ARG DISCOURSE_S3_CDN_URL
ENV DISCOURSE_HOSTNAME=$DISCOURSE_HOSTNAME
ENV DISCOURSE_S3_CDN_URL=$DISCOURSE_S3_CDN_URL

# Mock DB and redis during assets precompilation
COPY 003-mock-redis.rb /var/www/discourse/config/initializers/
RUN env SKIP_DB_AND_REDIS=1 bundle exec rake assets:precompile && \
    rm /var/www/discourse/config/initializers/003-mock-redis.rb


ENV UNICORN_BIND_ALL=1
ENV UNICORN_WORKERS=2
ENV UNICORN_SIDEKIQS=1
ENV DISCOURSE_DISABLE_ANON_CACHE=1
# Serve static assets since we aren't using nginx
ENV DISCOURSE_SERVE_STATIC_ASSETS=true
# ENV DISCOURSE_SMTP_ADDRESS=smtp.sendgrid.net
# ENV DISCOURSE_SMTP_USER_NAME=apikey
# ENV DISCOURSE_SMTP_PORT=587
# ENV DISCOURSE_SMTP_ENABLE_START_TLS=true
ENV DISCOURSE_USE_S3=true
ENV DISCOURSE_S3_REGION=anything
ENV DISCOURSE_S3_INSTALL_CORS_RULE=false
ENV DISCOURSE_MAX_REQS_PER_IP_MODE=none
ENV DISCOURSE_MAX_REQS_PER_IP_PER_10_SECONDS=1000
ENV DISCOURSE_LOAD_MINI_PROFILER=false
# Enable cloudflare assets to be loaded.
ENV DISCOURSE_CONTENT_SECURITY_POLICY_SCRIPT_SRC=https://${DISCOURSE_HOSTNAME}/cdn-cgi/scripts/
# ENV ENABLE_LOGRAGE=true
# https://meta.discourse.org/t/sidekiq-is-consuming-too-much-memory-restarting/48395/38?u=saulshanabrook
ENV UNICORN_SIDEKIQ_MAX_RSS=1000
# https://github.com/discourse/discourse_docker/blob/990519e2373ec32055a7742a407e81f4bd606ed4/templates/web.template.yml#L10-L12
ENV RUBY_GLOBAL_METHOD_CACHE_SIZE=131072
ENV RUBY_GC_HEAP_GROWTH_MAX_SLOTS=40000
ENV RUBY_GC_HEAP_INIT_SLOTS=400000
ENV RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=1.5
ENV DISCOURSE_FORCE_HTTPS=true

EXPOSE 3000
COPY discourse.init.sh /usr/bin/init.sh
# Print logs to stdout/stderr instead of to a file.
RUN { echo 'stdout_path nil'; echo 'stderr_path nil'; echo 'logger Logger.new(STDOUT)'; } >> config/unicorn.conf.rb
COPY 999-log-stdout.rb /var/www/discourse/config/initializers/
COPY 999-glitchtip.rb /var/www/discourse/config/initializers/
# Copy error handling to sikekiq so its loaded then
# RUN cat /var/www/discourse/config/initializers/999-glitchtip.rb >> /var/www/discourse/config/initializers/100-sidekiq.rb

CMD ["bundle", "exec", "unicorn", "-c", "config/unicorn.conf.rb"]

