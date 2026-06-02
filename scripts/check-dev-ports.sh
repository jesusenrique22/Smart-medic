#!/usr/bin/env bash
# Comprueba que backend (3000), gateway (3001) y Flutter web (8080) escuchan.
set -euo pipefail

PORT_WEB="${FLUTTER_WEB_PORT:-8080}"
if [[ -f .env ]]; then
  val=$(grep -E '^FLUTTER_WEB_PORT=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$val" ]] && PORT_WEB="$val"
fi

check_port() {
  local port=$1 name=$2
  if lsof -iTCP:"$port" -sTCP:LISTEN -P -n >/dev/null 2>&1; then
    echo "  ✓ $name — puerto $port (activo)"
    return 0
  fi
  echo "  ✗ $name — puerto $port (NO hay proceso escuchando)"
  return 1
}

echo ""
echo "Estado de puertos Smart Medic"
echo "─────────────────────────────"

ok=0
check_port 3000 "Backend API" || ok=1
check_port 3001 "Gateway Socket" || ok=1
check_port "$PORT_WEB" "Flutter web" || ok=1

echo ""
if [[ $ok -ne 0 ]]; then
  echo "502 en Dev Tunnel = el puerto no tiene servicio local."
  echo ""
  echo "Arranca lo que falte:"
  echo "  ./scripts/dev-services.sh          # API + gateway (no duplica si ya corren)"
  echo "  ./scripts/serve-web-tunnel.sh      # Flutter web en :$PORT_WEB"
  echo "  ./scripts/stop-dev-ports.sh        # detener todo y empezar limpio"
  echo ""
  echo "Luego en Cursor → Puertos: visibilidad PÚBLICA en 8080, 3000, 3001."
  echo "Ver docs/DEV_TUNNELS.md"
  exit 1
fi

echo "Todo listo. Dev Tunnel / LAN debería responder en :$PORT_WEB"
exit 0
