export type RealtimeBroadcast = {
  room: string;
  event: string;
  payload: Record<string, unknown>;
};

export type RealtimeHandlerResult = {
  broadcasts: RealtimeBroadcast[];
  ack?: Record<string, unknown>;
};
