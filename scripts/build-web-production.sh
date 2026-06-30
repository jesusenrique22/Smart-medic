#!/usr/bin/env bash
# Compila Flutter web para producción (Render Static Site).
#
# Uso:
#   ./scripts/build-web-production.sh
#   API_BASE_URL=https://tu-backend.onrender.com SOCKET_URL=https://tu-gateway.onrender.com ./scripts/build-web-production.sh
#
# Requisitos: Flutter SDK en PATH.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

API_BASE_URL="${API_BASE_URL:-}"
SOCKET_URL="${SOCKET_URL:-}"

if [[ -z "$API_BASE_URL" || -z "$SOCKET_URL" ]]; then
  if [[ -f "$ROOT/.env.production.local" ]]; then
    # shellcheck disable=SC1091
    source "$ROOT/.env.production.local"
  elif [[ -f "$ROOT/.env.production.example" ]]; then
    echo "→ Leyendo URLs desde .env.production.example (edítalo con tus URLs de Render)"
    API_BASE_URL="$(grep -E '^API_BASE_URL=' .env.production.example | cut -d= -f2- | tr -d '\r"')"
    SOCKET_URL="$(grep -E '^SOCKET_URL=' .env.production.example | cut -d= -f2- | tr -d '\r"')"
  fi
fi

if [[ -z "$API_BASE_URL" || -z "$SOCKET_URL" ]]; then
  echo "✗ Define API_BASE_URL y SOCKET_URL"
  echo ""
  echo "  API_BASE_URL=https://tu-backend.onrender.com \\"
  echo "  SOCKET_URL=https://tu-gateway.onrender.com \\"
  echo "  ./scripts/build-web-production.sh"
  echo ""
  echo "  O crea .env.production.local con esas variables."
  exit 1
fi

if [[ "$API_BASE_URL" == *"smart-medic-backend.onrender.com"* ]] && [[ ! -f "$ROOT/.env.production.local" ]]; then
  echo "⚠ Usando URLs de ejemplo. Edita .env.production.example con tus URLs reales de Render."
fi

ENV_BACKUP=""
if [[ -f "$ROOT/.env" ]]; then
  ENV_BACKUP="$(mktemp)"
  cp "$ROOT/.env" "$ENV_BACKUP"
fi

cleanup() {
  if [[ -n "$ENV_BACKUP" && -f "$ENV_BACKUP" ]]; then
    cp "$ENV_BACKUP" "$ROOT/.env"
    rm -f "$ENV_BACKUP"
  fi
}
trap cleanup EXIT

cat >"$ROOT/.env" <<EOF
API_BASE_URL=${API_BASE_URL}
SOCKET_URL=${SOCKET_URL}
ENABLE_DEV_TOOLS=false
EOF

echo ""
echo "Smart Medic — build web producción"
echo "──────────────────────────────────"
echo "  API:    ${API_BASE_URL}"
echo "  Socket: ${SOCKET_URL}"
echo ""

echo "→ Compilando Flutter web (release)…"
flutter build web --release \
  --no-tree-shake-icons \
  --no-web-resources-cdn \
  --dart-define=ENABLE_DEV_TOOLS=false

if [[ -f "$ROOT/deploy/web/_redirects" ]]; then
  cp "$ROOT/deploy/web/_redirects" "$ROOT/build/web/_redirects"
  echo "→ _redirects (SPA) copiado"
fi

echo ""
echo "✓ Listo: $ROOT/build/web"
echo ""
echo "Despliegue:"
echo "  · GitHub Action → push a main (despliega rama render-web automáticamente)"
echo "  · Manual: sube build/web a Render Static Site"
echo ""
echo "Health checks:"
echo "  ${API_BASE_URL}/health"
echo "  ${SOCKET_URL}/health"
echo ""
