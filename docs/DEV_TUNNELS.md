# Dev Tunnels (Cursor / VS Code) — compartir URL HTTPS

El **502 Bad Gateway** casi siempre significa: el túnel existe pero **no hay nada escuchando** en ese puerto en tu Mac.  
Comprueba con:

```bash
./scripts/check-dev-ports.sh
```

## Orden correcto (importante)

### 1. Arrancar los 3 servicios **antes** de abrir el túnel

```bash
# Terminal 1 — API + gateway
./scripts/dev-services.sh

# Terminal 2 — Flutter web en 8080 (obligatorio para el túnel :8080)
./scripts/run-web-lan.sh
```

Espera a ver en terminal algo como: `lib/main.dart is being served at http://0.0.0.0:8080`

### 2. Puertos en Cursor

Pestaña **Puertos** → añade **8080**, **3000**, **3001** solo **después** de que los servicios estén activos.

- Columna **Proceso en ejecución** debe mostrar algo (node / dart). Si está vacía → 502.
- **Visibilidad**: cambia de **Privado** a **Público** (clic derecho → *Port Visibility* → *Public*) para que otra persona pueda abrir la URL.

### 3. Copiar las 3 URLs del túnel

Cada puerto tiene su propia URL HTTPS, por ejemplo:

| Puerto | Uso | URL ejemplo |
|--------|-----|-------------|
| **8080** | App Flutter (abrir en el móvil) | `https://xxxx-8080.use2.devtunnels.ms` |
| **3000** | API REST | `https://xxxx-3000.use2.devtunnels.ms` |
| **3001** | Gateway Socket.IO | `https://xxxx-3001.use2.devtunnels.ms` |

### 4. `.env` en la raíz (sin barra final)

Pega las URLs **públicas** del túnel (no uses `127.0.0.1` ni `DEV_HOST` en este modo):

```env
PUBLIC_API_URL=https://TU-TUNEL-3000.use2.devtunnels.ms
PUBLIC_SOCKET_URL=https://TU-TUNEL-3001.use2.devtunnels.ms
API_BASE_URL=http://127.0.0.1:3000
SOCKET_URL=http://127.0.0.1:3001
FLUTTER_WEB_PORT=8080
# DEV_HOST comentado o vacío
```

### 5. Reiniciar Flutter web (obligatorio tras cambiar código o `.env`)

**Hot reload no sirve** con túnel estático. Cada vez que cambies Dart o `.env`:

```bash
# Detén el servidor (Ctrl+C) y vuelve a compilar + servir:
./scripts/serve-web-tunnel.sh
```

En el **navegador del otro dispositivo** (o ventana del túnel):

- Recarga **forzada**: `Cmd+Shift+R` (Mac) o `Ctrl+Shift+R` (Windows/Android)
- O ventana de incógnito / borrar caché del sitio `….devtunnels.ms`

El script compila con `--dart-define=ENABLE_DEV_TOOLS=true` y sirve sin caché en `index.html` / `.js`.

### 5c. Panel debug en túnel

- Icono **🐛** en **Mensajes** (barra superior)
- O abre directo: `https://TU-TUNEL-8088…/#/debug/gateway`
- Pestañas: Diagnóstico, Log, Llamadas (WebRTC en vivo)

### 5d. CORS (peticiones bloqueadas)

La app (túnel **8080** HTTPS) llama a API (**3000**) y socket (**3001**) en **otros** túneles → es cross-origin.

- Backend y gateway ya permiten `*.devtunnels.ms` en desarrollo.
- **Usa URLs HTTPS** en `PUBLIC_API_URL` y `PUBLIC_SOCKET_URL` (no `http://127.0.0.1` desde una página HTTPS).
- Tras cambiar CORS o `.env`, reinicia backend y gateway:
  ```bash
  cd backend && pnpm run dev
  cd realtime-gateway && pnpm run dev
  ```
- Origen extra (opcional) en `backend/.env` y `realtime-gateway/.env`:
  ```env
  CORS_ORIGIN=https://TU-TUNEL-8080.use2.devtunnels.ms
  ```

### 6. Abrir en el otro dispositivo

Solo la URL del puerto **8080** (la app). API y socket van embebidos vía `.env`.

---

## Error 502 / 504 en el túnel del 8080

El túnel **3000/3001** responde pero el **8080** da timeout → el reenvío de Cursor quedó mal o `flutter run` no es estable con túneles.

**Solución A — Rehacer el túnel 8080**

1. Detén `flutter run` (`q` en esa terminal).
2. Cursor → **Puertos** → elimina el **8080** (icono X).
3. Arranca: `./scripts/serve-web-tunnel.sh` (compila y sirve en 8080).
4. Agrega de nuevo el puerto **8080** → **Público**.
5. Abre la **nueva** URL del túnel 8080.

**Solución B — Probar en tu Mac primero**

`http://127.0.0.1:8080` debe cargar antes de usar el túnel.

## Checklist rápido

- [ ] `./scripts/check-dev-ports.sh` → los 3 ✓
- [ ] Túneles en **Público**
- [ ] `PUBLIC_API_URL` y `PUBLIC_SOCKET_URL` en `.env`
- [ ] Flutter reiniciado tras cambiar `.env`
- [ ] Probar `https://TU-TUNEL-3001.../health` en el móvil → JSON OK

---

## LAN vs Dev Tunnel

| Modo | `.env` | URL en el móvil |
|------|--------|-----------------|
| **Misma Wi‑Fi** | `DEV_HOST=192.168.x.x` | `http://192.168.x.x:8080` |
| **Dev Tunnel** | `PUBLIC_API_URL` + `PUBLIC_SOCKET_URL` | `https://...-8080.devtunnels.ms` |

Ver también [DEV_LAN.md](./DEV_LAN.md).

## Videollamadas

Dev Tunnels dan **HTTPS** → mejor para micrófono/cámara en móvil.  
Usa **Mensajes** → chat → llamada, con **dos cuentas distintas**.
