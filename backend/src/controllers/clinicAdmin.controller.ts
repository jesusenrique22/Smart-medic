import { Response } from 'express';
import bcrypt from 'bcryptjs';
import { AuthRequest } from '../middleware/auth';
import { prisma } from '../lib/prisma';
import { createDoctorByAdmin } from '../services/adminDoctor.service';
import {
  listDoctorsForFacility,
  listDoctorsNotInFacility,
  unassignDoctorFromFacility,
} from '../services/clinicDoctorAssignment.service';
import { ClinicInvitationStatus } from '../models/ClinicInvitation';
import { inviteDoctorToFacility } from '../services/clinicInvitation.service';
import { emitToFacility } from '../socket/realtimeGatewayClient';
import { sanitizeUser } from '../utils/sanitizeUser';
import { toApiDoc } from '../utils/apiDoc';

async function getClinicAdminContext(userId: string) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user?.managedFacilityId) {
    return null;
  }
  const facility = await prisma.medicalFacility.findUnique({
    where: { id: user.managedFacilityId },
  });
  return { user, facility };
}

export const getMyContext = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx) {
    return res.status(400).json({ error: 'Administrador de clínica sin sede asignada' });
  }
  res.json({
    user: sanitizeUser(ctx.user),
    facility: ctx.facility ? toApiDoc(ctx.facility) : null,
  });
};

export const getDashboard = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }

  const facilityId = ctx.facility.id;
  const doctors = await listDoctorsForFacility(facilityId);
  const doctorUserIds = doctors.map((d) => d.user?.id).filter((id): id is string => Boolean(id));

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  let appointmentsToday = 0;
  if (doctorUserIds.length) {
    appointmentsToday = await prisma.appointment.count({
      where: {
        doctorId: { in: doctorUserIds },
        dateTime: { gte: today, lt: tomorrow },
        status: { not: 'CANCELLED' },
      },
    });
  }

  const pendingInvitations = await prisma.clinicInvitation.findMany({
    where: { facilityId: ctx.facility.id, status: ClinicInvitationStatus.PENDING },
    include: {
      doctor: { select: { id: true, name: true, email: true, phone: true, profilePic: true } },
    },
    orderBy: { createdAt: 'desc' },
  });

  res.json({
    facility: toApiDoc(ctx.facility),
    stats: {
      doctorsCount: doctors.length,
      appointmentsToday,
      pendingInvitationsCount: pendingInvitations.length,
    },
    doctors,
    pendingInvitations: pendingInvitations.map((inv) => ({
      id: inv.id,
      doctor: inv.doctor ? toApiDoc(inv.doctor) : null,
      createdAt: inv.createdAt,
    })),
  });
};

export const listDoctors = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }
  const doctors = await listDoctorsForFacility(ctx.facility.id);
  res.json(doctors);
};

export const listAssignableDoctors = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }
  const search = req.query.search as string | undefined;
  const doctors = await listDoctorsNotInFacility(ctx.facility.id, search);
  res.json(doctors);
};

export const assignDoctor = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }

  const { doctorUserId } = req.body;
  if (!doctorUserId) {
    return res.status(400).json({ error: 'doctorUserId es obligatorio' });
  }

  try {
    const result = await inviteDoctorToFacility(doctorUserId, ctx.facility.id, req.user!.id);
    res.status(200).json({
      invitationId: result.invitation.id,
      facilityName: result.facility.name,
      doctorName: result.doctor.name,
      message: `Invitación enviada a ${result.doctor.name}. El médico debe aceptarla para unirse a ${result.facility.name}.`,
    });
  } catch (e) {
    const message = (e as Error).message;
    res.status(400).json({ error: message });
  }
};

export const unassignDoctor = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }

  const { doctorUserId } = req.params;
  if (!doctorUserId) {
    return res.status(400).json({ error: 'doctorUserId es obligatorio' });
  }

  try {
    const result = await unassignDoctorFromFacility(doctorUserId, ctx.facility.id);
    emitToFacility(ctx.facility.id, 'clinic:roster:updated', {
      reason: 'doctor_unassigned',
      facilityId: ctx.facility.id,
      doctorUserId,
    });
    res.json({
      profile: result.profile,
      message: 'Médico desvinculado de la clínica',
    });
  } catch (e) {
    res.status(400).json({ error: (e as Error).message });
  }
};

export const createDoctor = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }

  const { name, email, phone, documentId, specialtyId } = req.body;
  if (!name?.trim() || !email?.trim() || !phone?.trim() || !documentId?.trim()) {
    return res.status(400).json({
      error: 'Nombre, correo, teléfono y cédula son obligatorios',
    });
  }
  if (!specialtyId) {
    return res.status(400).json({ error: 'La especialidad es obligatoria' });
  }

  const facilityId = ctx.facility.id;

  try {
    const result = await createDoctorByAdmin({
      name,
      email,
      phone,
      documentId,
      specialtyId,
      facilityIds: [facilityId],
      allowedFacilityIds: [facilityId],
    });
    res.status(201).json(result);
  } catch (e) {
    const message = (e as Error).message;
    res.status(message.includes('ya está') ? 409 : 400).json({ error: message });
  }
};

export const changeMyPassword = async (req: AuthRequest, res: Response) => {
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    return res.status(400).json({ error: 'Contraseña actual y nueva son obligatorias' });
  }
  if (String(newPassword).length < 6) {
    return res.status(400).json({ error: 'La nueva contraseña debe tener al menos 6 caracteres' });
  }

  const user = await prisma.user.findUnique({ where: { id: req.user!.id } });
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });

  const isMatch = await bcrypt.compare(currentPassword, user.password);
  if (!isMatch) {
    return res.status(400).json({ error: 'La contraseña actual no es correcta' });
  }

  await prisma.user.update({
    where: { id: user.id },
    data: { password: await bcrypt.hash(String(newPassword), 10) },
  });

  res.json({ message: 'Contraseña actualizada correctamente' });
};
