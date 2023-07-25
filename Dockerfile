# syntax=docker/dockerfile:1
# https://github.com/discourse/discourse/blob/main/docs/DEVELOPER-ADVANCED.md
# https://hub.docker.com/_/ruby
# Check for updates: https://github.com/discourse/discourse_docker/compare/58eada78642c504164ff4952a25ddd2b8c69f9c1...main

FROM ruby:3.2.2
LABEL org.opencontainers.image.source="https://github.com/saulshanabrook/discourse-hosting"
ARG DISCOURSE_TAG
ENV LANG C.UTF-8


# Hard code version codename to remove need for lsb_release
ENV VERSION_CODENAME=bookworm
# Verify version codename
RUN cat /etc/os-release | grep VERSION_CODENAME=$VERSION_CODENAME


ENV KEYRINGS=/usr/share/keyrings/
RUN \
    # Install node, postgres, and yarn packages to install version 18 of nodejs and 15 of postgres.
    curl -ssL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor  > ${KEYRINGS}nodesource.gpg && \
    curl -sSl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor > ${KEYRINGS}postgres.gpg && \
    curl -sSl https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor > ${KEYRINGS}yarn.gpg && \
    echo "deb [signed-by=${KEYRINGS}nodesource.gpg] https://deb.nodesource.com/node_18.x ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/nodesource.list && \
    echo "deb [signed-by=${KEYRINGS}postgres.gpg] http://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    echo "deb [signed-by=${KEYRINGS}yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y jpegoptim optipng jhead nodejs yarn pngquant brotli gnupg locales locales-all pngcrush imagemagick libmagickwand-dev cmake pkg-config libgit2-dev libsqlite3-dev postgresql-client-15 librsvg2-dev libffi-dev && \
    rm -rf /var/lib/apt/lists/*

ENV OXIPNG_VERSION=8.0.0
WORKDIR /tmp/oxipng-install
RUN wget https://github.com/shssoichiro/oxipng/releases/download/v${OXIPNG_VERSION}/oxipng-${OXIPNG_VERSION}-x86_64-unknown-linux-musl.tar.gz \
 && tar -xzf oxipng-${OXIPNG_VERSION}-x86_64-unknown-linux-musl.tar.gz \
 && cp oxipng-${OXIPNG_VERSION}-x86_64-unknown-linux-musl/oxipng /usr/local/bin \
 && rm -rf /tmp/oxipng-install

RUN npm install -g svgo terser uglify-js

ENV BUNDLER_VERSION='2.3.22'
RUN gem install bundler --no-document -v '2.3.22'


WORKDIR /home/discourse/discourse
RUN mkdir -p tmp/sockets log tmp/pids


# Only fetch one commit to reduce size
# https://stackoverflow.com/a/43136160/907060
# Actually just fetch one tag
RUN git config --global http.sslVerify false && \
    git clone https://github.com/discourse/discourse.git --depth 1 --branch tests-passed /var/www/discourse && \
    cd /var/www/discourse && \
    git fetch --depth 1 origin $DISCOURSE_TAG && \
    git checkout FETCH_HEAD

WORKDIR /var/www/discourse


# RUN corepack enable
RUN yarn install --frozen-lockfile && \
    cd app/assets/javascripts/discourse && \
    yarn add broccoli-plugin && \
    node_modules/.bin/ember install @sentry/ember && \
    yarn cache clean
ENV RAILS_ENV production
RUN bundle config --local without test development
RUN bundle add sentry-ruby --skip-install --version '>=5.8.0' && \
    bundle add mock_redis sqlite3 debug sentry-rails sentry-sidekiq --skip-install && \
    bundler install --no-cache
COPY discourse.install-plugins.sh plugins.txt ./
RUN ./discourse.install-plugins.sh
RUN bundle exec rake plugin:install_all_gems
RUN env LOAD_PLUGINS=0 bundle exec rake plugin:pull_compatible_all



ARG DISCOURSE_HOSTNAME
ARG DISCOURSE_S3_CDN_URL
ARG SENTRY_DSN
ENV DISCOURSE_HOSTNAME=$DISCOURSE_HOSTNAME
ENV DISCOURSE_S3_CDN_URL=$DISCOURSE_S3_CDN_URL
ENV SENTRY_DSN=$SENTRY_DSN

# Mock DB and redis during assets precompilation
COPY 003-mock-redis.rb ./config/initializers/
# Add sentry to assets precompilation
# https://docs.sentry.io/platforms/javascript/guides/ember/
RUN { echo 'import * as Sentry from "@sentry/ember"; Sentry.init({dsn: ' \"${SENTRY_DSN}\" ', tracesSampleRate: 0.1, autoSessionTracking: false})'; cat app/assets/javascripts/discourse/app/app.js; } > tmp.js && \
    mv -f tmp.js app/assets/javascripts/discourse/app/app.js

# Turn off discourse subscription client initialization for assets precompilation, since DB and redis aren't ready
# Add `  next` after `after_initialize do` line so that it ends early in
#  /var/www/discourse/plugins/discourse-subscription-client/plugin.rb
RUN cp /var/www/discourse/plugins/discourse-subscription-client/plugin.rb /var/www/discourse/plugins/discourse-subscription-client/plugin.rb.bak
RUN sed -i 's/after_initialize do/after_initialize do\n  next/' /var/www/discourse/plugins/discourse-subscription-client/plugin.rb

# Similarily add `  next` before the line containing DB.query_single in discourse-ai plugin
RUN cp /var/www/discourse/plugins/discourse-ai/plugin.rb /var/www/discourse/plugins/discourse-ai/plugin.rb.bak
RUN sed -i 's/  if DB.query_single/  next\n  if DB.query_single/' /var/www/discourse/plugins/discourse-ai/plugin.rb

# Need this for proper service worker compilation so it adds the right URL
# https://github.com/discourse/discourse/pull/22019/files#diff-5aa550c12017fd0bbcf7b37c23c1242e67f73afd84a618ff28dbebab6c2d32dbR4
# Need to have the `use_s3` preference be true, so set thes S3 env vars

RUN env SKIP_DB_AND_REDIS=1 \
        DISCOURSE_S3_BUCKET=1 \
        DISCOURSE_S3_REGION=1 \
        DISCOURSE_S3_USE_IAM_PROFILE=1 \
        bundle exec rake assets:precompile

RUN rm ./config/initializers/003-mock-redis.rb
# Revert backup
RUN mv -f /var/www/discourse/plugins/discourse-subscription-client/plugin.rb.bak /var/www/discourse/plugins/discourse-subscription-client/plugin.rb
RUN mv -f /var/www/discourse/plugins/discourse-ai/plugin.rb.bak /var/www/discourse/plugins/discourse-ai/plugin.rb

EXPOSE 3000
# Print logs to stdout/stderr instead of to a file.
RUN { echo 'stdout_path nil'; echo 'stderr_path nil'; echo 'logger Logger.new(STDOUT)'; } >> config/unicorn.conf.rb
COPY 999-log-stdout.rb 000-glitchtip.rb ./config/initializers/
COPY discourse.run.sh ./

# Only the sidekiq initializer is loaded for jobs, so move error handling to that.
RUN cat /var/www/discourse/config/initializers/000-glitchtip.rb >> /var/www/discourse/config/initializers/100-sidekiq.rb && \
    rm /var/www/discourse/config/initializers/000-glitchtip.rb

# Replace `klass.class_eval patches` with `return` in lib/method_profiler.rb to support sentry
# https://github.com/getsentry/sentry-ruby/issues/1999
RUN sed -i 's/klass.class_eval patches/return/' /var/www/discourse/lib/method_profiler.rb

CMD ["./discourse.run.sh"]

