import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { BackendRealtimeClient, applyBroadcasts } from './backendClient';
import { config } from './config';
import { socketIoCorsConfig } from './config/cors';

type AuthPayload = { id: string; role: string };
type AuthedSocket = Socket & { data: { user: AuthPayload } };

export function initSocketServer(
  httpServer: HttpServer,
  backend: BackendRealtimeClient,
): Server {
  const io = new Server(httpServer, {
    cors: socketIoCorsConfig(),
    transports: ['polling', 'websocket'],
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth?.token as string | undefined;
    if (!token) {
      return next(new Error('Token requerido'));
    }
    try {
      const user = jwt.verify(token, config.jwtSecret) as AuthPayload;
      socket.data.user = user;
      next();
    } catch {
      next(new Error('Token inválido'));
    }
  });

  io.on('connection', (socket: AuthedSocket) => {
    const userId = socket.data.user.id;
    const role = socket.data.user.role;
    socket.join(`user:${userId}`);

    if (role === 'CLINIC_ADMIN') {
      void backend
        .clinicAdminRooms(userId)
        .then(({ rooms }) => {
          for (const room of rooms) {
            socket.join(room);
          }
        })
        .catch(() => undefined);
    }

    socket.on('conversation:join', async (conversationId: string) => {
      try {
        const result = await backend.conversationJoin(userId, conversationId);
        if (result.ok) {
          socket.join(`conversation:${conversationId}`);
        }
      } catch {
        // ignore
      }
    });

    socket.on('conversation:leave', (conversationId: string) => {
      socket.leave(`conversation:${conversationId}`);
    });

    socket.on(
      'message:send',
      async (
        payload: { conversationId: string; text: string; kind?: 'chat' | 'clinical' },
        ack?: (response: { ok: boolean; error?: string; message?: unknown }) => void,
      ) => {
        try {
          const result = await backend.messageSend(userId, payload);
          applyBroadcasts(io, result.broadcasts);
          const ackBody = result.ack ?? { ok: true };
          ack?.(ackBody as { ok: boolean; error?: string; message?: unknown });
        } catch (e) {
          ack?.({ ok: false, error: (e as Error).message });
        }
      },
    );

    socket.on('typing:start', (payload: { conversationId: string }) => {
      socket.to(`conversation:${payload.conversationId}`).emit('typing:start', {
        conversationId: payload.conversationId,
        userId,
      });
    });

    socket.on('typing:stop', (payload: { conversationId: string }) => {
      socket.to(`conversation:${payload.conversationId}`).emit('typing:stop', {
        conversationId: payload.conversationId,
        userId,
      });
    });

    socket.on(
      'call:invite',
      async (payload: {
        conversationId: string;
        callType: 'video' | 'audio';
        callerName?: string;
      }) => {
        try {
          const callRoom = `call:${payload.conversationId}`;
          socket.join(callRoom);
          const result = await backend.callInvite(userId, payload);
          applyBroadcasts(io, result.broadcasts);
          if (process.env.NODE_ENV !== 'production') {
            console.log(`[call] invite ${userId} conv=${payload.conversationId}`);
          }
        } catch {
          // ignore
        }
      },
    );

    socket.on('call:join', (payload: { conversationId: string }) => {
      if (payload?.conversationId) {
        socket.join(`call:${payload.conversationId}`);
      }
    });

    socket.on('call:leave', (payload: { conversationId: string }) => {
      if (payload?.conversationId) {
        socket.leave(`call:${payload.conversationId}`);
      }
    });

    const emitHandlerBroadcasts = (broadcasts: import('./types').RealtimeBroadcast[]) => {
      for (const b of broadcasts) {
        if (b.room.startsWith('call:')) {
          socket.to(b.room).emit(b.event, b.payload);
        } else {
          io.to(b.room).emit(b.event, b.payload);
        }
      }
    };

    socket.on('call:accept', async (payload: { conversationId: string }) => {
      try {
        const callRoom = `call:${payload.conversationId}`;
        socket.join(callRoom);
        const result = await backend.callAccept(userId, payload.conversationId);
        emitHandlerBroadcasts(result.broadcasts);
      } catch {
        // ignore
      }
    });

    socket.on('call:reject', async (payload: { conversationId: string }) => {
      try {
        const result = await backend.callReject(userId, payload.conversationId);
        emitHandlerBroadcasts(result.broadcasts);
      } catch {
        // ignore
      }
    });

    const emitCallSignaling = async (
      payload: { conversationId: string },
      event: string,
      body: Record<string, unknown>,
    ) => {
      const { peerId } = await backend.callPeer(userId, payload.conversationId);
      if (!peerId) return;

      const callRoom = `call:${payload.conversationId}`;
      const signalId = `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
      const message = { ...body, fromUserId: userId, signalId };

      socket.join(callRoom);
      socket.to(callRoom).emit(event, message);
      io.to(`user:${peerId}`).emit(event, message);
    };

    socket.on(
      'call:offer',
      (payload: { conversationId: string; sdp: unknown; callType?: string }) => {
        void emitCallSignaling(payload, 'call:offer', {
          conversationId: payload.conversationId,
          sdp: payload.sdp,
          callType: payload.callType,
        });
      },
    );

    socket.on('call:answer', (payload: { conversationId: string; sdp: unknown }) => {
      void emitCallSignaling(payload, 'call:answer', {
        conversationId: payload.conversationId,
        sdp: payload.sdp,
      });
    });

    socket.on(
      'call:ice',
      (payload: { conversationId: string; candidate: unknown }) => {
        void emitCallSignaling(payload, 'call:ice', {
          conversationId: payload.conversationId,
          candidate: payload.candidate,
        });
      },
    );

    socket.on('call:end', async (payload: { conversationId: string }) => {
      try {
        const result = await backend.callEnd(userId, payload.conversationId);
        emitHandlerBroadcasts(result.broadcasts);
        socket.leave(`call:${payload.conversationId}`);
      } catch {
        // ignore
      }
    });
  });

  return io;
}
