#!/usr/bin/env bash
# Limpia build iOS y lanza en simulador (tras crash SIGSEGV / DevFS).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "→ Cerrando Runner en simulador si quedó colgado…"
killall Runner 2>/dev/null || true

echo "→ flutter clean + pub get…"
flutter clean
flutter pub get

echo "→ Pods iOS…"
cd ios
rm -rf Pods Podfile.lock .symlinks
pod install --repo-update
cd ..

echo "→ Abre el simulador y ejecuta: flutter run"
echo "  (Si falla DevFS: cierra Simulator, killall Runner, vuelve a ejecutar)"
