# 🧩 Component Descriptions

This document describes each component of the PostgreSQL Monitoring Stack.

---

## Prometheus

**Image:** `prom/prometheus:latest`  
**Port:** `9090`  
**Config:** `config/prometheus.yml`, `config/alert.rules.yml`

Prometheus is the core metrics collection and alerting engine. It periodically **scrapes** HTTP endpoints exposed by exporters, stores the metrics as time-series data, and evaluates alert rules.

Key features used in this stack:
- `scrape_interval: 5s` — fetches metrics every 5 seconds
- `--storage.tsdb.retention.time=15d` — retains 15 days of data
- `--web.enable-lifecycle` — allows hot-reloading config via API

**Useful endpoints:**
| Path | Purpose |
|------|---------|
| `/targets` | Shows scrape target health |
| `/alerts` | Shows firing and pending alerts |
| `/graph` | Ad-hoc PromQL query UI |
| `/-/reload` (POST) | Reloads configuration without restart |

---

## Alertmanager

**Image:** `prom/alertmanager:latest`  
**Port:** `9093`  
**Config:** `config/alertmanager.yml`

Alertmanager receives alerts from Prometheus and handles:
- **Deduplication** — prevents duplicate notifications for the same alert
- **Grouping** — combines related alerts into a single notification
- **Routing** — sends alerts to the correct receiver (email in this stack)
- **Silencing** — temporary muting of specific alerts

**Email routing:** Uses Gmail SMTP with App Password authentication. Configure in `config/alertmanager.yml`.

---

## Grafana

**Image:** `grafana/grafana:latest`  
**Port:** `3000`  
**Config:** `grafana/provisioning/`

Grafana is the visualization layer. It queries Prometheus for metrics and renders dashboards.

Auto-provisioning files (loaded at startup):
- `grafana/provisioning/datasources/prometheus.yml` — adds Prometheus datasource
- `grafana/provisioning/dashboards/dashboards.yml` — loads JSON dashboards from `grafana/dashboards/`

Default credentials: `admin` / `admin` — **change on first login**.

---

## node_exporter

**Port:** `9100`  
**Runs on:** DB Server (as systemd service)  
**Installed by:** `exporters/install-exporters.sh`

`node_exporter` exposes Linux system metrics in Prometheus format. Key metrics collected:

| Metric | Description |
|--------|-------------|
| `node_cpu_seconds_total` | CPU time by mode (idle, user, system, etc.) |
| `node_memory_MemAvailable_bytes` | Available RAM |
| `node_memory_MemTotal_bytes` | Total RAM |
| `node_filesystem_avail_bytes` | Available disk space per mount |
| `node_filesystem_size_bytes` | Total disk size per mount |
| `node_load1` / `node_load5` / `node_load15` | Load averages |
| `node_network_receive_bytes_total` | Network ingress |
| `node_network_transmit_bytes_total` | Network egress |

---

## postgres_exporter

**Port:** `9187`  
**Runs on:** DB Server (as systemd service)  
**Installed by:** `exporters/install-exporters.sh`

`postgres_exporter` connects to PostgreSQL and exposes database metrics.

| Metric | Description |
|--------|-------------|
| `pg_up` | `1` if PostgreSQL is reachable, `0` otherwise |
| `pg_stat_activity_count` | Active connections by state |
| `pg_settings_max_connections` | PostgreSQL `max_connections` setting |
| `pg_locks_count` | Lock counts by lock type |
| `pg_stat_database_tup_fetched` | Rows fetched per database |
| `pg_stat_bgwriter_buffers_alloc_total` | Background writer buffer allocations |

Requires a dedicated PostgreSQL monitoring user:
```sql
CREATE USER prometheus WITH PASSWORD 'prometheus';
GRANT pg_monitor TO prometheus;
```

---

## Docker Network & Volumes

All Docker services run on a private bridge network named `monitoring`.  
Services communicate by container name (e.g., `prometheus:9090`, `alertmanager:9093`).

| Volume              | Purpose                                |
|---------------------|----------------------------------------|
| `prometheus_data`   | Prometheus TSDB (time-series database) |
| `grafana_data`      | Grafana SQLite database and settings   |
| `alertmanager_data` | Alertmanager state and silences        |
