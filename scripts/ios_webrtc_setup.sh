#!/usr/bin/env bash
# Enlaza flutter_webrtc en iOS. Ejecutar una vez tras clonar o añadir el plugin.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "→ flutter pub get"
flutter pub get

echo "→ pod install (ios)"
cd ios
pod install --repo-update
cd ..

echo "→ flutter clean + build iOS (simulador)"
flutter clean
flutter pub get
flutter build ios --simulator --no-codesign

echo ""
echo "Listo. Ahora ejecuta: flutter run"
echo "(elige el simulador iOS; no uses solo hot restart)"
