#!/usr/bin/env bash
# Evita EADDRINUSE: si el puerto ya tiene un servicio sano, sale con aviso (exit 0).
# Uso: _guard-dev-port.sh <puerto> <nombre> [url_health]
set -euo pipefail

PORT="${1:?puerto requerido}"
NAME="${2:?nombre requerido}"
HEALTH_URL="${3:-}"

if ! lsof -iTCP:"$PORT" -sTCP:LISTEN -P -n >/dev/null 2>&1; then
  exit 0
fi

PID=$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null | head -1 || true)

if [[ -n "$HEALTH_URL" ]] && curl -sf --connect-timeout 2 "$HEALTH_URL" >/dev/null 2>&1; then
  echo ""
  echo "→ $NAME ya está activo en :$PORT (PID ${PID:-?})."
  echo "  No arranques otro \`pnpm run dev\` en esta terminal."
  echo "  Reinicio limpio: ./scripts/stop-dev-ports.sh && pnpm run dev"
  echo ""
  exit 0
fi

echo ""
echo "✗ Puerto :$PORT ocupado (PID ${PID:-?}) pero $NAME no responde."
echo "  Libera el puerto: ./scripts/stop-dev-ports.sh"
echo ""
exit 1
