#!/bin/bash
# View logs for UniFi Observability Stack

cd "$(dirname "$0")/.."

docker compose logs -f "$@"
