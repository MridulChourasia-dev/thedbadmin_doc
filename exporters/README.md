# Exporters

This directory contains the installation script for the Prometheus exporters that run on the **PostgreSQL / DB server**.

---

## What are exporters?

Exporters are small HTTP servers that expose metrics in Prometheus format.  
Two exporters are used in this stack:

| Exporter            | Port | Metrics                                    |
|---------------------|------|--------------------------------------------|
| `node_exporter`     | 9100 | CPU, RAM, disk, network, load average      |
| `postgres_exporter` | 9187 | Connections, locks, transactions, pg_up    |

Both exporters run as **systemd services** directly on the DB server (not in Docker).

---

## Prerequisites

Before running the installer, create the monitoring role in PostgreSQL:

```sql
-- Run as superuser (e.g., postgres):
CREATE USER prometheus WITH PASSWORD 'prometheus';
GRANT pg_monitor TO prometheus;
```

---

## Installation

Run this script **on the PostgreSQL / DB server** (requires `sudo`):

```bash
sudo bash exporters/install-exporters.sh
```

The script will:
1. Download `node_exporter` and `postgres_exporter` binaries from GitHub Releases.
2. Create dedicated system users for each exporter.
3. Install systemd unit files and start both services.

---

## Verify Installation

After running the script:

```bash
# Check services are running
systemctl status node_exporter
systemctl status postgres_exporter

# Test metric endpoints
curl http://localhost:9100/metrics | head -10
curl http://localhost:9187/metrics | head -10
```

---

## Upgrading

To upgrade to a newer version, edit the version variables at the top of `install-exporters.sh`:

```bash
NODE_EXPORTER_VERSION="1.8.1"   # Update to desired version
PG_EXPORTER_VERSION="0.15.0"    # Update to desired version
```

Then re-run the installer.

---

## Uninstalling

```bash
sudo systemctl stop node_exporter postgres_exporter
sudo systemctl disable node_exporter postgres_exporter
sudo rm /etc/systemd/system/node_exporter.service \
        /etc/systemd/system/postgres_exporter.service \
        /usr/local/bin/node_exporter \
        /usr/local/bin/postgres_exporter
sudo userdel node_exporter
sudo userdel postgres_exporter
sudo systemctl daemon-reload
```
