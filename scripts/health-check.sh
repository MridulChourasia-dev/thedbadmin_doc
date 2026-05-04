#!/bin/bash
# ============================================================
# health-check.sh — Quick health check for all monitoring services
#
# Usage:  bash scripts/health-check.sh [DB_SERVER_IP]
#
# Checks:
#   - Docker container status
#   - Prometheus health endpoint
#   - Alertmanager health endpoint
#   - Grafana health endpoint
#   - Prometheus target state (are exporters UP?)
#   - node_exporter reachability on DB server (optional)
#   - postgres_exporter reachability on DB server (optional)
# ============================================================

set -euo pipefail

# Optional: pass DB server IP as first argument, or read from .env
DB_SERVER_IP="${1:-}"
if [[ -z "$DB_SERVER_IP" ]] && [[ -f .env ]]; then
  DB_SERVER_IP="$(grep -E '^DB_SERVER_IP=' .env | cut -d= -f2)"
fi

# Colour helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}  [ OK ]${NC} $1"; }
warn() { echo -e "${YELLOW}  [WARN]${NC} $1"; }
err()  { echo -e "${RED}  [FAIL]${NC} $1"; }

section() { echo -e "\n=== $1 ==="; }

MONITOR_HOST="localhost"

# ---- 1. Docker containers ----
section "Docker container status"

for container in prometheus alertmanager grafana; do
  STATUS="$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo 'not found')"
  HEALTH="$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo 'n/a')"
  if [[ "$STATUS" == "running" ]]; then
    ok "$container — running (health: $HEALTH)"
  else
    err "$container — $STATUS"
  fi
done

# ---- 2. Service HTTP endpoints ----
section "Service HTTP health endpoints"

check_http() {
  local name="$1"
  local url="$2"
  local expected="${3:-200}"
  HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null || echo '000')"
  if [[ "$HTTP_CODE" == "$expected" ]]; then
    ok "$name → $url (HTTP $HTTP_CODE)"
  else
    err "$name → $url (HTTP $HTTP_CODE, expected $expected)"
  fi
}

check_http "Prometheus"   "http://${MONITOR_HOST}:9090/-/healthy"
check_http "Alertmanager" "http://${MONITOR_HOST}:9093/-/healthy"
check_http "Grafana"      "http://${MONITOR_HOST}:3000/api/health"

# ---- 3. Prometheus targets ----
section "Prometheus target states"

TARGETS_JSON="$(curl -s --max-time 5 "http://${MONITOR_HOST}:9090/api/v1/targets" 2>/dev/null || echo '')"
if [[ -z "$TARGETS_JSON" ]]; then
  err "Could not reach Prometheus API"
else
  # Parse active targets using grep/awk (no jq dependency)
  # Use process substitution to avoid a subshell so ok/err counters are accurate
  while read -r count state; do
    HEALTH="$(echo "$state" | sed 's/"health":"//;s/"//')"
    if [[ "$HEALTH" == "up" ]]; then
      ok "$count target(s) → $HEALTH"
    else
      err "$count target(s) → $HEALTH"
    fi
  done < <(echo "$TARGETS_JSON" | grep -o '"health":"[^"]*"' | sort | uniq -c || true)
fi

# ---- 4. Exporter reachability on DB server (optional) ----
if [[ -n "$DB_SERVER_IP" && "$DB_SERVER_IP" != "192.168.1.125" ]]; then
  section "Exporter reachability on DB server ($DB_SERVER_IP)"
  check_http "node_exporter"     "http://${DB_SERVER_IP}:9100/metrics"
  check_http "postgres_exporter" "http://${DB_SERVER_IP}:9187/metrics"
elif [[ -z "$DB_SERVER_IP" || "$DB_SERVER_IP" == "192.168.1.125" ]]; then
  section "Exporter reachability"
  warn "DB_SERVER_IP not set or still at placeholder — skipping exporter check"
  warn "Run:  bash scripts/health-check.sh <DB_SERVER_IP>"
fi

# ---- Summary ----
echo ""
echo "============================================"
echo " Health check complete"
echo " Grafana:       http://${MONITOR_HOST}:3000"
echo " Prometheus:    http://${MONITOR_HOST}:9090"
echo " Alertmanager:  http://${MONITOR_HOST}:9093"
echo "============================================"
