# UniFi Home Network Architecture

## Overview

This document describes the complete home network architecture including VLAN segmentation, DNS infrastructure, monitoring stack, and device assignments.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INTERNET                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
              ┌─────▼─────┐                   ┌─────▼─────┐
              │ Internet 1│                   │ Internet 2│
              │  (WAN)    │                   │  (WAN2)   │
              │ Primary   │                   │ Failover  │
              └─────┬─────┘                   └─────┬─────┘
                    │                               │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │   UniFi Cloud Gateway Ultra   │
                    │        192.168.1.1            │
                    │   (Router/Firewall/DHCP)      │
                    └───────────────┬───────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────────┐
        │                           │                               │
  ┌─────▼─────┐              ┌──────▼──────┐               ┌────────▼────────┐
  │ USW Flex  │              │   Port 1    │               │   WiFi APs      │
  │ (Switch)  │              │ Trunk Port  │               │                 │
  │ Ports 2-4 │              │ to Proxmox  │               │ • Inferno 🔥    │
  │Entertainment│            │             │               │ • Galaxy 🌌     │
  └───────────┘              └──────┬──────┘               │ • Digital       │
                                    │                      │ • UniFi Identity│
                             ┌──────▼──────┐               └─────────────────┘
                             │   Proxmox   │
                             │   Server    │
                             │192.168.1.204│
                             └─────────────┘
```

---

## Network Segmentation (VLANs)

| VLAN | Name | Subnet | Gateway | DHCP Range | Purpose |
|------|------|--------|---------|------------|---------|
| 1 | Default | 192.168.1.0/24 | 192.168.1.1 | .6 - .254 | Infrastructure & trusted wired devices |
| 2 | Dreamers | 192.168.2.0/24 | 192.168.2.1 | .6 - .254 | Kids devices (content filtered) |
| 5 | Homelab | 192.168.5.0/24 | 192.168.5.1 | .6 - .254 | Proxmox VMs and lab infrastructure |
| 8 | Creators | 192.168.8.0/24 | 192.168.8.1 | .6 - .254 | Adult devices |
| 10 | Digital | 192.168.10.0/24 | 192.168.10.1 | .6 - .254 | IoT devices (Nest, Ring, printers) |
| 15 | Entertainment | 192.168.15.0/24 | 192.168.15.1 | .100 - .254 | Gaming & streaming devices |
| 17 | VPN | 192.168.17.0/24 | 192.168.17.1 | .6 - .254 | WireGuard VPN clients |
| 20 | IoT | 192.168.20.0/24 | 192.168.20.1 | .100 - .254 | Additional IoT devices |

---

## WiFi Networks (SSIDs)

| SSID | Security | Network/VLAN | Band | Purpose |
|------|----------|--------------|------|---------|
| Inferno🔥 | WPA2/WPA3 | Creators (VLAN 8) | 2.4/5/6 GHz | Adults |
| Galaxy🌌🪐💫☄️ | WPA2/WPA3 | Dreamers (VLAN 2) | 2.4/5/6 GHz | Kids (filtered) |
| Digital | WPA2/WPA3 | Digital (VLAN 10) | 2.4/5/6 GHz | IoT devices |
| UniFi Identity | WPA2/WPA3 | Default (VLAN 1) | 2.4/5/6 GHz | Management |

**Note:** PMF (802.11w) is set to "optional" on Digital network for IoT compatibility.

---

## DNS Infrastructure

```
┌─────────────────────────────────────────────────────────────────┐
│                    DNS Server (LXC CT 100)                      │
│                       192.168.1.53                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────────┐      ┌─────────────────────┐         │
│   │   AdGuard Home      │      │      Unbound        │         │
│   │   Port 53 (DNS)     │─────▶│   Port 5335         │         │
│   │   Port 3000 (Web)   │      │   (Recursive DNS)   │         │
│   │                     │      │                     │         │
│   │ • Ad blocking       │      │ • Privacy-focused   │         │
│   │ • Parental controls │      │ • No forwarding     │         │
│   │ • Query logging     │      │ • DNSSEC validation │         │
│   └─────────────────────┘      └─────────────────────┘         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### AdGuard Home Configuration

