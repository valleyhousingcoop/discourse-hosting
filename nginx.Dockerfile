FROM jonasal/nginx-certbot:4.2.0

RUN mkdir -p /etc/letsencrypt/ && echo "dns_cloudflare_api_token = ${CLOUDFLARE_API_TOKEN}" > /etc/letsencrypt/cloudflare.ini
COPY nginx.conf /etc/nginx/templates/discourse.conf.template
ENV NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d/

ENV CERTBOT_AUTHENTICATOR=dns-cloudflare

