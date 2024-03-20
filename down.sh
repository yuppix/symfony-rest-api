#!/bin/bash -e

docker compose down -v
rm -f api/public/done
rm -f admin/public/done
