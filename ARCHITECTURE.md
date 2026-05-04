# 🏗️ Architecture Overview

This document describes the system design of the PostgreSQL Monitoring Stack.

---

## Component Diagram

```
┌─────────────────────────────────────┐     ┌──────────────────────────┐
│          Monitoring Server          │     │       DB Server           │
│                                     │     │   (192.168.1.125)        │
│  ┌───────────┐    ┌──────────────┐  │     │                          │
│  │ Grafana   │    │ Alertmanager │  │     │  ┌─────────────────┐    │
│  │ :3000     │    │ :9093        │◄─┼─────┼──│ node_exporter   │    │
│  └─────┬─────┘    └──────▲───────┘  │     │  │ :9100           │    │
│        │                 │          │     │  ├─────────────────┤    │
│  ┌─────▼─────────────────┴───────┐  │     │  │postgres_exporter│    │
│  │       Prometheus  :9090       │◄─┼─────┼──│ :9187           │    │
│  └───────────────────────────────┘  │     │  └─────────────────┘    │
└─────────────────────────────────────┘     └──────────────────────────┘
```

---

## Data Flow

1. **Exporters** (on DB Server) expose metrics over HTTP on their respective ports.
2. **Prometheus** (on Monitoring Server) scrapes those endpoints every 5 seconds and stores time-series data.
3. **Prometheus** evaluates alert rules defined in `config/alert.rules.yml`.
4. When an alert fires, **Prometheus** forwards it to **Alertmanager**.
5. **Alertmanager** deduplicates, groups, and routes the alert to the configured receiver (email via Gmail SMTP).
6. **Grafana** queries Prometheus for historical and real-time metrics to render dashboards.

---

## Services

| Service             | Port | Image                        | Purpose                               |
|---------------------|------|------------------------------|---------------------------------------|
| Prometheus          | 9090 | `prom/prometheus:latest`     | Metrics collection & alert evaluation |
| Alertmanager        | 9093 | `prom/alertmanager:latest`   | Alert routing → email                 |
| Grafana             | 3000 | `grafana/grafana:latest`     | Visualization dashboards              |
| node_exporter       | 9100 | Binary on DB server          | CPU / RAM / Disk metrics              |
| postgres_exporter   | 9187 | Binary on DB server          | PostgreSQL-specific metrics           |

---

## Network Layout

All Docker services (`prometheus`, `alertmanager`, `grafana`) communicate over a private Docker bridge network named `monitoring`. Services are referenced by their container names (e.g., `prometheus:9090`) rather than by IP address.

The exporters run as systemd services directly on the DB server and are **not** inside Docker. Prometheus reaches them via the DB server's IP address.

---

## Persistent Volumes

| Volume              | Mounted Into               | Purpose                          |
|---------------------|----------------------------|----------------------------------|
| `prometheus_data`   | `/prometheus`              | Prometheus TSDB (15-day retention)|
| `grafana_data`      | `/var/lib/grafana`         | Grafana database & settings      |
| `alertmanager_data` | `/alertmanager`            | Alertmanager state & silences    |

---

## Configuration Files

| File                               | Service       | Description                          |
|------------------------------------|---------------|--------------------------------------|
| `config/prometheus.yml`            | Prometheus    | Scrape targets & alerting endpoint   |
| `config/alert.rules.yml`           | Prometheus    | Alert rule definitions               |
| `config/alertmanager.yml`          | Alertmanager  | Email routing & SMTP settings        |
| `grafana/provisioning/datasources/prometheus.yml` | Grafana | Auto-adds Prometheus datasource |
| `grafana/provisioning/dashboards/dashboards.yml`  | Grafana | Auto-loads JSON dashboards      |

---

## Security Boundaries

- `.env` holds all secrets (passwords, IPs) and is excluded from git via `.gitignore`.
- Grafana and Prometheus ports should **not** be exposed publicly — use a VPN or firewall rules.
- See [docs/SECURITY.md](docs/SECURITY.md) for detailed recommendations.
