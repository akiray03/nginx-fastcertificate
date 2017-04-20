#!/bin/bash

if [ -f /usr/local/nginx/conf/nginx.conf ]; then
  mv /usr/local/nginx/conf/nginx.conf /tmp/nginx.conf
  for e in $(env | grep -E "_PROXY_TO_(HOST|PORT)" | cut -d'=' -f1)
  do
    echo "env $e; # REPLACE_LINE"
  done > /tmp/env-vars

  echo "worker_processes $NGINX_WORKER_PROCESSES; # REPLACE_LINE" > /tmp/ngx_worker
  cat /tmp/ngx_worker /tmp/env-vars /tmp/nginx.conf | grep -v REPLACE_LINE > /usr/local/nginx/conf/nginx.conf
fi

export INTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

cat /usr/local/nginx/conf/nginx.conf

echo "INTERNAL_IP is $INTERNAL_IP"

exec "$@"
