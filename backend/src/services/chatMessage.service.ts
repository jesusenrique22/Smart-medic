import { ChatConversation, ChatMessage, ChatMessageKind } from '../models/Chat';
import { assertDoctorPatientCanCommunicate } from './chatEligibility.service';
import {
  createChatNotification,
  getSenderName,
} from './notification.service';

export async function assertConversationParticipant(
  conversationId: string,
  userId: string,
) {
  const conversation = await ChatConversation.findById(conversationId);
  if (!conversation) {
    throw new Error('Conversación no encontrada');
  }

  const isParticipant =
    conversation.doctorId.toString() === userId ||
    conversation.patientId.toString() === userId;

  if (!isParticipant) {
    throw new Error('Acceso denegado');
  }

  return conversation;
}

export async function createChatMessage(params: {
  conversationId: string;
  senderId: string;
  text: string;
  kind?: ChatMessageKind;
}) {
  const { conversationId, senderId, text } = params;
  const kind: ChatMessageKind = params.kind === 'clinical' ? 'clinical' : 'chat';
  const trimmed = String(text).trim();
  if (!trimmed) {
    throw new Error('El mensaje no puede estar vacío');
  }

  const conversation = await assertConversationParticipant(conversationId, senderId);
  await assertDoctorPatientCanCommunicate(
    conversation.doctorId,
    conversation.patientId,
  );

  const message = await ChatMessage.create({
    conversationId,
    senderId,
    text: trimmed,
    kind,
  });

  if (kind === 'clinical') {
    conversation.lastClinicalMessage = trimmed;
    conversation.lastClinicalMessageAt = new Date();
  } else {
    conversation.lastChatMessage = trimmed;
    conversation.lastChatMessageAt = new Date();
    conversation.lastMessage = trimmed;
    conversation.lastMessageAt = new Date();
  }
  await conversation.save();

  const recipientId =
    conversation.doctorId.toString() === senderId
      ? conversation.patientId.toString()
      : conversation.doctorId.toString();

  const senderName = await getSenderName(senderId);
  await createChatNotification({
    recipientId,
    senderId,
    senderName,
    text: trimmed,
    conversationId: conversation.id,
  });

  const populated = await message.populate('senderId', 'name profilePic role');
  return { message: populated, conversation, kind };
}
