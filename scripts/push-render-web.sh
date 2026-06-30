#!/usr/bin/env bash
# Compila Flutter web y sube la rama render-web a GitHub (para Render Static Site).
#
# 1) Crea .env.production.local con tus URLs de Render:
#      API_BASE_URL=https://tu-backend.onrender.com
#      SOCKET_URL=https://tu-gateway.onrender.com
# 2) Ejecuta: ./scripts/push-render-web.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f "$ROOT/.env.production.local" ]]; then
  echo "✗ Crea .env.production.local con API_BASE_URL y SOCKET_URL (URLs de Render)."
  echo ""
  echo "  cp .env.production.example .env.production.local"
  echo "  # edita las URLs reales del dashboard de Render"
  exit 1
fi

# shellcheck disable=SC1091
source "$ROOT/.env.production.local"

export API_BASE_URL SOCKET_URL
"$ROOT/scripts/build-web-production.sh"

DEPLOY_DIR="$(mktemp -d)"
trap 'rm -rf "$DEPLOY_DIR"' EXIT

cp -R "$ROOT/build/web/." "$DEPLOY_DIR/"
cd "$DEPLOY_DIR"

git init -q
git config user.email "deploy@smart-medic.local"
git config user.name "Smart Medic Deploy"
git checkout -b render-web 2>/dev/null || git checkout -B render-web
git add -A
git commit -q -m "deploy: flutter web $(date -u +%Y-%m-%dT%H:%M:%SZ)"

REMOTE="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
if [[ -z "$REMOTE" ]]; then
  echo "✗ Sin remote origin en el repo principal."
  exit 1
fi

git remote add origin "$REMOTE"
echo "→ Subiendo rama render-web a GitHub…"
git push -f origin render-web

echo ""
echo "✓ Rama render-web actualizada."
echo ""
echo "En Render → New Static Site:"
echo "  · Repo: Smart-medic"
echo "  · Branch: render-web"
echo "  · Publish directory: . (raíz)"
echo "  · Build command: (vacío)"
echo "  · Rewrite: /* → /index.html"
echo ""
