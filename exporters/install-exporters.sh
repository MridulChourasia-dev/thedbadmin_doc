#!/bin/bash
# ============================================================
# Install node_exporter + postgres_exporter on the DB server
# Run this script ON the PostgreSQL server (192.168.1.125)
# Usage: sudo bash exporters/install-exporters.sh
# ============================================================

set -e

NODE_EXPORTER_VERSION="1.8.1"
PG_EXPORTER_VERSION="0.15.0"

echo "=============================="
echo " Installing Node Exporter"
echo "=============================="

useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true

cd /tmp
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now node_exporter
echo "node_exporter running on :9100"

echo ""
echo "=============================="
echo " Installing Postgres Exporter"
echo "=============================="

useradd --no-create-home --shell /bin/false postgres_exporter 2>/dev/null || true

cd /tmp
wget -q "https://github.com/prometheus-community/postgres_exporter/releases/download/v${PG_EXPORTER_VERSION}/postgres_exporter-${PG_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xzf "postgres_exporter-${PG_EXPORTER_VERSION}.linux-amd64.tar.gz"
cp "postgres_exporter-${PG_EXPORTER_VERSION}.linux-amd64/postgres_exporter" /usr/local/bin/
chown postgres_exporter:postgres_exporter /usr/local/bin/postgres_exporter

# NOTE: Create this role in PostgreSQL first:
#   CREATE USER prometheus WITH PASSWORD 'prometheus';
#   GRANT pg_monitor TO prometheus;
cat > /etc/systemd/system/postgres_exporter.service <<EOF
[Unit]
Description=Postgres Exporter
After=network.target postgresql.service

[Service]
User=postgres_exporter
Environment="DATA_SOURCE_NAME=postgresql://prometheus:prometheus@localhost:5432/postgres?sslmode=disable"
ExecStart=/usr/local/bin/postgres_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now postgres_exporter
echo "postgres_exporter running on :9187"

echo ""
echo "=============================="
echo " Done! Verify:"
echo "  curl http://localhost:9100/metrics | head -5"
echo "  curl http://localhost:9187/metrics | head -5"
echo "=============================="
