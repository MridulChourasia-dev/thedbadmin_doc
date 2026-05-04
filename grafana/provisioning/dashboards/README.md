# Grafana Dashboards Provisioning

This directory contains the dashboard provider configuration that Grafana uses to auto-load dashboard JSON files.

## Files

| File              | Description                                              |
|-------------------|----------------------------------------------------------|
| `dashboards.yml`  | Configures the file-based dashboard provider             |

## How it works

`dashboards.yml` tells Grafana to watch the `/var/lib/grafana/dashboards` directory (mapped from `grafana/dashboards/` in this repo) and load any `.json` files found there.

Grafana polls for changes every **30 seconds**, so new or updated dashboard files are picked up automatically without restarting the container.

## Adding a custom dashboard

1. Export your dashboard from Grafana: **Dashboard Settings → JSON Model → Copy to clipboard**
2. Save the JSON to `grafana/dashboards/my-dashboard.json`
3. Wait up to 30 seconds for Grafana to auto-load it, or restart Grafana:
   ```bash
   docker compose restart grafana
   ```
