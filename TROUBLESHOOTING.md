# 🔧 Troubleshooting Guide

Common problems and their solutions for the PostgreSQL Monitoring Stack.

---

## Table of Contents

- [Prometheus targets showing DOWN](#prometheus-targets-showing-down)
- [No alerts received](#no-alerts-received)
- [Grafana shows "No data"](#grafana-shows-no-data)
- [Docker services fail to start](#docker-services-fail-to-start)
- [Exporters not running](#exporters-not-running)
- [Permission errors](#permission-errors)

---

## Prometheus targets showing DOWN

**Symptoms:** `http://MONITOR_SERVER:9090/targets` shows `node_exporter` or `postgres_exporter` as `DOWN`.

**Possible causes and fixes:**

1. **Exporter service not running on DB server**
   ```bash
   # On the DB server:
   systemctl status node_exporter
   systemctl status postgres_exporter
   # If stopped:
   sudo systemctl start node_exporter
   sudo systemctl start postgres_exporter
   ```

2. **Firewall blocking ports 9100 / 9187**
   ```bash
   # On the DB server, allow Prometheus to reach exporters:
   sudo ufw allow from <MONITOR_SERVER_IP> to any port 9100
   sudo ufw allow from <MONITOR_SERVER_IP> to any port 9187
   ```

3. **Wrong DB server IP in `config/prometheus.yml`**
   - Edit `config/prometheus.yml` and ensure targets match your actual DB server IP.
   - Reload Prometheus: `curl -X POST http://localhost:9090/-/reload`

---

## No alerts received

**Symptoms:** Alerts fire in Prometheus but no emails arrive.

**Steps to diagnose:**

1. Check Alertmanager received the alert:
   ```
   http://MONITOR_SERVER:9093
   ```
   The Alertmanager UI shows active and silenced alerts.

2. Verify SMTP credentials in `config/alertmanager.yml`:
   - Use a **Gmail App Password**, not your Google account password.
   - Generate one at: https://myaccount.google.com/apppasswords

3. Check Alertmanager logs:
   ```bash
   docker compose logs alertmanager
   ```
   Look for SMTP authentication errors.

4. Test SMTP connectivity from the monitoring server:
   ```bash
   curl --url 'smtps://smtp.gmail.com:465' \
     --ssl-reqd \
     --mail-from 'sender@gmail.com' \
     --mail-rcpt 'recipient@gmail.com' \
     --upload-file /dev/null \
     -u 'sender@gmail.com:APP_PASSWORD'
   ```

---

## Grafana shows "No data"

**Symptoms:** Grafana panels display "No data" or query errors.

**Steps to diagnose:**

1. **Check Prometheus datasource** in Grafana → Configuration → Data Sources → Prometheus
   - URL should be `http://prometheus:9090`
   - Click **Save & Test** — should show "Data source is working"

2. **Check Prometheus is scraping correctly**
   ```
   http://MONITOR_SERVER:9090/graph
   ```
   Try a query like `up` — you should see `1` for healthy targets.

3. **Wrong dashboard time range** — Ensure the dashboard time picker is not set to a future or very old range.

4. **Re-provision datasource** if auto-provisioning failed:
   ```bash
   docker compose restart grafana
   ```

---

## Docker services fail to start

**Symptoms:** `docker compose up -d` errors out.

**Common causes:**

1. **Port already in use**
   ```bash
   sudo ss -tlnp | grep -E '9090|9093|3000'
   # Kill conflicting process or change port in docker-compose.yml
   ```

2. **Config file not found / syntax error**
   ```bash
   docker compose config    # Validate docker-compose.yml
   ```

3. **Old containers with conflicting names**
   ```bash
   docker rm -f prometheus alertmanager grafana
   docker compose up -d
   ```

4. **Insufficient disk space**
   ```bash
   df -h
   docker system prune -f   # Clean up unused images/volumes
   ```

---

## Exporters not running

**Symptoms:** `systemctl status node_exporter` or `systemctl status postgres_exporter` shows failed.

**Steps:**

1. View full logs:
   ```bash
   journalctl -u node_exporter -n 50
   journalctl -u postgres_exporter -n 50
   ```

2. For `postgres_exporter`, ensure the monitoring user exists in PostgreSQL:
   ```sql
   -- Run in psql as superuser:
   CREATE USER prometheus WITH PASSWORD 'prometheus';
   GRANT pg_monitor TO prometheus;
   ```

3. Verify the `DATA_SOURCE_NAME` in the service file:
   ```bash
   cat /etc/systemd/system/postgres_exporter.service
   ```
   It should match your PostgreSQL credentials.

4. Re-run the installer:
   ```bash
   sudo bash exporters/install-exporters.sh
   ```

---

## Permission errors

**Symptoms:** `chown: invalid user`, `Permission denied`, or `sudo: command not found`.

**Fixes:**

- Run the installer with `sudo`: `sudo bash exporters/install-exporters.sh`
- Ensure `wget` and `tar` are installed: `sudo apt-get install wget tar`
- Ensure `/usr/local/bin` is writable: `ls -la /usr/local/bin`

---

## Still stuck?

Open an issue using the [Bug Report template](.github/ISSUE_TEMPLATE/BUG_REPORT.md) and include:
- The output of `docker compose logs`
- The output of `systemctl status node_exporter postgres_exporter`
- Your operating system and Docker version
