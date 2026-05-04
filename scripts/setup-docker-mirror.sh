#!/bin/bash
#
# Setup Docker Hub registry mirrors for Hong Kong / China VPS
#
# This script configures Docker daemon to use registry mirrors,
# which helps bypass connectivity issues to Docker Hub
# (e.g., "i/o timeout" errors when pulling images).
#
# Usage:
#   chmod +x scripts/setup-docker-mirror.sh
#   sudo ./scripts/setup-docker-mirror.sh
#
# Supported mirrors (in order of preference):
#   1. Tencent Cloud    - https://mirror.ccs.tencentyun.com   (best for HK)
#   2. USTC             - https://docker.mirrors.ustc.edu.cn
#   3. NetEase          - https://hub-mirror.c.163.com
#   4. Alibaba Cloud    - https://<your-code>.mirror.aliyuncs.com  (requires registration)
#

set -euo pipefail

DOCKER_CONFIG_DIR="/etc/docker"
DAEMON_JSON="${DOCKER_CONFIG_DIR}/daemon.json"
BACKUP_JSON="${DAEMON_JSON}.bak.$(date +%Y%m%d%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ── Check if running as root ────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)."
    exit 1
fi

# ── Ensure Docker config directory exists ───────────────────────────────────
mkdir -p "$DOCKER_CONFIG_DIR"

# ── Backup existing daemon.json if present ──────────────────────────────────
if [[ -f "$DAEMON_JSON" ]]; then
    cp "$DAEMON_JSON" "$BACKUP_JSON"
    info "Backed up existing daemon.json → ${BACKUP_JSON}"
fi

# ── Build new daemon.json with mirrors ──────────────────────────────────────
cat > "$DAEMON_JSON" << 'EOF'
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

info "Written ${DAEMON_JSON}:"
cat "$DAEMON_JSON"

# ── Restart Docker daemon ──────────────────────────────────────────────────
info "Restarting Docker daemon..."
if systemctl restart docker 2>/dev/null; then
    info "Docker daemon restarted successfully (systemctl)."
elif service docker restart 2>/dev/null; then
    info "Docker daemon restarted successfully (service)."
else
    warn "Could not restart Docker automatically. Please restart Docker manually."
fi

# ── Verify mirrors are active ───────────────────────────────────────────────
sleep 2
info "Verifying Docker info for registry mirrors..."
docker info 2>/dev/null | grep -A 5 "Registry Mirrors" || \
    warn "Could not verify registry mirrors. Check manually with: docker info"

# ── Test pulling the image ──────────────────────────────────────────────────
echo ""
info "Testing: pulling postgres:18-alpine via mirror..."
docker pull postgres:18-alpine

echo ""
info "───────────────────────────────────────────────────────────"
info "Setup complete!"
info ""
info "If the pull above succeeded, you can now run:"
info "  docker compose up -d"
info ""
info "If it still fails, try an alternative registry:"
info "  docker pull postgres:18-alpine --registry-mirror=https://docker.mirrors.ustc.edu.cn"
info "───────────────────────────────────────────────────────────"