- **Web UI**: http://192.168.1.53:3000
- **DNS Port**: 53
- **Upstream DNS**: 127.0.0.1:5335 (Unbound)

### Client Groups & Filtering

| Group | Networks | Blocked Services | Safe Search |
|-------|----------|------------------|-------------|
| Kids-Dreamers | 192.168.2.0/24 | TikTok, Snapchat, Discord, Twitch, Reddit, Tinder, OnlyFans | Enforced |
| Adults-Default | All others | None | Off |

### Whitelisted Services (Kids)
- Apple & iCloud services
- Netflix
- Disney+
- YouTube Kids
- Amazon Prime Video

### Local DNS Names (.home domain)

All devices can be accessed by hostname using the `.home` domain (configured in /etc/hosts on DNS server):

| Hostname | IP Address | Description |
|----------|------------|-------------|
| **Infrastructure** |||
| gateway.home | 192.168.1.1 | UniFi Cloud Gateway |
| unifi.home | 192.168.1.1 | UniFi Controller |
| dns.home | 192.168.1.53 | DNS Server |
| adguard.home | 192.168.1.53 | AdGuard Home Web UI |
| proxmox.home | 192.168.1.204 | Proxmox VE |
| grafana.home | 192.168.1.204 | Grafana Dashboards |
| prometheus.home | 192.168.1.204 | Prometheus Metrics |
| mac-mini.home | 192.168.1.118 | Mac Mini |
| **Homelab VMs** |||
| qlp-master.home | 192.168.5.212 | Primary app server |
| qlp-beta.home | 192.168.5.150 | Beta/staging |
| quintelligence.home | 192.168.5.25 | AI/ML workloads |
| quantumnews.home | 192.168.5.125 | News aggregation |
| localgpt.home | 192.168.5.131 | Local LLM |
| labverse.home | 192.168.5.16 | Lab environment |
| careerfied.home | 192.168.5.89 | Career platform |
| **Entertainment** |||
| ps5.home | 192.168.15.144 | PlayStation 5 |
| appletv.home | 192.168.15.164 | Apple TV |
| soundbar.home | 192.168.15.205 | Bose Soundbar 900 |

**Quick Access URLs:**
- Grafana: http://grafana.home:3000
- AdGuard: http://adguard.home:3000
- Proxmox: https://proxmox.home:8006
- UniFi: https://unifi.home

---

## Observability Stack

