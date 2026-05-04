# 🔔 Alert Configuration Guide

This document explains the alerts configured in `config/alert.rules.yml` and how to tune or extend them.

---

## Pre-configured Alerts

| Alert Name                      | Condition                                             | Severity | Duration |
|---------------------------------|-------------------------------------------------------|----------|----------|
| `InstanceDown`                  | Any scrape target is unreachable (`up == 0`)          | critical | 1 min    |
| `HighCPUUsage`                  | CPU usage > 80%                                       | warning  | 2 min    |
| `HighMemoryUsage`               | Available RAM < 10%                                   | warning  | 2 min    |
| `DiskSpaceLow`                  | Disk usage > 85% (non-tmpfs mounts)                   | warning  | 5 min    |
| `PostgreSQLDown`                | `pg_up == 0` (postgres_exporter cannot connect)       | critical | 1 min    |
| `PostgreSQLTooManyConnections`  | Active connections > 80% of `max_connections`         | warning  | 2 min    |

---

## How Alerts Work

1. Prometheus evaluates each rule at the `scrape_interval` (default: 5s).
2. An alert transitions from **inactive → pending** when its condition is first true.
3. After the `for` duration, the alert transitions to **firing**.
4. Prometheus sends the firing alert to Alertmanager.
5. Alertmanager groups, deduplicates, and emails the configured recipient.
6. When the condition resolves, a **resolved** email is sent (`send_resolved: true`).

---

## Tuning Alert Thresholds

Edit `config/alert.rules.yml` to adjust thresholds for your environment:

```yaml
# Example: lower CPU threshold to 60% for a sensitive workload
- alert: HighCPUUsage
  expr: 100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100) > 60
  for: 2m
```

After editing, reload Prometheus without restarting:
```bash
curl -X POST http://localhost:9090/-/reload
```

---

## Adding New Alerts

Add new rule blocks to `config/alert.rules.yml`:

```yaml
# Example: Alert if PostgreSQL replication lag exceeds 30 seconds
- alert: PostgreSQLHighReplicationLag
  expr: pg_replication_lag > 30
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High replication lag on {{ $labels.instance }}"
    description: "Replication lag is {{ $value | printf \"%.0f\" }}s on {{ $labels.instance }}"
```

---

## Silencing Alerts

To temporarily silence an alert (e.g., during maintenance):

1. Open Alertmanager: `http://MONITOR_IP:9093`
2. Click **Silences → New Silence**
3. Set matchers (e.g., `alertname="HighCPUUsage"`) and duration
4. Click **Create**

---

## Testing Alerts

You can trigger a test alert manually using the Alertmanager API:

```bash
curl -X POST http://localhost:9093/api/v2/alerts \
  -H 'Content-Type: application/json' \
  -d '[{
    "labels": {"alertname": "TestAlert", "severity": "warning"},
    "annotations": {"summary": "This is a test alert"},
    "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }]'
```

Check your inbox within a minute for the test email.

---

## Alert Routing Configuration

Routing is configured in `config/alertmanager.yml`:

| Parameter        | Default | Description                                          |
|------------------|---------|------------------------------------------------------|
| `group_wait`     | 30s     | Wait before sending the first notification in a group |
| `group_interval` | 5m      | Wait before sending new alerts for an existing group  |
| `repeat_interval`| 4h      | Resend alert if it's still firing after this interval |

Adjust these to control notification frequency and grouping behaviour.
