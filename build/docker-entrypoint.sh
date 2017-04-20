#!/bin/bash

rm -f /usr/local/nginx/conf/env_vars.conf
for e in $(env | grep -E "_PROXY_TO_(HOST|PORT)" | cut -d'=' -f1)
do
  echo "env $e; # REPLACE_LINE"
done > /tmp/env-vars
echo "worker_processes $NGINX_WORKER_PROCESSES; # REPLACE_LINE" > /usr/local/nginx/conf/env_vars.conf

if [ ! -z "$NGINX_WORKER_PROCESSES" ]; then
  rm -f /usr/local/nginx/conf/worker_processes.conf
  echo "worker_processes $NGINX_WORKER_PROCESSES;" > /usr/local/nginx/conf/worker_processes.conf
fi

if [ -z "$INTERNAL_IP" ]; then
  export INTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
  cat /usr/local/nginx/conf/nginx.conf
fi
echo "INTERNAL_IP is $INTERNAL_IP"

exec "$@"