```
┌─────────────────────────────────────────────────────────────────┐
│              Observability Stack (Docker Compose)               │
│                    192.168.1.204:3000                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│   │   Grafana    │◀───│  Prometheus  │◀───│   Unpoller   │     │
│   │  Port 3000   │    │  Port 9090   │    │  Port 9130   │     │
│   │              │    │              │    │              │     │
│   │ Dashboards:  │    │ • 15s scrape │    │ • API Key    │     │
│   │ • Clients    │    │ • 15d retain │    │   auth       │     │
│   │ • Gateway    │    │              │    │ • Poll every │     │
│   │ • APs        │    │              │    │   30s        │     │
│   │ • DPI        │    │              │    │              │     │
│   │ • Sites      │    │              │    │              │     │
│   └──────────────┘    └──────────────┘    └──────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Grafana Dashboards

| Dashboard | URL | Purpose |
|-----------|-----|---------|
| UniFi Clients | http://192.168.1.204:3000/d/jMfvAjxWz | Client stats per network |
| UniFi Gateway | http://192.168.1.204:3000/d/4Yo8IZ-Wk | WAN performance, routing |
| UniFi DPI | http://192.168.1.204:3000/d/w3usaHLZk | Deep packet inspection |
| UniFi Access Points | http://192.168.1.204:3000/d/g5wFWqxZk | WiFi AP metrics |
| UniFi Sites | http://192.168.1.204:3000/d/7LglOlHWz | Site overview |
| UniFi Switches | http://192.168.1.204:3000/d/XsuKlHPGk | Switch port stats |

### Credentials

| Service | Username | Password | Notes |
|---------|----------|----------|-------|
| Grafana | admin | admin | http://192.168.1.204:3000 |
| AdGuard Home | - | - | http://192.168.1.53:3000 |
| UniFi Controller | - | API Key | Via Cloud Gateway |

---

## Device Inventory

### Default Network (VLAN 1) - Infrastructure

| Device | IP | MAC | Purpose |
|--------|-----|-----|---------|
| Cloud Gateway Ultra | 192.168.1.1 | - | Router/Firewall |
| DNS Server (LXC) | 192.168.1.53 | bc:24:11:81:18:79 | AdGuard + Unbound |
| Proxmox Host | 192.168.1.204 | c8:7f:54:c5:7e:9b | Hypervisor |
| satish-mini | 192.168.1.118 | 00:24:27:15:63:62 | Mac Mini |

### Homelab Network (VLAN 5) - Proxmox VMs

| VM | VMID | IP | Purpose |
|----|------|-----|---------|
| qlp-master | 104 | 192.168.5.212 | Primary app server |
| qlp-beta | 110 | 192.168.5.150 | Beta/staging |
| Quintelligence | 888 | 192.168.5.25 | AI/ML workloads |
| QuantumNews | 777 | 192.168.5.125 | News aggregation |
| LabGPT | 109 | 192.168.5.131 | Local LLM |
| LabVerse | 666 | 192.168.5.16 | Lab environment |
| careerfied | 1001 | 192.168.5.89 | Career platform |

### Digital Network (VLAN 10) - IoT Devices

| Device | IP | Type |
|--------|-----|------|
| Nest Thermostat | 192.168.10.x | Smart Home |
| Ring Doorbell | 192.168.10.133 | Security |
| HP Printer | 192.168.10.220 | Printer |
| Nest Hub | 192.168.10.x | Smart Display |

### Entertainment Network (VLAN 15)

| Device | IP | MAC |
|--------|-----|-----|
| PlayStation 5 | 192.168.15.144 | 70:66:2a:b2:bb:16 |
| Apple TV | 192.168.15.164 | c0:95:6d:85:7b:8b |
| Bose Soundbar 900 | 192.168.15.205 | 78:2b:64:6f:d2:e9 |

---

## Key Configuration Files

### Observability Stack
```
/root/projects/unifi-observability/
├── docker-compose.yml          # Main compose file
├── prometheus/
│   └── config/
│       └── prometheus.yml      # Prometheus config
├── grafana/
│   └── provisioning/
│       ├── datasources/        # Prometheus datasource
│       └── dashboards/         # UniFi dashboards
└── unpoller/
    └── .env                    # Unpoller credentials
```

### DNS Server (CT 100)
```
/etc/unbound/unbound.conf.d/adguard.conf   # Unbound config
/opt/AdGuardHome/AdGuardHome.yaml          # AdGuard config
```

---

## API Access

### UniFi Controller API

```bash
# Base URL
https://192.168.1.1/proxy/network/api/s/default/

# Authentication Header
X-API-Key: I13ThZb9WjeXUTzzJAYRYTibm5unKndh

# Example: List networks
curl -s -k 'https://192.168.1.1/proxy/network/api/s/default/rest/networkconf' \
  -H "X-API-Key: I13ThZb9WjeXUTzzJAYRYTibm5unKndh"

# Example: List clients
curl -s -k 'https://192.168.1.1/proxy/network/api/s/default/stat/sta' \
  -H "X-API-Key: I13ThZb9WjeXUTzzJAYRYTibm5unKndh"
```

### Prometheus API

```bash
# Query metrics
curl -s "http://192.168.1.204:9090/api/v1/query?query=up"

# Client count by network
curl -s "http://192.168.1.204:9090/api/v1/query" \
  --data-urlencode 'query=count(unpoller_client_uptime_seconds) by (network)'
