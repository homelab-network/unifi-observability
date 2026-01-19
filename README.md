# UniFi Observability Stack

Production-ready monitoring stack for UniFi Network infrastructure using Prometheus, Grafana, and Unpoller.

## Components

| Service | Port | Description |
|---------|------|-------------|
| Prometheus | 9090 | Metrics storage and query engine |
| Grafana | 3000 | Visualization and dashboards |
| Unpoller | 9130 | UniFi metrics exporter |
| Dozzle | 8080 | Container log viewer (optional) |

## Quick Start

### 1. Configure Unpoller

Edit `unpoller/.env` with your UniFi controller credentials.

**Option A: API Key (Recommended for Cloud Gateway)**
```bash
UP_UNIFI_CONTROLLER_0_URL=https://192.168.1.1
UP_UNIFI_CONTROLLER_0_API_KEY=your_api_key_here
```

Generate an API key in UniFi: Settings → Control Plane → API Tokens → Create

**Option B: Username/Password (Self-hosted controllers)**
```bash
UP_UNIFI_CONTROLLER_0_URL=https://192.168.1.1
UP_UNIFI_CONTROLLER_0_USER=unpoller
UP_UNIFI_CONTROLLER_0_PASS=your_password
```

Create a dedicated local-only admin user in UniFi for this method.

### 2. Configure Grafana (Optional)

Edit `.env` to set Grafana admin credentials:

```bash
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your_secure_password
```

### 3. Start the Stack

```bash
docker compose up -d
```

Or use the helper script:

```bash
./scripts/start.sh
```

### 4. Access Dashboards

- **Grafana:** http://localhost:3000
- **Prometheus:** http://localhost:9090
- **Unpoller Metrics:** http://localhost:9130/metrics

## Included Dashboards

- **UniFi Access Points** - WiFi performance, client counts, channel utilization
- **UniFi Switches** - Port statistics, PoE usage, throughput
- **UniFi Clients** - Connected devices, bandwidth usage
- **UniFi Gateway** - WAN metrics, firewall stats, VPN status
- **UniFi Sites** - Multi-site overview
- **UniFi DPI** - Deep packet inspection data (requires DPI enabled)
- **UniFi PDU** - Power distribution unit metrics

## Directory Structure

```
.
├── docker-compose.yml       # Main compose file
├── .env                     # Docker compose environment
├── prometheus/
│   ├── config/              # Prometheus configuration
│   ├── data/                # Metrics storage (gitignored)
│   └── rules/               # Alert rules
├── grafana/
│   ├── data/                # Grafana data (gitignored)
│   └── provisioning/
│       ├── datasources/     # Auto-configured datasources
│       └── dashboards/      # Dashboard JSON files
├── unpoller/
│   └── .env                 # Unpoller configuration
├── dozzle/
│   └── .env                 # Dozzle configuration
└── scripts/
    ├── start.sh             # Start the stack
    ├── stop.sh              # Stop the stack
    └── logs.sh              # View logs
```

## Configuration

### Prometheus Retention

Default retention is 90 days or 10GB (whichever comes first). Modify in `docker-compose.yml`:

```yaml
command:
  - '--storage.tsdb.retention.time=90d'
  - '--storage.tsdb.retention.size=10GB'
```

### Scrape Interval

If you receive 429 (rate limit) errors from UniFi, increase the scrape interval in `prometheus/config/prometheus.yml`:

```yaml
scrape_interval: 120s  # Increase from 60s
```

### Enable DPI Metrics

To collect Deep Packet Inspection data, enable in `unpoller/.env`:

```bash
UP_UNIFI_CONTROLLER_0_SAVE_DPI=true
```

Note: This significantly increases metrics volume.

## Optional: Log Viewer

Start with the Dozzle log viewer profile:

```bash
docker compose --profile logs up -d
```

Access at http://localhost:8080

## Troubleshooting

### Unpoller not collecting metrics

1. Verify UniFi credentials in `unpoller/.env`
2. Check Unpoller logs: `docker compose logs unpoller`
3. Test metrics endpoint: `curl http://localhost:9130/metrics`

### Grafana dashboards empty

1. Verify Prometheus is healthy: http://localhost:9090/-/healthy
2. Check Prometheus targets: http://localhost:9090/targets
3. Ensure Unpoller target shows "UP"

### Rate limiting (429 errors)

Increase scrape interval to 120s or higher in Prometheus config.

## License

MIT
