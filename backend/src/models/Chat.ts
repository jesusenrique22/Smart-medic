import mongoose, { Document, Schema, Types } from 'mongoose';

export type ChatMessageKind = 'chat' | 'clinical';

export interface IChatConversation extends Document {
  doctorId: Types.ObjectId;
  patientId: Types.ObjectId;
  /** Último mensaje de chat libre (estilo WhatsApp). */
  lastChatMessage?: string;
  lastChatMessageAt?: Date;
  /** Último mensaje clínico enviado desde historial médico. */
  lastClinicalMessage?: string;
  lastClinicalMessageAt?: Date;
  /** Compatibilidad: espejo de lastChatMessage. */
  lastMessage?: string;
  lastMessageAt?: Date;
}

const chatConversationSchema = new Schema<IChatConversation>(
  {
    doctorId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    patientId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    lastChatMessage: { type: String },
    lastChatMessageAt: { type: Date },
    lastClinicalMessage: { type: String },
    lastClinicalMessageAt: { type: Date },
    lastMessage: { type: String },
    lastMessageAt: { type: Date },
  },
  { timestamps: true, collection: 'chat_conversations' },
);

chatConversationSchema.index({ doctorId: 1, patientId: 1 }, { unique: true });

export const ChatConversation = mongoose.model<IChatConversation>(
  'ChatConversation',
  chatConversationSchema,
);

export interface IChatMessage extends Document {
  conversationId: Types.ObjectId;
  senderId: Types.ObjectId;
  text: string;
  kind: ChatMessageKind;
  readAt?: Date;
}

const chatMessageSchema = new Schema<IChatMessage>(
  {
    conversationId: {
      type: Schema.Types.ObjectId,
      ref: 'ChatConversation',
      required: true,
    },
    senderId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    text: { type: String, required: true, trim: true },
    kind: { type: String, enum: ['chat', 'clinical'], default: 'chat' },
    readAt: { type: Date },
  },
  { timestamps: true, collection: 'chat_messages' },
);

chatMessageSchema.index({ conversationId: 1, createdAt: 1 });

export const ChatMessage = mongoose.model<IChatMessage>('ChatMessage', chatMessageSchema);
