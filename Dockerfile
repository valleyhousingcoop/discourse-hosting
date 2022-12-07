# syntax=docker/dockerfile:1
ARG DISCOURSE_TAG=v2.8.13

# https://github.com/discourse/discourse/blob/main/docs/DEVELOPER-ADVANCED.md
# https://hub.docker.com/_/ruby

# Use Ruby < 3.1 to avoid missing net/pop error
# https://github.com/discourse/discourse/pull/15692/files
FROM ruby:3.0

ENV LANG C.UTF-8

# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md#example-cache-apt-packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && \
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

RUN git clone --depth 1 --branch $DISCOURSE_TAG https://github.com/discourse/discourse.git /var/www/discourse

RUN corepack enable
RUN  --mount=type=cache,target=/root/.yarn \
    YARN_CACHE_FOLDER=/root/.yarn \
    yarn install --production --frozen-lockfile
ENV RAILS_ENV production
# RUN bundle config build.rugged --use-system-libraries
RUN bundle install
COPY install-plugins.sh plugins.txt ./
RUN ./install-plugins.sh
RUN bundle exec rake plugin:install_all_gems
RUN env LOAD_PLUGINS=0 bundle exec rake plugin:pull_compatible_all
# Add this patch to allow looking at logs even without admin access, helpful for debugging
# COPY auth_logs.diff /tmp/
# RUN git apply /tmp/auth_logs.diff
CMD bundle exec rails server -b 0.0.0.0 -p 80
