# Install ddclient
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ddclient gettext-base ca-certificates && rm -rf /var/lib/apt/lists/*
# RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing ddclient envsubst
# Copy ddclient config
COPY ddclient.conf /etc/ddclient.conf.template

ARG HOSTNAME
ARG CLOUDFLARE_API_TOKEN
ARG CLOUDFLARE_ZONE
ENV HOSTNAME=$HOSTNAME
ENV CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN
ENV CLOUDFLARE_ZONE=$CLOUDFLARE_ZONE
# Replace env vars in ddclient config
RUN envsubst < /etc/ddclient.conf.template > /etc/ddclient.conf

# Run ddclient in daemon mode
CMD ["ddclient", "-verbose", "-foreground"]
