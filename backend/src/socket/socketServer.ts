import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { AuthPayload } from '../middleware/auth';
import { ChatConversation } from '../models/Chat';
import { assertDoctorPatientCanCommunicate } from '../services/chatEligibility.service';
import { createChatMessage } from '../services/chatMessage.service';

const JWT_SECRET = process.env.JWT_SECRET || 'vita-os-super-secret';

type AuthedSocket = Socket & { data: { user: AuthPayload } };

function serializeMessage(message: unknown) {
  const doc = message as { toObject?: () => object };
  if (doc && typeof doc.toObject === 'function') {
    return doc.toObject();
  }
  return message;
}

function peerUserId(
  conversation: { doctorId: { toString(): string }; patientId: { toString(): string } },
  userId: string,
): string {
  return conversation.doctorId.toString() === userId
    ? conversation.patientId.toString()
    : conversation.doctorId.toString();
}

export function initSocketServer(httpServer: HttpServer): Server {
  const io = new Server(httpServer, {
    cors: { origin: '*' },
    transports: ['websocket', 'polling'],
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth?.token as string | undefined;
    if (!token) {
      return next(new Error('Token requerido'));
    }
    try {
      const user = jwt.verify(token, JWT_SECRET) as AuthPayload;
      socket.data.user = user;
      next();
    } catch {
      next(new Error('Token inválido'));
    }
  });

  io.on('connection', (socket: AuthedSocket) => {
    const userId = socket.data.user.id;
    socket.join(`user:${userId}`);

    socket.on('conversation:join', async (conversationId: string) => {
      try {
        const conversation = await ChatConversation.findById(conversationId);
        if (!conversation) return;
        const isParticipant =
          conversation.doctorId.toString() === userId ||
          conversation.patientId.toString() === userId;
        if (!isParticipant) return;
        await assertDoctorPatientCanCommunicate(
          conversation.doctorId,
          conversation.patientId,
        );
        socket.join(`conversation:${conversationId}`);
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
          const { message, kind } = await createChatMessage({
            conversationId: payload.conversationId,
            senderId: userId,
            text: payload.text,
            kind: payload.kind,
          });

          const serialized = serializeMessage(message);
          io.to(`conversation:${payload.conversationId}`).emit('message:new', {
            conversationId: payload.conversationId,
            kind,
            message: serialized,
          });

          const conversation = await ChatConversation.findById(payload.conversationId);
          if (conversation) {
            const peerId =
              conversation.doctorId.toString() === userId
                ? conversation.patientId.toString()
                : conversation.doctorId.toString();
            const preview = payload.text.trim();
            io.to(`user:${peerId}`).emit('conversation:updated', {
              conversationId: payload.conversationId,
              kind,
              lastMessage: kind === 'clinical' ? preview : preview,
              lastChatMessage: conversation.lastChatMessage,
              lastClinicalMessage: conversation.lastClinicalMessage,
            });
          }

          ack?.({ ok: true, message: serialized });
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

    // WebRTC signaling
    socket.on(
      'call:invite',
      async (payload: {
        conversationId: string;
        callType: 'video' | 'audio';
        callerName?: string;
      }) => {
        const conversation = await ChatConversation.findById(payload.conversationId);
        if (!conversation) return;

        const isParticipant =
          conversation.doctorId.toString() === userId ||
          conversation.patientId.toString() === userId;
        if (!isParticipant) return;

        try {
          await assertDoctorPatientCanCommunicate(
            conversation.doctorId,
            conversation.patientId,
          );
        } catch {
          return;
        }

        const calleeId = peerUserId(conversation, userId);
        const callRoom = `call:${payload.conversationId}`;

        // El llamador entra a la sala de señalización antes de que el otro conteste.
        socket.join(callRoom);

        io.to(`user:${calleeId}`).emit('call:incoming', {
          conversationId: payload.conversationId,
          callType: payload.callType,
          callerId: userId,
          callerName: payload.callerName ?? 'Usuario',
        });

        if (process.env.NODE_ENV !== 'production') {
          console.log(
            `[call] invite ${userId} -> user:${calleeId} conv=${payload.conversationId}`,
          );
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

    socket.on('call:accept', async (payload: { conversationId: string }) => {
      const conversation = await ChatConversation.findById(payload.conversationId);
      if (!conversation) return;

      const callRoom = `call:${payload.conversationId}`;
      socket.join(callRoom);

      const peerId = peerUserId(conversation, userId);
      const acceptedPayload = {
        conversationId: payload.conversationId,
        userId,
      };

      // El llamador suele estar en user:{id}, no aún en call: — notificar por ambos canales.
      io.to(`user:${peerId}`).emit('call:accepted', acceptedPayload);
      socket.to(callRoom).emit('call:accepted', acceptedPayload);

      if (process.env.NODE_ENV !== 'production') {
        console.log(`[call] accept ${userId} -> user:${peerId} conv=${payload.conversationId}`);
      }
    });

    socket.on('call:reject', async (payload: { conversationId: string }) => {
      const conversation = await ChatConversation.findById(payload.conversationId);
      if (!conversation) return;

      const peerId = peerUserId(conversation, userId);
      const rejectedPayload = {
        conversationId: payload.conversationId,
        userId,
      };

      io.to(`user:${peerId}`).emit('call:rejected', rejectedPayload);
      socket.to(`call:${payload.conversationId}`).emit('call:rejected', rejectedPayload);
    });

    const emitCallSignaling = async (
      payload: { conversationId: string },
      event: string,
      body: Record<string, unknown>,
    ) => {
      const conversation = await ChatConversation.findById(payload.conversationId);
      if (!conversation) return;

      const callRoom = `call:${payload.conversationId}`;
      const peerId = peerUserId(conversation, userId);
      const signalId = `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
      const message = { ...body, fromUserId: userId, signalId };

      socket.join(callRoom);
      socket.to(callRoom).emit(event, message);
      // Respaldo si el peer aún no está en call: (el cliente deduplica por signalId).
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
      const conversation = await ChatConversation.findById(payload.conversationId);
      const endedPayload = {
        conversationId: payload.conversationId,
        userId,
      };

      if (conversation) {
        const peerId = peerUserId(conversation, userId);
        io.to(`user:${peerId}`).emit('call:ended', endedPayload);
      }
      socket.to(`call:${payload.conversationId}`).emit('call:ended', endedPayload);
      socket.leave(`call:${payload.conversationId}`);
    });
  });

  return io;
}
