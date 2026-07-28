#!/usr/bin/env bash
# Install fm-anvil-agent as a systemd service. Idempotent; run on the rig:
#   sudo bash ~/anvil-loader/agent/install.sh
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  printf '%s\n' "This installer needs root. Re-running with sudo..."
  exec sudo "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UNIT_SRC="${SCRIPT_DIR}/fm-anvil-agent.service"
UNIT_DST="/etc/systemd/system/fm-anvil-agent.service"

install -m 0644 "${UNIT_SRC}" "${UNIT_DST}"
systemctl daemon-reload
systemctl enable --now fm-anvil-agent.service
sleep 1
systemctl --no-pager --lines=5 status fm-anvil-agent.service || true

if curl -sf --max-time 3 http://localhost:8770/health >/dev/null; then
  printf '%s\n' "fm-anvil-agent is up on :8770."
else
  printf '%s\n' "Warning: agent did not answer on :8770 yet; check journalctl -u fm-anvil-agent."
  exit 1
fi
