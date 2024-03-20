#!/bin/sh -e

mc config host add myminio $SERVICE_ENDPOINT $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

for BUCKET in $BUCKETS; do
    mc mb myminio/$BUCKET
    mc policy set download myminio/$BUCKET
done
