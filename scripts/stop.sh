#!/bin/bash
# Stop UniFi Observability Stack

set -e

cd "$(dirname "$0")/.."

echo "Stopping UniFi Observability Stack..."
docker compose down

echo "Stack stopped."
