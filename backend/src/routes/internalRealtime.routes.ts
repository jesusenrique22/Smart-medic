import { Router } from 'express';
import { requireInternalRealtimeAuth } from '../middleware/internalAuth';
import {
  postCallAccept,
  postCallEnd,
  postCallInvite,
  postCallPeer,
  postCallReject,
  postClinicAdminRooms,
  postConversationJoin,
  postMessageSend,
} from '../controllers/internalRealtime.controller';

const router = Router();

router.use(requireInternalRealtimeAuth);

router.post('/conversation/join', postConversationJoin);
router.post('/message/send', postMessageSend);
router.post('/call/invite', postCallInvite);
router.post('/call/accept', postCallAccept);
router.post('/call/reject', postCallReject);
router.post('/call/end', postCallEnd);
router.post('/call/peer', postCallPeer);
router.post('/clinic-admin/rooms', postClinicAdminRooms);

export default router;
