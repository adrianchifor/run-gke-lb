FROM google/cloud-sdk:alpine

LABEL org.opencontainers.image.source https://github.com/adrianchifor/run-gke-lb

RUN apk add --no-cache bash curl nginx

RUN curl -L https://github.com/krallin/tini/releases/download/v0.18.0/tini-static -o /bin/tini \
  && chmod +x /bin/tini

RUN mkdir -p /run/nginx
COPY gke-proxy.sh /bin/
RUN chmod +x /bin/gke-proxy.sh

CMD ["/bin/tini", "--", "/bin/gke-proxy.sh"]
