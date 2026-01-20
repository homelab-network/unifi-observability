# Session Context - UniFi Home Network Setup

**Last Updated:** 2026-01-20
**Session Status:** Complete - Ready for future enhancements

---

## What Was Accomplished

### 1. UniFi Observability Stack
- Created Docker Compose stack with Prometheus, Grafana, and Unpoller
- Configured Unpoller with API key authentication (not username/password)
- Loaded 7 UniFi dashboards + 1 custom "Home Network Overview" dashboard
- Enabled DPI (Deep Packet Inspection) metrics
- Repository: https://github.com/homelab-network/unifi-observability

### 2. Network Segmentation (7 VLANs)
| VLAN | Name | Subnet | Purpose |
|------|------|--------|---------|
| 1 | Default | 192.168.1.0/24 | Infrastructure (Proxmox host, DNS, Mac Mini) |
| 2 | Dreamers | 192.168.2.0/24 | Kids devices (content filtered) |
| 5 | Homelab | 192.168.5.0/24 | Proxmox VMs |
| 8 | Creators | 192.168.8.0/24 | Adult devices |
| 10 | Digital | 192.168.10.0/24 | IoT (Nest, Ring, printers) |
| 15 | Entertainment | 192.168.15.0/24 | PS5, Apple TV, Bose Soundbar |
| 20 | IoT | 192.168.20.0/24 | Additional IoT |

### 3. WiFi Networks
| SSID | VLAN | Users |
|------|------|-------|
| Inferno🔥 | Creators (8) | Adults |
| Galaxy🌌🪐💫☄️ | Dreamers (2) | Kids (filtered) |
| Digital | Digital (10) | IoT devices |
| UniFi Identity | Default (1) | Management |

### 4. DNS Infrastructure (LXC CT 100 - 192.168.1.53)
- **AdGuard Home** (port 53 DNS, port 3000 Web UI)
  - Upstream: Unbound on 127.0.0.1:5335
  - Parental controls for Kids network (192.168.2.0/24)
  - Blocked: TikTok, Snapchat, Discord, Twitch, Reddit, Tinder, OnlyFans
  - Whitelisted: Apple, iCloud, Netflix, Disney+, YouTube Kids, Amazon Prime
- **Unbound** (recursive DNS on port 5335)
  - Privacy-focused, no forwarding
  - DNSSEC enabled

### 5. Local DNS Names (.home domain)
Configured in /etc/hosts on DNS server:
```
# Infrastructure
gateway.home / unifi.home    -> 192.168.1.1
dns.home / adguard.home      -> 192.168.1.53
proxmox.home / grafana.home / prometheus.home -> 192.168.1.204
mac-mini.home                -> 192.168.1.118

# Homelab VMs (VLAN 5)
qlp-master.home      -> 192.168.5.212
qlp-beta.home        -> 192.168.5.150
quintelligence.home  -> 192.168.5.25
quantumnews.home     -> 192.168.5.125
localgpt.home        -> 192.168.5.131
labverse.home        -> 192.168.5.16
careerfied.home      -> 192.168.5.89

# Entertainment (VLAN 15)
ps5.home        -> 192.168.15.144
appletv.home    -> 192.168.15.164
soundbar.home   -> 192.168.15.205
```

### 6. Proxmox VM Migration
- Configured Cloud Gateway Port 1 as trunk port (VLAN 5 tagged)
- Moved 7 VMs from Default to Homelab VLAN 5
- Used hotplug to apply VLAN tags without rebooting

### 7. Entertainment Network Setup
- Created VLAN 15 (Entertainment)
- Configured USW Flex ports 2,3,4 for entertainment devices
- PS5, Apple TV, Bose Soundbar all connected

### 8. IoT Device Fix
- Nest thermostat went offline due to PMF (802.11w) set to "required"
- Fixed by changing PMF to "optional" on Digital WiFi
- Ring doorbell and HP printer also recovered

---

## Current Credentials

