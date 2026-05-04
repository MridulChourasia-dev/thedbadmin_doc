# Grafana Dashboard Setup

## Importing Community Dashboards

In Grafana → Click **+** → **Import Dashboard** → Enter the ID below.

| Dashboard | Import ID | What it shows |
|-----------|-----------|---------------|
| Node Exporter Full | `1860` | CPU, RAM, Disk, Network per host |
| PostgreSQL Overview | `9628` | Active connections, locks, transactions |
| Prometheus Stats | `3662` | Prometheus performance and scrape health |

## Adding a Custom Dashboard as JSON

1. Export your dashboard from Grafana (Dashboard Settings → JSON Model)
2. Save the file to `grafana/dashboards/my-dashboard.json`
3. Restart Grafana or wait 30s for auto-reload

## Recommended Panels for PostgreSQL

- `pg_stat_activity_count` — active connections
- `pg_stat_bgwriter_buffers_alloc_total` — buffer allocation
- `pg_locks_count` — lock wait events
- `rate(pg_stat_database_tup_fetched[5m])` — rows fetched rate
- `pg_replication_lag` — replication delay (if using replicas)
