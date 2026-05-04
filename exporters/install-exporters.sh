#!/bin/bash
# ============================================================
# install-exporters.sh
#
# Installs node_exporter and postgres_exporter on the DB server
# as systemd services.
#
# Run this script ON the PostgreSQL server:
#   sudo bash exporters/install-exporters.sh
#
# Prerequisites:
#   - Run as root / with sudo
#   - wget and tar must be installed
#   - PostgreSQL monitoring user must exist:
#       CREATE USER prometheus WITH PASSWORD 'prometheus';
#       GRANT pg_monitor TO prometheus;
# ============================================================

# Exit immediately on any error; treat unset variables as errors
set -euo pipefail

# ---- Version pinning ----
# Update these values to install newer releases.
NODE_EXPORTER_VERSION="1.8.1"
PG_EXPORTER_VERSION="0.15.0"

# ---- Ensure the script is run as root ----
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root. Use: sudo bash $0" >&2
  exit 1
fi

# ---- Helper: check required tools ----
for cmd in wget tar systemctl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: Required command '$cmd' is not installed." >&2
    exit 1
  fi
done

# ============================================================
# Part 1 — node_exporter
# Exposes Linux system metrics (CPU, RAM, disk, network) on :9100
# ============================================================
echo "=============================="
echo " Installing Node Exporter v${NODE_EXPORTER_VERSION}"
echo "=============================="

# Create a dedicated system user without a login shell for security
useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true

# Download and extract the binary from the official GitHub release
cd /tmp
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

# Install binary and set ownership to the dedicated user
cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Clean up downloaded files
rm -rf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64" \
       "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

# Write the systemd unit file
cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter
# Restart the service automatically if it crashes
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to pick up the new unit file, then enable and start
systemctl daemon-reload
systemctl enable --now node_exporter
echo "node_exporter installed and running on :9100"

# ============================================================
# Part 2 — postgres_exporter
# Connects to PostgreSQL and exposes DB metrics on :9187
# ============================================================
echo ""
echo "=============================="
echo " Installing Postgres Exporter v${PG_EXPORTER_VERSION}"
echo "=============================="

# IMPORTANT: The prometheus PostgreSQL user must exist before starting
# the exporter. Create it with:
#   psql -U postgres -c "CREATE USER prometheus WITH PASSWORD 'prometheus';"
#   psql -U postgres -c "GRANT pg_monitor TO prometheus;"

# Create a dedicated system user
useradd --no-create-home --shell /bin/false postgres_exporter 2>/dev/null || true

# Download and extract
cd /tmp
wget -q "https://github.com/prometheus-community/postgres_exporter/releases/download/v${PG_EXPORTER_VERSION}/postgres_exporter-${PG_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xzf "postgres_exporter-${PG_EXPORTER_VERSION}.linux-amd64.tar.gz"

# Install binary
cp "postgres_exporter-${PG_EXPORTER_VERSION}.linux-amd64/postgres_exporter" /usr/local/bin/
chown postgres_exporter:postgres_exporter /usr/local/bin/postgres_exporter

# Clean up
rm -rf "postgres_exporter-${PG_EXPORTER_VERSION}.linux-amd64" \
       "postgres_exporter-${PG_EXPORTER_VERSION}.linux-amd64.tar.gz"

# Write the systemd unit file
# DATA_SOURCE_NAME: PostgreSQL connection string for the monitoring user.
# Update the password if you used a different one when creating the role.
cat > /etc/systemd/system/postgres_exporter.service <<EOF
[Unit]
Description=Postgres Exporter
Documentation=https://github.com/prometheus-community/postgres_exporter
After=network.target postgresql.service

[Service]
User=postgres_exporter
Group=postgres_exporter
# Connection string for the prometheus PostgreSQL monitoring user
# Update the password to match what you set in PostgreSQL
Environment="DATA_SOURCE_NAME=postgresql://prometheus:prometheus@localhost:5432/postgres?sslmode=disable"
ExecStart=/usr/local/bin/postgres_exporter
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now postgres_exporter
echo "postgres_exporter installed and running on :9187"

# ============================================================
# Done — print verification commands
# ============================================================
echo ""
echo "=============================="
echo " Installation complete!"
echo ""
echo " Verify services:"
echo "   systemctl status node_exporter"
echo "   systemctl status postgres_exporter"
echo ""
echo " Test metric endpoints:"
echo "   curl http://localhost:9100/metrics | head -5"
echo "   curl http://localhost:9187/metrics | head -5"
echo "=============================="