| Service | Username | Password | URL |
|---------|----------|----------|-----|
| Grafana | admin | admin | http://grafana.home:3000 |
| AdGuard Home | admin | admin | http://adguard.home:3000 |
| Proxmox | root | (your system password) | https://proxmox.home:8006 |
| UniFi | - | API Key | https://unifi.home |

**UniFi API Key:** `I13ThZb9WjeXUTzzJAYRYTibm5unKndh`

---

## Key Files & Locations

### On Proxmox Host (192.168.1.204)
```
/root/projects/unifi-observability/
├── docker-compose.yml
├── prometheus/config/prometheus.yml
├── grafana/provisioning/dashboards/
│   └── home-network-overview.json  (custom dashboard)
├── unpoller/.env
├── ARCHITECTURE.md
└── SESSION_CONTEXT.md (this file)
```

### On DNS Server (LXC CT 100 - 192.168.1.53)
```
/opt/AdGuardHome/AdGuardHome.yaml  - AdGuard config
/etc/unbound/unbound.conf.d/       - Unbound config
/etc/hosts                         - Local DNS entries
```

---

## Useful Commands

### Observability Stack
```bash
cd /root/projects/unifi-observability
docker compose up -d          # Start stack
docker compose logs -f        # View logs
docker compose restart grafana # Restart Grafana
```

### Proxmox VM Management
```bash
qm list                       # List all VMs
qm config <vmid>              # Show VM config
qm start/stop <vmid>          # Start/stop VM
```

### DNS Server (via Proxmox)
```bash
ssh root@192.168.1.204 "pct exec 100 -- <command>"
# Or directly if SSH key is set up:
ssh root@192.168.1.53
```

### UniFi API Examples
```bash
# List networks
curl -sk 'https://192.168.1.1/proxy/network/api/s/default/rest/networkconf' \
  -H "X-API-Key: I13ThZb9WjeXUTzzJAYRYTibm5unKndh"

# List clients
curl -sk 'https://192.168.1.1/proxy/network/api/s/default/stat/sta' \
  -H "X-API-Key: I13ThZb9WjeXUTzzJAYRYTibm5unKndh"
```

---

## Pending / Future Enhancements

Not started - for future sessions:

1. **Security**
   - [ ] Firewall rules between VLANs (block IoT from Homelab)
   - [ ] IDS/IPS configuration
   - [ ] Fail2ban on exposed services

2. **Alerting**
   - [ ] Prometheus Alertmanager setup
   - [ ] Notifications (Slack/email) for WAN failover, device offline

3. **Backup**
   - [ ] Proxmox VM backups to TrueNAS or PBS
   - [ ] Config backup automation

4. **Logging**
   - [ ] Loki + Promtail for centralized logs
   - [ ] Syslog from UniFi devices

5. **Network**
   - [ ] Speed test automation
   - [ ] Wake-on-LAN setup

6. **Reverse Proxy**
   - [ ] Traefik/Nginx with SSL for internal services

---

## Known Issues / Notes

1. **AdGuard Rewrites**: The YAML `rewrites:` section adds `enabled: false` automatically. Workaround: use `/etc/hosts` instead (currently in use).

2. **Grafana Dashboard Datasource**: Custom dashboards must use UID `PBFA97CFB590B2093` for Prometheus datasource.

3. **PMF Compatibility**: IoT devices (Nest, Ring) require PMF set to "optional" not "required".

4. **VM VLAN Changes**: Require hotplug (detach/reattach network) or reboot to take effect on running VMs.

---

## How to Resume

1. SSH to Proxmox: `ssh root@192.168.1.204`
2. Navigate to project: `cd /root/projects/unifi-observability`
3. Check stack status: `docker compose ps`
4. Read this file for context: `cat SESSION_CONTEXT.md`
5. Read full architecture: `cat ARCHITECTURE.md`

---

## GitHub Repository

**URL:** https://github.com/homelab-network/unifi-observability

Contains:
- Docker Compose configuration
- Prometheus config
- Grafana dashboards (including custom Home Network Overview)
- Full architecture documentation
- This session context file
