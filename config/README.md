# Configuration Files

This directory contains all configuration files for the monitoring stack services.

## Files

| File                  | Service       | Description                                  |
|-----------------------|---------------|----------------------------------------------|
| `prometheus.yml`      | Prometheus    | Scrape intervals, targets, and alerting link |
| `alert.rules.yml`     | Prometheus    | Alert rule definitions (CPU, RAM, Disk, PG)  |
| `alertmanager.yml`    | Alertmanager  | Email routing and SMTP credentials           |

## Customization

### Changing the DB server IP

Edit `prometheus.yml` and replace `192.168.1.125` with your actual DB server IP:

```yaml
- targets: ["YOUR_DB_IP:9100"]   # node_exporter
- targets: ["YOUR_DB_IP:9187"]   # postgres_exporter
```

After editing, reload Prometheus without restarting:

```bash
curl -X POST http://localhost:9090/-/reload
```

### Adjusting alert thresholds

Edit `alert.rules.yml` to tune thresholds for your environment:

- `HighCPUUsage` — default `> 80%` for 2 minutes
- `HighMemoryUsage` — default available RAM `< 10%` for 2 minutes
- `DiskSpaceLow` — default disk usage `> 85%` for 5 minutes
- `PostgreSQLTooManyConnections` — default `> 80%` of `max_connections` for 2 minutes

### Configuring email alerts

Edit `alertmanager.yml` and set:
- `smtp_from` — the Gmail address to send from
- `smtp_auth_username` — the same Gmail address
- `smtp_auth_password` — your Gmail App Password (see `.env.example`)
- `to` under `email_configs` — the recipient address

> **Tip:** Use environment variables via `.env` to avoid hardcoding credentials.
