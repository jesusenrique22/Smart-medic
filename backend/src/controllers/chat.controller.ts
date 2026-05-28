import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ChatConversation, ChatMessage, ChatMessageKind } from '../models/Chat';
import { User } from '../models/User';
import { UserRole } from '../types/enums';
import {
  assertConversationParticipant,
  createChatMessage,
} from '../services/chatMessage.service';
import {
  assertDoctorPatientCanCommunicate,
  getEligiblePeerIds,
  isEligiblePair,
  userIdFromRef,
} from '../services/chatEligibility.service';

function parseKind(value: unknown): ChatMessageKind | undefined {
  if (value === 'clinical' || value === 'chat') return value;
  return undefined;
}

function mapChatError(res: Response, e: unknown) {
  const msg = (e as Error).message;
  if (msg === 'Conversación no encontrada') {
    return res.status(404).json({ error: msg });
  }
  if (msg === 'Acceso denegado') {
    return res.status(403).json({ error: msg });
  }
  if (msg.includes('consulta') || msg.includes('comunicarte')) {
    return res.status(403).json({ error: msg });
  }
  return res.status(400).json({ error: msg });
}

/** Chats ya iniciados (conversaciones existentes del usuario). */
export const listConversations = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  const isDoctor = req.user!.role === UserRole.DOCTOR;
  const eligiblePeerIds = await getEligiblePeerIds(userId, isDoctor);

  const filter = isDoctor ? { doctorId: userId } : { patientId: userId };

  const conversations = await ChatConversation.find(filter)
    .populate('doctorId', 'name email profilePic')
    .populate('patientId', 'name email profilePic')
    .sort({ lastChatMessageAt: -1, lastMessageAt: -1, updatedAt: -1 });

  const filtered = conversations.filter((c) => {
    const docId = userIdFromRef(c.doctorId);
    const patId = userIdFromRef(c.patientId);
    if (!docId || !patId) return false;
    return isEligiblePair(docId, patId, eligiblePeerIds, isDoctor);
  });

  res.json(filtered);
};

/**
 * Contactos para nueva conversación (+): con cita y sin chat abierto aún.
 * Query: forNew=true (por defecto en el botón + del cliente).
 */
export const listContacts = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  const isDoctor = req.user!.role === UserRole.DOCTOR;
  const forNew = req.query.forNew !== 'false';

  let peerIds = await getEligiblePeerIds(userId, isDoctor);

  if (forNew && peerIds.length > 0) {
    const convFilter = isDoctor ? { doctorId: userId } : { patientId: userId };
    const existing = await ChatConversation.find(convFilter).select('doctorId patientId');
    const existingPeerIds = new Set(
      existing.map((c) =>
        isDoctor ? userIdFromRef(c.patientId) : userIdFromRef(c.doctorId),
      ),
    );
    peerIds = peerIds.filter((id) => !existingPeerIds.has(id));
  }

  if (peerIds.length === 0) {
    return res.json([]);
  }

  const users = await User.find({ _id: { $in: peerIds } })
    .select('name email profilePic role')
    .sort({ name: 1 });

  return res.json(
    users.map((u) => ({
      id: u.id,
      name: u.name,
      email: u.email,
      profilePic: u.profilePic,
      role: isDoctor ? 'patient' : 'doctor',
    })),
  );
};

export const getClinicalFeed = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  const isDoctor = req.user!.role === UserRole.DOCTOR;
  const eligiblePeerIds = await getEligiblePeerIds(userId, isDoctor);

  const convFilter = isDoctor ? { doctorId: userId } : { patientId: userId };
  const conversations = await ChatConversation.find(convFilter).select(
    '_id doctorId patientId',
  );

  const convIds = conversations
    .filter((c) =>
      isEligiblePair(
        userIdFromRef(c.doctorId),
        userIdFromRef(c.patientId),
        eligiblePeerIds,
        isDoctor,
      ),
    )
    .map((c) => c._id);

  const messages = await ChatMessage.find({
    conversationId: { $in: convIds },
    kind: 'clinical',
  })
    .populate('senderId', 'name profilePic role')
    .populate({
      path: 'conversationId',
      populate: [
        { path: 'doctorId', select: 'name profilePic' },
        { path: 'patientId', select: 'name profilePic' },
      ],
    })
    .sort({ createdAt: -1 })
    .limit(200);

  res.json(messages);
};

export const getOrCreateConversation = async (req: AuthRequest, res: Response) => {
  const { doctorId, patientId } = req.body;

  let docId = doctorId;
  let patId = patientId;

  if (req.user!.role === UserRole.DOCTOR) {
    docId = req.user!.id;
    if (!patId) return res.status(400).json({ error: 'patientId requerido' });
  } else {
    patId = req.user!.id;
    if (!docId) return res.status(400).json({ error: 'doctorId requerido' });
  }

  try {
    await assertDoctorPatientCanCommunicate(docId, patId);
  } catch (e) {
    return mapChatError(res, e);
  }

  let conversation = await ChatConversation.findOne({ doctorId: docId, patientId: patId });
  if (!conversation) {
    conversation = await ChatConversation.create({ doctorId: docId, patientId: patId });
  }

  const populated = await conversation.populate([
    { path: 'doctorId', select: 'name email profilePic' },
    { path: 'patientId', select: 'name email profilePic' },
  ]);

  res.json(populated);
};

export const getMessages = async (req: AuthRequest, res: Response) => {
  let conversation;
  try {
    conversation = await assertConversationParticipant(
      req.params.conversationId,
      req.user!.id,
    );
    await assertDoctorPatientCanCommunicate(
      conversation.doctorId,
      conversation.patientId,
    );
  } catch (e) {
    return mapChatError(res, e);
  }

  const kind = parseKind(req.query.kind) ?? 'chat';
  const messages = await ChatMessage.find({
    conversationId: conversation.id,
    kind,
  })
    .populate('senderId', 'name profilePic role')
    .sort({ createdAt: 1 });

  res.json(messages);
};

export const sendMessage = async (req: AuthRequest, res: Response) => {
  const { conversationId, text, kind } = req.body;
  try {
    const { message } = await createChatMessage({
      conversationId,
      senderId: req.user!.id,
      text,
      kind: parseKind(kind),
    });
    res.status(201).json(message);
  } catch (e) {
    return mapChatError(res, e);
  }
};
