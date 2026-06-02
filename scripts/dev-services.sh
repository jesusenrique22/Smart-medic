#!/usr/bin/env bash
# Arranca API (3000) y gateway WebSocket (3001) en paralelo.
# Si ya están activos y responden /health, no duplica procesos.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

health_ok() {
  local port=$1
  curl -sf --connect-timeout 2 "http://127.0.0.1:${port}/health" >/dev/null 2>&1
}

port_listening() {
  lsof -iTCP:"$1" -sTCP:LISTEN -P -n >/dev/null 2>&1
}

api_up=false
gw_up=false
health_ok 3000 && api_up=true
health_ok 3001 && gw_up=true

if $api_up && $gw_up; then
  echo ""
  echo "✓ Backend (3000) y gateway (3001) ya están activos y responden /health."
  echo "  No hace falta volver a ejecutar dev-services.sh."
  echo ""
  echo "  API:    http://127.0.0.1:3000"
  echo "  Socket: http://127.0.0.1:3001"
  echo ""
  echo "  Para reiniciarlos: ./scripts/stop-dev-ports.sh && ./scripts/dev-services.sh"
  echo ""
  exit 0
fi

if port_listening 3000 || port_listening 3001; then
  echo ""
  echo "⚠ Puertos 3000/3001 ocupados pero /health no responde bien."
  echo "  Libera puertos: ./scripts/stop-dev-ports.sh"
  echo "  Luego:          ./scripts/dev-services.sh"
  echo ""
  exit 1
fi

cleanup() {
  kill "$API_PID" "$GW_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "→ Backend API (puerto 3000)..."
(cd "$ROOT/backend" && pnpm run dev) &
API_PID=$!

echo "→ Realtime gateway (puerto 3001)..."
(cd "$ROOT/realtime-gateway" && pnpm run dev) &
GW_PID=$!

echo ""
echo "Servicios en marcha. Flutter .env:"
echo "  API_BASE_URL=http://127.0.0.1:3000"
echo "  SOCKET_URL=http://127.0.0.1:3001"
echo "Ctrl+C para detener ambos."
wait
