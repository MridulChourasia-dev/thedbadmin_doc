#!/bin/bash
# ============================================================
# validate-setup.sh — Pre-flight validation for the monitoring stack
#
# Usage:  bash scripts/validate-setup.sh
# Run this BEFORE starting docker compose to catch common
# configuration mistakes early.
# ============================================================

set -euo pipefail

# Colour helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

PASS=0
FAIL=0

pass() { echo -e "${GREEN}  [PASS]${NC} $1"; ((PASS++)); }
fail() { echo -e "${RED}  [FAIL]${NC} $1"; ((FAIL++)); }
warn() { echo -e "${YELLOW}  [WARN]${NC} $1"; }
section() { echo -e "\n=== $1 ==="; }

# ---- 1. Required tools ----
section "Checking required tools"

for cmd in docker curl; do
  if command -v "$cmd" &>/dev/null; then
    pass "$cmd is installed"
  else
    fail "$cmd is NOT installed — install it before continuing"
  fi
done

# docker compose v2 check
if docker compose version &>/dev/null; then
  pass "docker compose (v2) is available"
elif docker-compose version &>/dev/null; then
  warn "docker-compose (v1) found — consider upgrading to Docker Compose v2"
else
  fail "Neither 'docker compose' nor 'docker-compose' found"
fi

# ---- 2. .env file ----
section "Checking .env file"

if [[ -f .env ]]; then
  pass ".env file exists"
else
  fail ".env file is missing — run: cp .env.example .env and fill in your values"
fi

# ---- 3. Required config files ----
section "Checking config files"

for f in \
  docker-compose.yml \
  config/prometheus.yml \
  config/alert.rules.yml \
  config/alertmanager.yml \
  grafana/provisioning/datasources/prometheus.yml \
  grafana/provisioning/dashboards/dashboards.yml; do
  if [[ -f "$f" ]]; then
    pass "$f exists"
  else
    fail "$f is MISSING"
  fi
done

# ---- 4. Placeholder IP check ----
section "Checking for unconfigured placeholder values"

if grep -q "192.168.1.125" config/prometheus.yml 2>/dev/null; then
  warn "config/prometheus.yml still contains the placeholder IP 192.168.1.125 — update it to your DB server IP"
else
  pass "No placeholder IP found in prometheus.yml"
fi

if grep -q "YOUR_GMAIL_APP_PASSWORD" config/alertmanager.yml 2>/dev/null; then
  warn "config/alertmanager.yml still contains YOUR_GMAIL_APP_PASSWORD — set your real Gmail App Password"
fi

if [[ -f .env ]] && grep -q "your_gmail_app_password_here" .env 2>/dev/null; then
  warn ".env still contains the placeholder Gmail App Password"
fi

if [[ -f .env ]] && grep -q "changeme_strong_password" .env 2>/dev/null; then
  warn ".env still contains the default Grafana password 'changeme_strong_password' — change it"
fi

# ---- 5. Docker daemon ----
section "Checking Docker daemon"

if docker info &>/dev/null; then
  pass "Docker daemon is running"
else
  fail "Docker daemon is NOT running — start Docker and retry"
fi

# ---- 6. Port availability ----
section "Checking port availability (9090, 9093, 3000)"

for port in 9090 9093 3000; do
  if ss -tlnp 2>/dev/null | grep -q ":${port} " || \
     netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
    warn "Port $port appears to be in use — check for conflicts"
  else
    pass "Port $port is available"
  fi
done

# ---- Summary ----
echo ""
echo "============================================"
echo " Validation complete: ${PASS} passed, ${FAIL} failed"
echo "============================================"

if [[ $FAIL -gt 0 ]]; then
  echo -e "${RED}Fix the failed checks before running 'docker compose up -d'.${NC}"
  exit 1
else
  echo -e "${GREEN}All checks passed — you're good to go!${NC}"
  echo "  Run:  docker compose up -d"
fi
