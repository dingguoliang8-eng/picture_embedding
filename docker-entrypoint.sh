#!/bin/sh
set -e
if [ ! -f /app/data/.picture_embedding.yaml ]; then
  mkdir -p /app/data
  cp /app/picture_embedding.yaml /app/data/.picture_embedding.yaml
fi
exec "$@"
