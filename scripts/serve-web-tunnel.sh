#!/usr/bin/env bash
# Compila y sirve la app web para Dev Tunnels (panel debug + sin caché agresiva).
#
# Uso:
#   ./scripts/serve-web-tunnel.sh           # compila + sirve (reinicia :8088 si estaba activo)
#   ./scripts/serve-web-tunnel.sh --status  # solo comprueba si la web ya corre
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PORT="${TUNNEL_WEB_PORT:-8088}"
if [[ -f .env ]]; then
  val=$(grep -E '^FLUTTER_WEB_PORT=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$val" ]] && PORT="$val"
fi

free_port() {
  local pids
  pids=$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    echo "→ Liberando puerto $PORT (PID $pids)…"
    kill $pids 2>/dev/null || true
    sleep 0.5
    pids=$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)
    [[ -n "$pids" ]] && kill -9 $pids 2>/dev/null || true
  fi
}

if [[ "${1:-}" == "--status" ]]; then
  if lsof -iTCP:"$PORT" -sTCP:LISTEN -P -n >/dev/null 2>&1; then
    echo "✓ Web activa en http://127.0.0.1:${PORT}"
    echo "  Túnel: https://….-${PORT}.devtunnels.ms"
    echo "  Para recompilar: ./scripts/serve-web-tunnel.sh"
  else
    echo "✗ Web NO está en el puerto $PORT"
    echo "  Arranca: ./scripts/serve-web-tunnel.sh"
  fi
  exit 0
fi

free_port

echo "Compilando Flutter web (release + panel debug para túneles)…"
flutter build web --release --dart-define=ENABLE_DEV_TOOLS=true

free_port

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Web en http://0.0.0.0:${PORT} (sin caché en HTML/JS)"
echo ""
echo "  1. Cursor → Puertos → ${PORT} → Público"
echo "  2. Abre https://….-${PORT}.devtunnels.ms en el otro dispositivo"
echo "  3. Panel debug: 🐛 en Mensajes o #/debug/gateway"
echo ""
echo "  ACTUALIZAR tras cambiar código:"
echo "    ./scripts/serve-web-tunnel.sh"
echo "    Recarga forzada en el navegador (Cmd+Shift+R)"
echo "════════════════════════════════════════════════════════════"
echo ""

exec python3 "$ROOT/scripts/serve_web_no_cache.py" --port "$PORT" --directory "$ROOT/build/web"
