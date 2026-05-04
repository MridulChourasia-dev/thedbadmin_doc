# 📖 Detailed Setup Guide

This guide walks through every step required to set up the PostgreSQL Monitoring Stack in a production-like environment.

---

## Table of Contents

1. [System Requirements](#1-system-requirements)
2. [Monitoring Server Setup](#2-monitoring-server-setup)
3. [DB Server Setup](#3-db-server-setup)
4. [Configuring Prometheus](#4-configuring-prometheus)
5. [Configuring Alertmanager](#5-configuring-alertmanager)
6. [Configuring Grafana](#6-configuring-grafana)
7. [Starting the Stack](#7-starting-the-stack)
8. [Post-setup Verification](#8-post-setup-verification)

---

## 1. System Requirements

### Monitoring Server
- Linux (Ubuntu 20.04+ recommended) or macOS
- Docker Engine 20.10+
- Docker Compose v2 (`docker compose` command)
- 1 GB RAM minimum (2 GB recommended)
- 10 GB disk space for metrics retention (15-day default)

### DB Server
- Linux (Ubuntu 20.04+ / RHEL 8+)
- PostgreSQL 12+
- `wget`, `tar`, `systemd` available
- Outbound internet access (to download exporter binaries during install)
- Firewall allows Monitoring Server to reach ports `9100` and `9187`

---

## 2. Monitoring Server Setup

### Install Docker

```bash
# Ubuntu
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
```

### Clone the Repository

```bash
git clone https://github.com/<your-username>/postgres-monitor.git
cd postgres-monitor
```

### Configure Environment Variables

```bash
cp .env.example .env
nano .env   # Or use your preferred editor
```

Set all required variables (see `.env.example` for descriptions).

---

## 3. DB Server Setup

### Create the Prometheus PostgreSQL User

Connect to PostgreSQL as superuser and run:

```sql
CREATE USER prometheus WITH PASSWORD 'prometheus';
GRANT pg_monitor TO prometheus;
```

> **Note:** Use a stronger password in production and update the `DATA_SOURCE_NAME` in the exporter service accordingly.

### Install Exporters

Transfer the install script to the DB server and execute:

```bash
# From monitoring server:
scp exporters/install-exporters.sh user@DB_SERVER_IP:/tmp/

# On DB server:
sudo bash /tmp/install-exporters.sh
```

### Open Firewall Ports (if applicable)

```bash
# Allow Monitoring Server to scrape exporters
sudo ufw allow from MONITOR_SERVER_IP to any port 9100
sudo ufw allow from MONITOR_SERVER_IP to any port 9187
```

---

## 4. Configuring Prometheus

Edit `config/prometheus.yml` and replace the placeholder IP:

```yaml
- job_name: "node_exporter"
  static_configs:
    - targets: ["YOUR_DB_SERVER_IP:9100"]

- job_name: "postgres_exporter"
  static_configs:
    - targets: ["YOUR_DB_SERVER_IP:9187"]
```

Alert rules are pre-configured in `config/alert.rules.yml`. See [docs/ALERTS.md](ALERTS.md) for tuning.

---

## 5. Configuring Alertmanager

Edit `config/alertmanager.yml`:

```yaml
global:
  smtp_from: 'you@gmail.com'
  smtp_auth_username: 'you@gmail.com'
  smtp_auth_password: 'YOUR_GMAIL_APP_PASSWORD'

receivers:
  - name: "email-alert"
    email_configs:
      - to: "alerts@yourcompany.com"
```

> Use a [Gmail App Password](https://myaccount.google.com/apppasswords), not your Google account password.

---

## 6. Configuring Grafana

The Grafana datasource and dashboard provider are pre-configured via provisioning files:

- `grafana/provisioning/datasources/prometheus.yml` — Auto-adds Prometheus datasource
- `grafana/provisioning/dashboards/dashboards.yml` — Auto-loads JSON dashboards

**Set the admin password** in `docker-compose.yml` or via `.env`:

```bash
GF_SECURITY_ADMIN_PASSWORD=your_strong_password
```

---

## 7. Starting the Stack

Run the validation script first:

```bash
bash scripts/validate-setup.sh
```

Then start all services:

```bash
docker compose up -d
```

Check that all containers started successfully:

```bash
docker compose ps
```

All services should show `Up (healthy)` after ~30 seconds.

---

## 8. Post-setup Verification

```bash
# Run the health check script
bash scripts/health-check.sh YOUR_DB_SERVER_IP
```

Manual checks:

| Check | URL |
|-------|-----|
| Prometheus targets | `http://MONITOR_IP:9090/targets` |
| Prometheus alerts | `http://MONITOR_IP:9090/alerts` |
| Alertmanager | `http://MONITOR_IP:9093` |
| Grafana | `http://MONITOR_IP:3000` |

### Import Grafana Dashboards

In Grafana → **Dashboards → Import** → enter these IDs:

| Dashboard | ID |
|-----------|----|
| Node Exporter Full | 1860 |
| PostgreSQL Overview | 9628 |
| Prometheus Stats | 3662 |

See [grafana-dashboards.md](grafana-dashboards.md) for details.

---

## Common Commands

```bash
# Start the stack
docker compose up -d

# Stop the stack
docker compose down

# View logs
docker compose logs -f prometheus
docker compose logs -f alertmanager
docker compose logs -f grafana

# Reload Prometheus config (no restart needed)
curl -X POST http://localhost:9090/-/reload
```

---

For troubleshooting, see [../TROUBLESHOOTING.md](../TROUBLESHOOTING.md).
