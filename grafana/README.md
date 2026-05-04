# Grafana Configuration

This directory contains Grafana-related files for the monitoring stack.

---

## Directory Structure

```
grafana/
├── dashboards/          # Place custom dashboard JSON files here
│   └── .gitkeep         # Keeps directory tracked in git (replace with .json files)
└── provisioning/        # Auto-provisioning configs loaded by Grafana on startup
    ├── datasources/
    │   ├── README.md
    │   └── prometheus.yml   # Automatically adds Prometheus as a datasource
    └── dashboards/
        ├── README.md
        └── dashboards.yml   # Tells Grafana where to load dashboard JSON files from
```

---

## Dashboards

### Auto-provisioned dashboards

Any `.json` file placed in `grafana/dashboards/` is automatically loaded by Grafana on startup (or within 30 seconds via the polling interval configured in `provisioning/dashboards/dashboards.yml`).

### Importing community dashboards

You can also import dashboards directly from Grafana UI:

1. Open Grafana → **Dashboards → Import**
2. Enter one of these community dashboard IDs:

| Dashboard             | ID   | Purpose                           |
|-----------------------|------|-----------------------------------|
| Node Exporter Full    | 1860 | CPU / Memory / Disk / Network     |
| PostgreSQL Overview   | 9628 | Connections, locks, queries       |
| Prometheus Stats      | 3662 | Prometheus self-monitoring        |

See [docs/grafana-dashboards.md](../docs/grafana-dashboards.md) for more details.

---

## Default Login

| Username | Password |
|----------|----------|
| `admin`  | `admin`  |

> ⚠️ Change the default password on first login or set `GF_SECURITY_ADMIN_PASSWORD` in your `.env` file.

---

## Accessing Grafana

After starting the stack with `docker compose up -d`:

```
http://MONITOR_SERVER_IP:3000
```
