#!/bin/bash
# Start UniFi Observability Stack

set -e

cd "$(dirname "$0")/.."

echo "Starting UniFi Observability Stack..."
docker compose up -d

echo ""
echo "Services starting:"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana:    http://localhost:3000"
echo "  - Unpoller:   http://localhost:9130/metrics"
echo ""
echo "Use 'docker compose logs -f' to view logs"