```

---

## Maintenance Commands

### Docker Compose (Observability)
```bash
cd /root/projects/unifi-observability

# Start stack
docker compose up -d

# View logs
docker compose logs -f

# Restart specific service
docker compose restart grafana

# Update images
docker compose pull && docker compose up -d
```

### Proxmox VM Management
```bash
# List VMs
qm list

# Check VM network config
qm config <vmid> | grep net

# Add VLAN tag to VM
qm set <vmid> -net0 virtio=<mac>,bridge=vmbr0,tag=5,firewall=1
```

### DNS Server (CT 100)
```bash
# SSH to DNS server
ssh root@192.168.1.53

# Restart Unbound
systemctl restart unbound

# Restart AdGuard Home
systemctl restart AdGuardHome

# Check AdGuard status
systemctl status AdGuardHome
```

---

## Troubleshooting

### IoT Device Won't Connect
1. Check PMF setting on WiFi network (should be "optional" for IoT)
2. Verify VLAN assignment on switch port
3. Check DHCP lease availability

### VM Not Getting VLAN IP
1. Verify trunk port configuration on Cloud Gateway
2. Check VM network config: `qm config <vmid> | grep net`
3. Hotplug network interface or reboot VM

### DNS Not Resolving
1. Check AdGuard Home status: http://192.168.1.53:3000
2. Verify Unbound is running: `systemctl status unbound`
3. Test resolution: `dig @192.168.1.53 google.com`

### Grafana Dashboard Empty
1. Check Prometheus targets: http://192.168.1.204:9090/targets
2. Verify Unpoller is scraping: check `unpoller` container logs
3. Confirm API key is valid

---

## Network Diagram (ASCII)

```
                                    INTERNET
                                       │
                    ┌──────────────────┴──────────────────┐
                    │      UniFi Cloud Gateway Ultra      │
                    │            192.168.1.1              │
                    └──────────────────┬──────────────────┘
                                       │
       ┌───────────────┬───────────────┼───────────────┬───────────────┐
       │               │               │               │               │
   ┌───┴───┐       ┌───┴───┐       ┌───┴───┐       ┌───┴───┐       ┌───┴───┐
   │VLAN 1 │       │VLAN 2 │       │VLAN 5 │       │VLAN 8 │       │VLAN 10│
   │Default│       │Dreamers│      │Homelab│       │Creators│      │Digital│
   │.1.0/24│       │.2.0/24│       │.5.0/24│       │.8.0/24│       │.10.0/24│
   └───┬───┘       └───┬───┘       └───┬───┘       └───┬───┘       └───┬───┘
       │               │               │               │               │
   • Proxmox       • Kids iPads    • qlp-master    • iPhones       • Nest
   • DNS Server    • Kids Macs     • qlp-beta      • MacBooks      • Ring
   • Mac Mini                      • LabGPT        • Watches       • Printer
                                   • LabVerse
                                   • QuantumNews        ┌───────────────┐
                                   • Quintelligence     │   VLAN 15     │
                                   • careerfied         │ Entertainment │
                                                        │  .15.0/24     │
                                                        └───────┬───────┘
                                                                │
                                                            • PS5
                                                            • Apple TV
                                                            • Bose Soundbar
```

---

## Change Log

| Date | Change | Notes |
|------|--------|-------|
| 2026-01-19 | Initial setup | Created observability stack |
| 2026-01-19 | Network segmentation | Created VLANs 2, 5, 8, 10, 15, 20 |
| 2026-01-19 | DNS infrastructure | AdGuard Home + Unbound on CT 100 |
| 2026-01-19 | Parental controls | Configured Kids-Dreamers filtering |
| 2026-01-19 | VM migration | Moved 7 VMs to Homelab VLAN 5 |
| 2026-01-19 | Entertainment setup | PS5, Apple TV, Bose on VLAN 15 |

---

## GitHub Repository

- **URL**: https://github.com/homelab-network/unifi-observability
- **Contains**: Docker Compose, Prometheus config, Grafana dashboards
