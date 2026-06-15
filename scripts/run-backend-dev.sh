#!/usr/bin/env bash
# Arranca backend :3000 (o avisa si ya está activo — sin EADDRINUSE).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

"$ROOT/scripts/_bootstrap-web-tunnel.sh"

if lsof -iTCP:3000 -sTCP:LISTEN -P -n >/dev/null 2>&1; then
  PID=$(lsof -tiTCP:3000 -sTCP:LISTEN 2>/dev/null | head -1 || true)
  if curl -sf --connect-timeout 2 http://127.0.0.1:3000/health >/dev/null 2>&1; then
    echo ""
    echo "→ Backend API ya está activo en :3000 (PID ${PID:-?})."
    echo "  No hace falta otro \`pnpm run dev\` en esta terminal."
    echo "  Reinicio limpio: ./scripts/stop-dev-ports.sh && cd backend && pnpm run dev"
    echo ""
    exit 0
  fi
  echo ""
  echo "✗ Puerto :3000 ocupado (PID ${PID:-?}) pero la API no responde."
  echo "  Libera el puerto: ./scripts/stop-dev-ports.sh"
  echo ""
  exit 1
fi

cd "$ROOT/backend"
exec pnpm exec ts-node-dev --respawn --transpile-only src/index.ts
