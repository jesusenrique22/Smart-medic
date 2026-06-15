#!/usr/bin/env bash
# Arranca gateway :3001 (o avisa si ya está activo — sin EADDRINUSE).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

"$ROOT/scripts/_bootstrap-dev-env.sh"

if lsof -iTCP:3001 -sTCP:LISTEN -P -n >/dev/null 2>&1; then
  PID=$(lsof -tiTCP:3001 -sTCP:LISTEN 2>/dev/null | head -1 || true)
  if curl -sf --connect-timeout 2 http://127.0.0.1:3001/health >/dev/null 2>&1; then
    echo ""
    echo "→ Gateway ya está activo en :3001 (PID ${PID:-?})."
    echo "  No hace falta otro \`pnpm run dev\` en esta terminal."
    echo "  Reinicio limpio: ./scripts/stop-dev-ports.sh && cd realtime-gateway && pnpm run dev"
    echo ""
    exit 0
  fi
  echo ""
  echo "✗ Puerto :3001 ocupado (PID ${PID:-?}) pero el gateway no responde."
  echo "  Libera el puerto: ./scripts/stop-dev-ports.sh"
  echo ""
  exit 1
fi

cd "$ROOT/realtime-gateway"
exec pnpm exec ts-node-dev --respawn --transpile-only src/index.ts
