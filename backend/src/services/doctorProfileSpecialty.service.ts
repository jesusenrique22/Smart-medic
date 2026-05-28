import { Types } from 'mongoose';
import { DoctorProfile } from '../models/DoctorProfile';
import { Specialty } from '../models/Specialty';
import { User } from '../models/User';

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function getDoctorProfileOrThrow(doctorUserId: string) {
  const profile = await DoctorProfile.findOne({ userId: doctorUserId });
  if (!profile) throw new Error('Perfil de médico no encontrado');
  return profile;
}

export async function addSpecialtyToDoctorProfile(
  doctorUserId: string,
  specialtyId: string,
) {
  const specialty = await Specialty.findById(specialtyId);
  if (!specialty) throw new Error('Especialidad no encontrada');

  const profile = await getDoctorProfileOrThrow(doctorUserId);
  const sid = new Types.ObjectId(specialtyId);

  if (profile.specialtyIds.some((id) => id.equals(sid))) {
    throw new Error('Ya tienes esta especialidad en tu perfil');
  }

  profile.specialtyIds.push(sid);
  if (
    !profile.specialtyConsultationDurations.some((entry) =>
      entry.specialtyId.equals(sid),
    )
  ) {
    profile.specialtyConsultationDurations.push({
      specialtyId: sid,
      durationMinutes: profile.defaultConsultationMinutes ?? 30,
    });
  }

  await profile.save();
  return DoctorProfile.findById(profile.id)
    .populate('specialtyIds', 'name description')
    .populate('facilityIds', 'name');
}

export async function createSpecialtyAndAddToDoctorProfile(
  doctorUserId: string,
  rawName: string,
) {
  const name = rawName.trim();
  if (name.length < 2) {
    throw new Error('El nombre de la especialidad debe tener al menos 2 caracteres');
  }
  if (name.length > 80) {
    throw new Error('El nombre de la especialidad es demasiado largo');
  }

  let specialty = await Specialty.findOne({
    name: new RegExp(`^${escapeRegex(name)}$`, 'i'),
  });

  if (!specialty) {
    try {
      specialty = await Specialty.create({ name });
    } catch {
      specialty = await Specialty.findOne({
        name: new RegExp(`^${escapeRegex(name)}$`, 'i'),
      });
      if (!specialty) throw new Error('No se pudo registrar la especialidad');
    }
  }

  return addSpecialtyToDoctorProfile(doctorUserId, specialty.id);
}

export async function removeSpecialtyFromDoctorProfile(
  doctorUserId: string,
  specialtyId: string,
) {
  const profile = await getDoctorProfileOrThrow(doctorUserId);
  const sid = new Types.ObjectId(specialtyId);

  if (!profile.specialtyIds.some((id) => id.equals(sid))) {
    throw new Error('Esta especialidad no está en tu perfil');
  }

  if (profile.specialtyIds.length <= 1) {
    throw new Error('Debes mantener al menos una especialidad en tu perfil');
  }

  profile.specialtyIds = profile.specialtyIds.filter((id) => !id.equals(sid));
  profile.specialtyConsultationDurations = profile.specialtyConsultationDurations.filter(
    (entry) => !entry.specialtyId.equals(sid),
  );

  await profile.save();
  return DoctorProfile.findById(profile.id)
    .populate('specialtyIds', 'name description')
    .populate('facilityIds', 'name');
}

export async function updateSpecialtyConsultationDuration(
  doctorUserId: string,
  specialtyId: string,
  durationMinutes: number,
) {
  if (!Number.isFinite(durationMinutes) || durationMinutes < 15 || durationMinutes > 120) {
    throw new Error('La duración debe estar entre 15 y 120 minutos');
  }

  const profile = await getDoctorProfileOrThrow(doctorUserId);
  const sid = new Types.ObjectId(specialtyId);

  if (!profile.specialtyIds.some((id) => id.equals(sid))) {
    throw new Error('Esta especialidad no está en tu perfil');
  }

  const entry = profile.specialtyConsultationDurations.find((e) =>
    e.specialtyId.equals(sid),
  );
  if (entry) {
    entry.durationMinutes = Math.round(durationMinutes);
  } else {
    profile.specialtyConsultationDurations.push({
      specialtyId: sid,
      durationMinutes: Math.round(durationMinutes),
    });
  }

  await profile.save();
  return DoctorProfile.findById(profile.id)
    .populate('specialtyIds', 'name description')
    .populate('facilityIds', 'name');
}

export async function updateDoctorProfileDetails(
  doctorUserId: string,
  input: {
    name?: string;
    bio?: string;
    licenseNumber?: string;
    profilePic?: string;
    defaultConsultationMinutes?: number;
  },
) {
  const user = await User.findById(doctorUserId);
  if (!user) throw new Error('Usuario no encontrado');

  if (input.name !== undefined) {
    const name = String(input.name).trim();
    if (name.length < 2) throw new Error('El nombre debe tener al menos 2 caracteres');
    user.name = name;
    await user.save();
  }

  if (input.profilePic !== undefined) {
    user.profilePic = String(input.profilePic).trim() || undefined;
    await user.save();
  }

  const profile = await getDoctorProfileOrThrow(doctorUserId);
  const profileUpdate: Record<string, unknown> = {};

  if (input.bio !== undefined) {
    profileUpdate.bio = String(input.bio).trim().slice(0, 600);
  }
  if (input.licenseNumber !== undefined) {
    profileUpdate.licenseNumber = String(input.licenseNumber).trim().slice(0, 60);
  }
  if (input.defaultConsultationMinutes !== undefined) {
    const mins = Number(input.defaultConsultationMinutes);
    if (!Number.isFinite(mins) || mins < 15 || mins > 120) {
      throw new Error('La duración por defecto debe estar entre 15 y 120 minutos');
    }
    profileUpdate.defaultConsultationMinutes = Math.round(mins);
  }

  if (Object.keys(profileUpdate).length > 0) {
    Object.assign(profile, profileUpdate);
    await profile.save();
  }

  const populated = await DoctorProfile.findById(profile.id)
    .populate('specialtyIds', 'name description')
    .populate('facilityIds', 'name');

  const userFresh = await User.findById(doctorUserId).select('-password');
  return { user: userFresh, profile: populated };
}
