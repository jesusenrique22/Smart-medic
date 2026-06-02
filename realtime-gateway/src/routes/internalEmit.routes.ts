import { Router, Request, Response } from 'express';
import { Server } from 'socket.io';
import { config } from '../config';

export function createInternalEmitRouter(io: Server): Router {
  const router = Router();

  router.post('/emit', (req: Request, res: Response) => {
    const key = req.header('X-Internal-Key');
    if (!key || key !== config.internalSecret) {
      res.status(401).json({ error: 'No autorizado (internal)' });
      return;
    }

    const { room, event, payload } = req.body as {
      room?: string;
      event?: string;
      payload?: Record<string, unknown>;
    };

    if (!room || !event) {
      res.status(400).json({ error: 'room y event son obligatorios' });
      return;
    }

    io.to(room).emit(event, payload ?? {});
    res.json({ ok: true });
  });

  return router;
}
