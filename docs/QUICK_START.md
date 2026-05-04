# ⚡ Quick Start

Get the PostgreSQL monitoring stack running in 5 minutes.

---

## Prerequisites

- A **monitoring server** with Docker installed
- A **DB server** running PostgreSQL (can be the same machine)
- Outbound internet access (to pull Docker images and download exporter binaries)

---

## Step 1 — Clone the repository

```bash
git clone https://github.com/<your-username>/postgres-monitor.git
cd postgres-monitor
```

---

## Step 2 — Configure your environment

```bash
cp .env.example .env
```

Open `.env` and set:

```bash
GF_SECURITY_ADMIN_PASSWORD=your_strong_password
SMTP_FROM=you@gmail.com
SMTP_AUTH_USERNAME=you@gmail.com
SMTP_AUTH_PASSWORD=your_gmail_app_password   # see https://myaccount.google.com/apppasswords
ALERT_EMAIL_TO=alerts@yourcompany.com
DB_SERVER_IP=192.168.1.125                   # your DB server's IP
```

---

## Step 3 — Set your DB server IP

```bash
# Replace the placeholder IP in Prometheus config
sed -i 's/192.168.1.125/YOUR_DB_IP/g' config/prometheus.yml
```

Or edit `config/prometheus.yml` manually.

---

## Step 4 — Prepare PostgreSQL on the DB server

```sql
-- Run as superuser on the DB server:
CREATE USER prometheus WITH PASSWORD 'prometheus';
GRANT pg_monitor TO prometheus;
```

---

## Step 5 — Install exporters on the DB server

Copy `exporters/install-exporters.sh` to the DB server and run:

```bash
sudo bash install-exporters.sh
```

---

## Step 6 — Validate your setup

```bash
bash scripts/validate-setup.sh
```

Fix any reported issues before continuing.

---

## Step 7 — Start the stack

```bash
docker compose up -d
```

---

## Step 8 — Verify

| URL | Expected result |
|-----|-----------------|
| `http://MONITOR_IP:9090/targets` | All targets **UP** |
| `http://MONITOR_IP:9090/alerts` | Alert rules loaded |
| `http://MONITOR_IP:9093` | Alertmanager UI |
| `http://MONITOR_IP:3000` | Grafana login page |

Run the health check script:

```bash
bash scripts/health-check.sh YOUR_DB_IP
```

---

## Next Steps

- [Detailed setup guide](SETUP.md)
- [Import Grafana dashboards](grafana-dashboards.md)
- [Configure alerts](ALERTS.md)
- [Security hardening](SECURITY.md)
