import { Types } from 'mongoose';
import { Appointment } from '../models/Appointment';
import { AppointmentStatus } from '../types/enums';

/** Citas válidas: agendadas, confirmadas o ya realizadas (no canceladas). */
const eligibleAppointmentFilter = {
  status: { $ne: AppointmentStatus.CANCELLED },
};

/**
 * Paciente y médico solo pueden chatear/llamar si comparten al menos una cita
 * (consulta agendada o realizada).
 */
export async function assertDoctorPatientCanCommunicate(
  doctorId: string | Types.ObjectId,
  patientId: string | Types.ObjectId,
): Promise<void> {
  const exists = await Appointment.exists({
    doctorId,
    patientId,
    ...eligibleAppointmentFilter,
  });

  if (!exists) {
    throw new Error(
      'Solo puedes comunicarte con personas con las que tengas una consulta (cita no cancelada).',
    );
  }
}

export async function getEligiblePeerIds(
  userId: string,
  isDoctor: boolean,
): Promise<string[]> {
  const filter = isDoctor
    ? { doctorId: userId, ...eligibleAppointmentFilter }
    : { patientId: userId, ...eligibleAppointmentFilter };

  const ids = isDoctor
    ? await Appointment.distinct('patientId', filter)
    : await Appointment.distinct('doctorId', filter);

  return ids.map((id) => id.toString());
}

export function isEligiblePair(
  doctorId: string,
  patientId: string,
  eligiblePeerIds: string[],
  isDoctor: boolean,
): boolean {
  const peerId = isDoctor ? patientId : doctorId;
  return eligiblePeerIds.includes(peerId);
}

/** ObjectId o documento poblado de User → id string. */
export function userIdFromRef(ref: unknown): string {
  if (ref == null) return '';
  if (typeof ref === 'object' && '_id' in (ref as object)) {
    return String((ref as { _id: unknown })._id);
  }
  return String(ref);
}
