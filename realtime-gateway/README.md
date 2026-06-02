# Smart Medic — Realtime Gateway

Servicio **intermediario WebSocket** (Socket.IO) entre la app Flutter/web y el backend REST.

```
┌─────────────┐     Socket.IO      ┌──────────────────┐     HTTP interno     ┌─────────────┐
│   Cliente   │ ◄──────────────► │ realtime-gateway │ ◄──────────────────► │   backend   │
│  (Flutter)  │    puerto 3001   │    (este repo)   │   puerto 3000        │  (REST API) │
└─────────────┘                  └──────────────────┘                      └─────────────┘
```

## Responsabilidades

| Componente | Qué hace |
|------------|----------|
| **Gateway** | Conexiones Socket.IO, salas (`user:`, `conversation:`, `call:`, `facility:`), reenvío de typing/señalización WebRTC |
| **Backend** | Base de datos, reglas de negocio (chat, citas, invitaciones clínica) y emisión de eventos vía `POST /internal/emit` |

## Desarrollo local

1. Backend (terminal 1):

```bash
cd backend
pnpm install
pnpm run dev
```

2. Gateway (terminal 2):

```bash
cd realtime-gateway
cp .env.example .env
pnpm install
pnpm run dev
```

3. Flutter — en `.env` del proyecto raíz:

```
API_BASE_URL=http://localhost:3000
SOCKET_URL=http://localhost:3001
```

Usa la **misma** `JWT_SECRET` e `INTERNAL_REALTIME_SECRET` en `backend/.env` y `realtime-gateway/.env`.

## Variables

| Variable | Gateway | Backend |
|----------|---------|---------|
| `JWT_SECRET` | ✓ (auth socket) | ✓ |
| `INTERNAL_REALTIME_SECRET` | ✓ | ✓ |
| `BACKEND_URL` | ✓ | — |
| `REALTIME_GATEWAY_URL` | — | ✓ (`http://localhost:3001`) |
| `PORT` | 3001 | 3000 |
