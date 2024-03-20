#!/bin/bash -e

cd "$(dirname "$0")"

docker compose up -d -V --wait --build --pull=always
