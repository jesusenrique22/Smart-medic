import type { RealtimeBroadcast, RealtimeHandlerResult } from './types';

export class BackendRealtimeClient {
  constructor(
    private readonly baseUrl: string,
    private readonly secret: string,
  ) {}

  private async post<T>(path: string, body: Record<string, unknown>): Promise<T> {
    const res = await fetch(`${this.baseUrl}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Internal-Key': this.secret,
      },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(text || `Backend ${res.status}`);
    }
    return res.json() as Promise<T>;
  }

  conversationJoin(userId: string, conversationId: string) {
    return this.post<{ ok: boolean; peerId?: string }>(
      '/internal/realtime/conversation/join',
      { userId, conversationId },
    );
  }

  messageSend(
    userId: string,
    payload: { conversationId: string; text: string; kind?: 'chat' | 'clinical' },
  ) {
    return this.post<RealtimeHandlerResult>('/internal/realtime/message/send', {
      userId,
      ...payload,
    });
  }

  callInvite(
    userId: string,
    payload: {
      conversationId: string;
      callType: 'video' | 'audio';
      callerName?: string;
    },
  ) {
    return this.post<RealtimeHandlerResult>('/internal/realtime/call/invite', {
      userId,
      ...payload,
    });
  }

  callAccept(userId: string, conversationId: string) {
    return this.post<RealtimeHandlerResult>('/internal/realtime/call/accept', {
      userId,
      conversationId,
    });
  }

  callReject(userId: string, conversationId: string) {
    return this.post<RealtimeHandlerResult>('/internal/realtime/call/reject', {
      userId,
      conversationId,
    });
  }

  callEnd(userId: string, conversationId: string) {
    return this.post<RealtimeHandlerResult>('/internal/realtime/call/end', {
      userId,
      conversationId,
    });
  }

  callPeer(userId: string, conversationId: string) {
    return this.post<{ peerId: string | null }>('/internal/realtime/call/peer', {
      userId,
      conversationId,
    });
  }

  clinicAdminRooms(userId: string) {
    return this.post<{ rooms: string[] }>('/internal/realtime/clinic-admin/rooms', {
      userId,
    });
  }
}

export function applyBroadcasts(
  io: import('socket.io').Server,
  broadcasts: RealtimeBroadcast[],
): void {
  for (const b of broadcasts) {
    io.to(b.room).emit(b.event, b.payload);
  }
}
