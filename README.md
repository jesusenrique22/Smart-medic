# Smart Medic

App Flutter + backend REST (`backend/`) + gateway WebSocket (`realtime-gateway/`).

## Desarrollo local

| Servicio | Puerto | Comando |
|----------|--------|---------|
| API | 3000 | `cd backend && pnpm run dev` |
| Gateway | 3001 | `cd realtime-gateway && pnpm run dev` |
| Flutter web (LAN) | **8080** | `./scripts/run-web-lan.sh` |

Copia `.env.example` → `.env` en la raíz del proyecto.

## Web desde otro dispositivo (videollamadas, etc.)

1. Pon en `.env`: `DEV_HOST=<IP Wi‑Fi de tu Mac>` y `FLUTTER_WEB_PORT=8080`
2. Arranca backend, gateway y `./scripts/run-web-lan.sh`
3. En el móvil (misma Wi‑Fi): `http://<DEV_HOST>:8080`

Guía completa: [docs/DEV_LAN.md](docs/DEV_LAN.md) · Dev Tunnels (502): [docs/DEV_TUNNELS.md](docs/DEV_TUNNELS.md)

Comprobar puertos: `./scripts/check-dev-ports.sh`
