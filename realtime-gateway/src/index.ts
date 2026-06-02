import http from 'http';
import express from 'express';

import { config } from './config';
import { createCorsMiddleware } from './config/cors';
import { BackendRealtimeClient } from './backendClient';
import { createInternalEmitRouter } from './routes/internalEmit.routes';
import { initSocketServer } from './socketServer';

const app = express();
app.use(createCorsMiddleware());
app.use(express.json());

const backend = new BackendRealtimeClient(config.backendUrl, config.internalSecret);
const httpServer = http.createServer(app);
const io = initSocketServer(httpServer, backend);

app.get('/health', (_req, res) => {
  res.status(200).json({
    status: 'OK',
    service: 'smart-medic-realtime-gateway',
    backend: config.backendUrl,
  });
});

app.get('/', (_req, res) => {
  res.status(200).json({
    service: 'smart-medic-realtime-gateway',
    status: 'OK',
    message:
      'Gateway WebSocket (Socket.IO) activo. No es la API REST — usa /health para comprobar.',
    health: '/health',
    socketIo: true,
    apiRest: config.backendUrl,
    note: 'La app Flutter se conecta aquí para chat y señalización de llamadas. Login/datos: puerto 3000.',
  });
});

app.use('/internal', createInternalEmitRouter(io));

httpServer.listen(config.port, '0.0.0.0', () => {
  console.log(`Realtime Gateway (WebSocket) en puerto ${config.port} (0.0.0.0)`);
  console.log(`  Clientes Socket.IO → :${config.port}`);
  console.log(`  API backend        → ${config.backendUrl}`);
  console.log(`  JWT_SECRET cargado (${config.jwtSecret.length} chars)`);
});
