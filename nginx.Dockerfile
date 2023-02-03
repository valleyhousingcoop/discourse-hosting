FROM jonasal/nginx-certbot:4.2.0

COPY nginx.conf /etc/nginx/templates/discourse.conf.template
COPY cloudflare.ini /etc/letsencrypt/cloudflare.ini
ENV NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d/

ENV CERTBOT_AUTHENTICATOR=dns-cloudflare

