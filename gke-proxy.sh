#!/usr/bin/env bash

set -e

if [[ -z $GKE_CLUSTER || -z $GKE_NODE_POOL || -z $GKE_NODE_PORT ]]; then
  echo "GKE_CLUSTER, GKE_NODE_POOL, GKE_NODE_PORT environment variables required"
  exit 1
fi

NGINX_TIMEOUT=${NGINX_TIMEOUT:-30s}
NGINX_PROTOCOL=${NGINX_PROTOCOL:-http}
CHECK_INTERVAL=${CHECK_INTERVAL:-30}

function getNodePoolIPs() {
  echo $(
    gcloud compute instances list \
      --format="value(networkInterfaces[0].accessConfigs[0].natIP)" \
      --filter="name~'^gke-$GKE_CLUSTER-$GKE_NODE_POOL.*'"
  )
}

function setNginxConfig() {
  local gke_ips=$1
  local upstream=""

  for ip in $gke_ips; do
    upstream+="server $ip:$GKE_NODE_PORT; "
  done

  cat <<EOF > /nginx.conf
events {}

http {
  upstream k8s {
    $upstream
  }

  server_tokens off;
  server {
    listen 8080;
    listen [::]:8080;

    location / {
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_connect_timeout $NGINX_TIMEOUT;
      proxy_send_timeout $NGINX_TIMEOUT;
      proxy_read_timeout $NGINX_TIMEOUT;

      proxy_pass $NGINX_PROTOCOL://k8s;
    }
  }
}
EOF
}

function checkAndRunNginx() {
  if ! pgrep "nginx" >/dev/null; then
    nginx -c /nginx.conf &
  fi
}

function reloadNginx() {
  if pgrep "nginx" >/dev/null; then
    nginx -s reload
  fi
}

OLD_GKE_IPS=""

while true; do
  GKE_IPS=$(getNodePoolIPs)

  if [[ "$OLD_GKE_IPS" != "$GKE_IPS" ]]; then
    echo "$(date) -- GKE IPs: $GKE_IPS"
    echo "$(date) -- Updating nginx..."
    setNginxConfig "$GKE_IPS"
    reloadNginx
    echo "$(date) -- Done"
  fi

  checkAndRunNginx

  OLD_GKE_IPS=$GKE_IPS
  sleep $CHECK_INTERVAL
done
