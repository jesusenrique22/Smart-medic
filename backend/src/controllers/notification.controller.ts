import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { prisma } from '../lib/prisma';
import { syncAppointmentReminders } from '../services/notification.service';
import { toApiDoc } from '../utils/apiDoc';

export const listMyNotifications = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  const role = req.user!.role;

  await syncAppointmentReminders(userId, role);

  const notifications = await prisma.notification.findMany({
    where: { userId },
    orderBy: [{ isRead: 'asc' }, { updatedAt: 'desc' }, { createdAt: 'desc' }],
    take: 50,
  });

  res.json(notifications.map(toApiDoc));
};

export const markNotificationRead = async (req: AuthRequest, res: Response) => {
  const existing = await prisma.notification.findFirst({
    where: { id: req.params.id, userId: req.user!.id },
  });
  if (!existing) return res.status(404).json({ error: 'Notificación no encontrada' });

  const notification = await prisma.notification.update({
    where: { id: existing.id },
    data: { isRead: true },
  });
  res.json(toApiDoc(notification));
};

export const markAllNotificationsRead = async (req: AuthRequest, res: Response) => {
  await prisma.notification.updateMany({
    where: { userId: req.user!.id, isRead: false },
    data: { isRead: true },
  });
  res.json({ message: 'Todas marcadas como leídas' });
};

export const getUnreadCount = async (req: AuthRequest, res: Response) => {
  await syncAppointmentReminders(req.user!.id, req.user!.role);
  const count = await prisma.notification.count({
    where: { userId: req.user!.id, isRead: false },
  });
  res.json({ count });
};
