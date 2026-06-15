#!/usr/bin/env bash
# Arranca backend :3000 en modo debug (9230).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

"$ROOT/scripts/_bootstrap-web-tunnel.sh"

if lsof -iTCP:3000 -sTCP:LISTEN -P -n >/dev/null 2>&1; then
  PID=$(lsof -tiTCP:3000 -sTCP:LISTEN 2>/dev/null | head -1 || true)
  if curl -sf --connect-timeout 2 http://127.0.0.1:3000/health >/dev/null 2>&1; then
    echo "→ Backend API ya activo en :3000 (PID ${PID:-?})."
    exit 0
  fi
  echo "✗ Puerto :3000 ocupado sin health. ./scripts/stop-dev-ports.sh"
  exit 1
fi

cd "$ROOT/backend"
exec pnpm exec ts-node-dev --inspect=9230 --transpile-only --no-notify src/index.ts
