#!/usr/bin/env bash
# Arranca gateway :3001 en modo debug (9231).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

"$ROOT/scripts/_bootstrap-dev-env.sh"

if lsof -iTCP:3001 -sTCP:LISTEN -P -n >/dev/null 2>&1; then
  PID=$(lsof -tiTCP:3001 -sTCP:LISTEN 2>/dev/null | head -1 || true)
  if curl -sf --connect-timeout 2 http://127.0.0.1:3001/health >/dev/null 2>&1; then
    echo "→ Gateway ya activo en :3001 (PID ${PID:-?})."
    exit 0
  fi
  echo "✗ Puerto :3001 ocupado sin health. ./scripts/stop-dev-ports.sh"
  exit 1
fi

cd "$ROOT/realtime-gateway"
exec pnpm exec ts-node-dev --inspect=9231 --transpile-only --no-notify src/index.ts
