import { Request, Response } from 'express';
import {
  getClinicAdminFacilityRoom,
  handleCallAccept,
  handleCallEnd,
  handleCallInvite,
  handleCallReject,
  handleSocketMessageSend,
  resolveCallPeer,
  validateConversationJoin,
} from '../services/realtimeOrchestration.service';

export const postConversationJoin = async (req: Request, res: Response) => {
  const { userId, conversationId } = req.body as {
    userId?: string;
    conversationId?: string;
  };
  if (!userId || !conversationId) {
    return res.status(400).json({ error: 'userId y conversationId son obligatorios' });
  }
  const result = await validateConversationJoin(userId, conversationId);
  res.json(result);
};

export const postMessageSend = async (req: Request, res: Response) => {
  const { userId, conversationId, text, kind } = req.body as {
    userId?: string;
    conversationId?: string;
    text?: string;
    kind?: 'chat' | 'clinical';
  };
  if (!userId || !conversationId || text == null) {
    return res.status(400).json({ error: 'Parámetros incompletos' });
  }
  try {
    const result = await handleSocketMessageSend(userId, {
      conversationId,
      text: String(text),
      kind,
    });
    res.json(result);
  } catch (e) {
    res.status(400).json({ ok: false, error: (e as Error).message });
  }
};

export const postCallInvite = async (req: Request, res: Response) => {
  const { userId, conversationId, callType, callerName } = req.body;
  if (!userId || !conversationId || !callType) {
    return res.status(400).json({ error: 'Parámetros incompletos' });
  }
  const result = await handleCallInvite(userId, {
    conversationId,
    callType,
    callerName,
  });
  res.json(result);
};

export const postCallAccept = async (req: Request, res: Response) => {
  const { userId, conversationId } = req.body;
  if (!userId || !conversationId) {
    return res.status(400).json({ error: 'Parámetros incompletos' });
  }
  const result = await handleCallAccept(userId, { conversationId });
  res.json(result);
};

export const postCallReject = async (req: Request, res: Response) => {
  const { userId, conversationId } = req.body;
  if (!userId || !conversationId) {
    return res.status(400).json({ error: 'Parámetros incompletos' });
  }
  const result = await handleCallReject(userId, { conversationId });
  res.json(result);
};

export const postCallEnd = async (req: Request, res: Response) => {
  const { userId, conversationId } = req.body;
  if (!userId || !conversationId) {
    return res.status(400).json({ error: 'Parámetros incompletos' });
  }
  const result = await handleCallEnd(userId, { conversationId });
  res.json(result);
};

export const postCallPeer = async (req: Request, res: Response) => {
  const { userId, conversationId } = req.body;
  if (!userId || !conversationId) {
    return res.status(400).json({ error: 'Parámetros incompletos' });
  }
  const peerId = await resolveCallPeer(userId, conversationId);
  res.json({ peerId });
};

export const postClinicAdminRooms = async (req: Request, res: Response) => {
  const { userId } = req.body as { userId?: string };
  if (!userId) {
    return res.status(400).json({ error: 'userId es obligatorio' });
  }
  const facilityId = await getClinicAdminFacilityRoom(userId);
  res.json({
    rooms: facilityId ? [`facility:${facilityId}`] : [],
  });
};
