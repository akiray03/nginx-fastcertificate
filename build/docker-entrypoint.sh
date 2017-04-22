#!/bin/bash

rm -f /usr/local/nginx/conf/env_vars.conf
for e in $(env | grep -E "_PROXY_TO_(HOST|PORT)" | cut -d'=' -f1)
do
  echo "env $e;"
done > /usr/local/nginx/conf/env_vars.conf

if [ ! -z "$NGINX_WORKER_PROCESSES" ]; then
  rm -f /usr/local/nginx/conf/worker_processes.conf
  echo "worker_processes $NGINX_WORKER_PROCESSES;" > /usr/local/nginx/conf/worker_processes.conf
fi

if [ -z "$INTERNAL_IP" ]; then
  case $CLOUD_PROVIDER in
    GCP|Google|GOOGLE)
      export INTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
      ;;
    AWS|Amazon)
      export INTERNAL_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
      ;;
  esac
fi

echo "INTERNAL_IP is $INTERNAL_IP"

exec "$@"
