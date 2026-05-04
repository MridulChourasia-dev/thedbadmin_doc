# 🔐 Security Best Practices

Recommendations for hardening the PostgreSQL Monitoring Stack in production environments.

---

## Secrets Management

### Never commit `.env` to Git

The `.env` file contains sensitive credentials (passwords, SMTP keys). It is excluded from git via `.gitignore`. Always verify before pushing:

```bash
git status   # .env should NOT appear in staged files
```

### Use strong passwords

- **Grafana admin password:** Set a strong password in `.env` (`GF_SECURITY_ADMIN_PASSWORD`). Never use the default `admin/admin` in production.
- **PostgreSQL monitoring user:** Use a strong, unique password for the `prometheus` PostgreSQL user.
- **Gmail App Password:** Never use your Google account password — always use a [Gmail App Password](https://myaccount.google.com/apppasswords).

---

## Network Security

### Restrict access to monitoring ports

Ports `9090` (Prometheus), `9093` (Alertmanager), and `3000` (Grafana) should **not** be publicly accessible.

**Firewall recommendations (UFW):**
```bash
# Allow access only from trusted IPs (e.g., your office/VPN IP)
sudo ufw allow from YOUR_ADMIN_IP to any port 9090
sudo ufw allow from YOUR_ADMIN_IP to any port 9093
sudo ufw allow from YOUR_ADMIN_IP to any port 3000

# Deny all others
sudo ufw deny 9090
sudo ufw deny 9093
sudo ufw deny 3000
```

### Restrict exporter ports on the DB server

Ports `9100` and `9187` should only be reachable from the Monitoring Server:

```bash
sudo ufw allow from MONITOR_SERVER_IP to any port 9100
sudo ufw allow from MONITOR_SERVER_IP to any port 9187
sudo ufw deny 9100
sudo ufw deny 9187
```

### Consider a VPN

For the highest security, run all monitoring traffic over a VPN (WireGuard, OpenVPN) rather than exposing any ports directly.

---

## Grafana

- Disable user sign-ups (already set in `docker-compose.yml`: `GF_USERS_ALLOW_SIGN_UP=false`).
- Use Grafana's built-in role-based access control (RBAC) to limit who can edit dashboards.
- Enable HTTPS by placing Grafana behind a reverse proxy (nginx, Caddy) with TLS.

---

## Prometheus & Alertmanager

- Prometheus and Alertmanager have no built-in authentication. Use a reverse proxy with basic auth or mTLS if they must be accessible beyond localhost.
- Limit `--web.enable-lifecycle` usage — this API allows configuration reloads and should not be publicly accessible.

---

## PostgreSQL

- Grant only the minimum required privileges to the `prometheus` user:
  ```sql
  GRANT pg_monitor TO prometheus;
  -- Do NOT grant superuser or write privileges
  ```
- Use `sslmode=require` in the `DATA_SOURCE_NAME` if PostgreSQL is configured for SSL:
  ```
  postgresql://prometheus:password@localhost:5432/postgres?sslmode=require
  ```

---

## Docker

- Keep Docker and images up to date to receive security patches.
- Use specific image tags (e.g., `prom/prometheus:v2.51.0`) instead of `latest` in production to avoid unintended upgrades.
- Run containers as non-root (already the case for Prometheus and Alertmanager official images).

---

## Audit & Monitoring

- Review Alertmanager logs periodically for authentication failures.
- Set up a separate alert for the monitoring stack itself (e.g., alert if Prometheus stops scraping itself).
- Rotate Gmail App Passwords periodically and update `config/alertmanager.yml`.
