#!/usr/bin/env bash
# Diagnóstico Dev Tunnel: stack local + URLs + checklist Cursor Puertos.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PORT_WEB="${FLUTTER_WEB_PORT:-8088}"
PREFIX=""
REGION="${TUNNEL_REGION:-use2}"
if [[ -f .env ]]; then
  val=$(grep -E '^FLUTTER_WEB_PORT=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$val" ]] && PORT_WEB="$val"
  PREFIX=$(grep -E '^TUNNEL_PREFIX=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  r=$(grep -E '^TUNNEL_REGION=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$r" ]] && REGION="$r"
fi

probe() {
  local label=$1 url=$2
  local line code time
  line=$(curl -s -o /dev/null -w "%{http_code} %{time_total}" --max-time 25 "$url" 2>/dev/null || echo "000 0")
  code=$(echo "$line" | awk '{print $1}')
  time=$(echo "$line" | awk '{print $2}')
  if [[ "$code" == "200" || "$code" == "304" ]]; then
    echo "  ✓ $label — HTTP $code (${time}s)"
    return 0
  fi
  if [[ "$code" == "502" || "$code" == "504" || "$code" == "000" ]]; then
    echo "  ✗ $label — HTTP $code (${time}s) ← túnel sin servicio local o timeout"
  else
    echo "  ✗ $label — HTTP $code (${time}s)"
  fi
  return 1
}

echo ""
echo "Smart Medic — diagnóstico Dev Tunnel"
echo "════════════════════════════════════"

echo ""
echo "1) Servicios locales"
./scripts/check-dev-ports.sh || true

if [[ -z "$PREFIX" ]]; then
  echo ""
  echo "⚠ Sin TUNNEL_PREFIX en .env"
  echo "  Copia la URL del puerto $PORT_WEB en Cursor → Puertos y ejecuta:"
  echo "    ./scripts/tunnel-sync-env.sh https://TU-PREFIJO-${PORT_WEB}.${REGION}.devtunnels.ms"
  exit 1
fi

BASE="https://${PREFIX}-${PORT_WEB}.${REGION}.devtunnels.ms"
WRONG_API="https://${PREFIX}-3000.${REGION}.devtunnels.ms"
WRONG_GW="https://${PREFIX}-3001.${REGION}.devtunnels.ms"

echo ""
echo "2) Túnel correcto (solo :${PORT_WEB})"
tunnel_ok=0
probe "Web /" "${BASE}/" && tunnel_ok=1 || true
probe "API /health (proxy)" "${BASE}/health" && tunnel_ok=1 || true
probe "Gateway /gateway-health (proxy)" "${BASE}/gateway-health" && tunnel_ok=1 || true
probe "main.dart.js" "${BASE}/main.dart.js" && tunnel_ok=1 || true

echo ""
echo "3) URLs que NO debes usar en el navegador"
echo "  ✗ ${WRONG_API}  (API cruda — sin Flutter, sin proxy unificado)"
echo "  ✗ ${WRONG_GW}  (gateway crudo — sin app)"
echo "  ✓ ${BASE}  ← abre SOLO esta"

echo ""
echo "4) Cursor → Puertos (corrige tu panel)"
echo "  ┌────────┬──────────────────────────────────────────────┐"
echo "  │ Puerto │ Visibilidad                                  │"
echo "  ├────────┼──────────────────────────────────────────────┤"
echo "  │ 8088   │ PÚBLICO  (python en Running Process)       │"
echo "  │ 3000   │ Privado o eliminar (icono X)                 │"
echo "  │ 3001   │ Privado o eliminar (icono X)                 │"
echo "  └────────┴──────────────────────────────────────────────┘"
echo ""
echo "  Si 3000/3001 están Públicos con «User Forwarded», la app va mal:"
echo "  · Clic derecho en 3000 y 3001 → Port Visibility → Private"
echo "  · O elimínalos (X) y deja solo ${PORT_WEB} público"
echo ""
echo "  «Running Process» vacío a veces es normal en Cursor;"
echo "  lo importante es que ./scripts/check-dev-ports.sh muestre ✓"

echo ""
if [[ $tunnel_ok -eq 1 ]]; then
  echo "Túnel :${PORT_WEB} responde. Abre: ${BASE}"
  echo "Recarga forzada: Cmd+Shift+R · Si hay VPN, prueba sin ella."
else
  echo "El túnel no responde bien. Pasos:"
  echo "  1) ./scripts/stop-dev-ports.sh"
  echo "  2) cd backend && pnpm run dev"
  echo "  3) cd realtime-gateway && pnpm run dev  (otra terminal)"
  echo "  4) Cursor → elimina puertos 3000/3001 públicos → solo ${PORT_WEB} Público"
  echo "  5) ./scripts/tunnel-sync-env.sh --check"
fi
echo ""
