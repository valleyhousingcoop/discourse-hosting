# syntax=docker/dockerfile:1
# https://github.com/discourse/discourse/blob/main/docs/DEVELOPER-ADVANCED.md
# https://hub.docker.com/_/ruby

# Use Ruby < 3.1 to avoid missing net/pop error
# https://github.com/discourse/discourse/pull/15692/files
FROM ruby:3.1

ENV LANG C.UTF-8

# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md#example-cache-apt-packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y jpegoptim optipng jhead nodejs pngquant brotli gnupg locales locales-all pngcrush imagemagick libmagickwand-dev cmake pkg-config libgit2-dev


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

RUN git clone https://github.com/discourse/discourse.git /var/www/discourse
RUN cd /var/www/discourse && git checkout 083ef4c8a1bf93ed5c4cba292d66ce3e09077f00

RUN corepack enable
RUN  --mount=type=cache,target=/root/.yarn \
    YARN_CACHE_FOLDER=/root/.yarn \
    yarn install --production --frozen-lockfile
ENV RAILS_ENV production
# RUN bundle config build.rugged --use-system-libraries
RUN bundle config --local deployment true
RUN bundle config --local without test development
RUN bundle install
COPY discourse.install-plugins.sh plugins.txt ./
RUN ./discourse.install-plugins.sh
RUN bundle exec rake plugin:install_all_gems
RUN env LOAD_PLUGINS=0 bundle exec rake plugin:pull_compatible_all
# Add this patch to allow looking at logs even without admin access, helpful for debugging
# COPY auth_logs.diff /tmp/
# RUN git apply /tmp/auth_logs.diff


# Create a file so it looks like static assets have been compiled
RUN mkdir -p public/assets
RUN touch public/assets/application.js
COPY discourse.start.sh /usr/bin/start.sh
COPY discourse.init.sh /usr/bin/init.sh
# COPY 999-custom.rb /var/www/discourse/config/initializers/
COPY manifest.rake /var/www/discourse/lib/tasks/
ENV UNICORN_BIND_ALL=1 UNICORN_WORKERS=2 UNICORN_PORT=80 UNICORN_SIDEKIQS=1
ENV DISCOURSE_DISABLE_ANON_CACHE=1 DISCOURSE_SERVE_STATIC_ASSETS=true
CMD ["start.sh"]
