import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import { connectDatabase, disconnectDatabase, prisma } from '../config/db';
import {
  AppointmentStatus,
  AppointmentType,
  DayOfWeek,
  PharmacyOrderStatus,
  UserRole,
} from '../types/enums';

dotenv.config();

async function clearDatabase() {
  await prisma.$transaction([
    prisma.chatMessage.deleteMany(),
    prisma.notification.deleteMany(),
    prisma.pharmacyOrder.deleteMany(),
    prisma.medicalHistoryEntry.deleteMany(),
    prisma.patientWeightControl.deleteMany(),
    prisma.chatConversation.deleteMany(),
    prisma.appointment.deleteMany(),
    prisma.clinicInvitation.deleteMany(),
    prisma.doctorWorkSchedule.deleteMany(),
    prisma.doctorProfileSpecialty.deleteMany(),
    prisma.doctorProfileFacility.deleteMany(),
    prisma.doctorSpecialtyDuration.deleteMany(),
    prisma.doctorProfile.deleteMany(),
    prisma.patientProfile.deleteMany(),
    prisma.medicalHistory.deleteMany(),
    prisma.pharmacyProduct.deleteMany(),
    prisma.user.deleteMany(),
    prisma.specialty.deleteMany(),
    prisma.medicalFacility.deleteMany(),
    prisma.pharmacy.deleteMany(),
    prisma.laboratory.deleteMany(),
  ]);
}

async function seed() {
  await connectDatabase();
  await clearDatabase();

  const password = await bcrypt.hash('password', 10);

  const specialties = await Promise.all([
    prisma.specialty.create({
      data: { name: 'Cardiología', description: 'Enfermedades del corazón' },
    }),
    prisma.specialty.create({
      data: { name: 'Medicina General', description: 'Atención primaria' },
    }),
    prisma.specialty.create({
      data: { name: 'Dermatología', description: 'Piel y anexos' },
    }),
    prisma.specialty.create({
      data: { name: 'Pediatría', description: 'Salud infantil' },
    }),
  ]);

  const facilities = await Promise.all([
    prisma.medicalFacility.create({
      data: {
        name: 'Clínica Metropolitana',
        type: 'CLINIC',
        address: 'Av. Principal, Caracas',
        city: 'Caracas',
      },
    }),
    prisma.medicalFacility.create({
      data: {
        name: 'Hospital Central',
        type: 'HOSPITAL',
        address: 'Centro Médico, Caracas',
        city: 'Caracas',
      },
    }),
    prisma.medicalFacility.create({
      data: {
        name: 'Consultorio Norte',
        type: 'CONSULTORY',
        address: 'Zona Norte, Valencia',
        city: 'Valencia',
      },
    }),
    prisma.medicalFacility.create({
      data: {
        name: 'Clínica San José',
        type: 'CLINIC',
        address: 'Los Palos Grandes, Caracas',
        city: 'Caracas',
      },
    }),
  ]);

  const superAdmin = await prisma.user.create({
    data: {
      email: 'admin@vita.com',
      password,
      name: 'Super Admin VITA',
      role: UserRole.SUPER_ADMIN,
      phone: '+58 412-000-0001',
    },
  });

  const pharmacies = await Promise.all([
    prisma.pharmacy.create({
      data: {
        name: 'FarmaVita Central',
        address: 'Av. Libertador #123, Caracas',
        logoUrl:
          'https://images.unsplash.com/photo-1586015555751-63bb77f4322a?auto=format&fit=crop&q=80&w=100',
      },
    }),
    prisma.pharmacy.create({
      data: {
        name: 'EcoMedic Express',
        address: 'Calle 50 con Calle 72, Panamá',
        logoUrl:
          'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=100',
      },
    }),
  ]);

  const clinicAdmin = await prisma.user.create({
    data: {
      email: 'clinic.admin@vita.com',
      password,
      name: 'Admin Clínica Metropolitana',
      role: UserRole.CLINIC_ADMIN,
      phone: '+58 412-000-0002',
      managedFacilityId: facilities[0].id,
      createdById: superAdmin.id,
    },
  });

  const pharmacyAdmin = await prisma.user.create({
    data: {
      email: 'pharmacy.admin@vita.com',
      password,
      name: 'Admin FarmaVita',
      role: UserRole.PHARMACY_ADMIN,
      phone: '+58 412-000-0003',
      pharmacyId: pharmacies[0].id,
      createdById: superAdmin.id,
    },
  });

  await prisma.user.create({
    data: {
      email: 'farmacista@vita.com',
      password,
      name: 'Ana Farmacéutica',
      role: UserRole.PHARMACIST,
      phone: '+58 412-000-0004',
      pharmacyId: pharmacies[0].id,
      createdById: pharmacyAdmin.id,
    },
  });

  await prisma.user.create({
    data: {
      email: 'cajero@vita.com',
      password,
      name: 'Luis Cajero',
      role: UserRole.PHARMACY_CASHIER,
      phone: '+58 412-000-0005',
      pharmacyId: pharmacies[0].id,
      createdById: pharmacyAdmin.id,
    },
  });

  const laboratories = await Promise.all([
    prisma.laboratory.create({
      data: {
        name: 'BioLab Central',
        address: 'Av. Principal, Caracas',
        logoUrl:
          'https://images.unsplash.com/photo-1579152276508-2d29944ef71d?auto=format&fit=crop&q=80&w=100',
      },
    }),
    prisma.laboratory.create({
      data: {
        name: 'Lab Diagnóstico VITA',
        address: 'Centro Médico, Caracas',
      },
    }),
  ]);

  await prisma.user.create({
    data: {
      email: 'lab@tech.com',
      password,
      name: 'Técnico Laboratorio VITA',
      role: UserRole.LAB_TECH,
      phone: '+58 412-000-0006',
      laboratoryId: laboratories[0].id,
      createdById: superAdmin.id,
    },
  });

  const products = await Promise.all([
    prisma.pharmacyProduct.create({
      data: {
        pharmacyId: pharmacies[0].id,
        name: 'Amoxicilina 500mg',
        brand: 'Genfar',
        category: 'Antibióticos',
        price: 12.5,
        stock: 80,
      },
    }),
    prisma.pharmacyProduct.create({
      data: {
        pharmacyId: pharmacies[0].id,
        name: 'Ibuprofeno 400mg',
        brand: 'MK',
        category: 'Analgesicos',
        price: 8.0,
        stock: 120,
      },
    }),
    prisma.pharmacyProduct.create({
      data: {
        pharmacyId: pharmacies[1].id,
        name: 'Losartán 50mg',
        brand: 'La Santé',
        category: 'Cardiovascular',
        price: 15.0,
        stock: 45,
      },
    }),
  ]);

  await prisma.pharmacyOrder.createMany({
    data: [
      {
        pharmacyId: pharmacies[0].id,
        productId: products[0].id,
        productName: products[0].name,
        quantity: 2,
        total: 25,
        status: PharmacyOrderStatus.COMPLETED,
      },
      {
        pharmacyId: pharmacies[0].id,
        productId: products[1].id,
        productName: products[1].name,
        quantity: 1,
        total: 8,
        status: PharmacyOrderStatus.PENDING,
      },
    ],
  });

  const patient = await prisma.user.create({
    data: {
      email: 'juan@patient.com',
      password,
      name: 'Juan Pérez',
      role: UserRole.PATIENT,
      phone: '+58 412-555-0198',
      profilePic: 'https://i.pravatar.cc/150?img=1',
    },
  });

  await prisma.patientProfile.create({
    data: {
      userId: patient.id,
      fullName: 'Juan Pérez',
      email: patient.email,
      phone: '+58 412-555-0198',
      documentId: 'V-12345678',
      birthDate: '1990-04-12',
      address: 'Av. Libertador, Caracas',
      emergencyContactName: 'María Pérez',
      emergencyContactPhone: '+58 414-555-0142',
      bloodType: 'O+',
      allergies: 'Penicilina',
      chronicConditions: 'Hipertensión controlada',
      currentMedications: 'Losartán 50mg diario',
      surgeries: 'Apendicectomía 2014',
      weightKg: '78',
      heightCm: '176',
      insuranceProvider: 'Seguros Mercantil',
      policyNumber: 'MC-2024-889900',
    },
  });

  const history = await prisma.medicalHistory.create({
    data: {
      patientId: patient.id,
      bloodType: 'O+',
      allergies: 'Penicilina',
      chronicConditions: 'Hipertensión controlada',
      currentMedications: 'Losartán 50mg diario',
      surgeries: 'Apendicectomía 2014',
      weightKg: '78',
      heightCm: '176',
    },
  });

  await prisma.medicalHistoryEntry.create({
    data: {
      medicalHistoryId: history.id,
      date: new Date('2025-11-10'),
      title: 'Control de presión',
      description: 'Presión arterial dentro de rango normal.',
      diagnosis: 'Hipertensión controlada',
      treatment: 'Continuar Losartán 50mg',
    },
  });

  const doctor = await prisma.user.create({
    data: {
      email: 'maria@doctor.com',
      password,
      name: 'Dra. María Gómez',
      role: UserRole.DOCTOR,
      phone: '+58 414-555-0200',
      profilePic: 'https://i.pravatar.cc/150?img=2',
    },
  });

  const doctorProfile = await prisma.doctorProfile.create({
    data: {
      userId: doctor.id,
      documentId: 'V-87654321',
      licenseNumber: 'MED-45821',
      bio: 'Cardióloga con 12 años de experiencia',
      rating: 4.9,
      consultationPriceOnline: 25,
      consultationPricePresential: 45,
      specialties: {
        create: [
          { specialtyId: specialties[0].id },
          { specialtyId: specialties[1].id },
        ],
      },
      facilities: {
        create: [{ facilityId: facilities[0].id }, { facilityId: facilities[1].id }],
      },
      specialtyDurations: {
        create: [
          { specialtyId: specialties[0].id, durationMinutes: 60 },
          { specialtyId: specialties[1].id, durationMinutes: 30 },
        ],
      },
    },
  });

  const weekdays = [
    DayOfWeek.MONDAY,
    DayOfWeek.TUESDAY,
    DayOfWeek.WEDNESDAY,
    DayOfWeek.THURSDAY,
    DayOfWeek.FRIDAY,
    DayOfWeek.SATURDAY,
  ];

  await prisma.doctorWorkSchedule.createMany({
    data: weekdays.flatMap((day) => [
      {
        doctorId: doctor.id,
        facilityId: facilities[0].id,
        dayOfWeek: day,
        startTime: '08:00',
        endTime: '12:00',
      },
      {
        doctorId: doctor.id,
        facilityId: facilities[1].id,
        dayOfWeek: day,
        startTime: '14:00',
        endTime: '18:00',
      },
    ]),
  });

  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(10, 30, 0, 0);

  await prisma.appointment.createMany({
    data: [
      {
        patientId: patient.id,
        doctorId: doctor.id,
        facilityId: facilities[1].id,
        specialtyId: specialties[0].id,
        dateTime: tomorrow,
        status: AppointmentStatus.PENDING,
        type: AppointmentType.PRESENTIAL,
        reason: 'Control cardiológico',
        price: 45,
        durationMinutes: 60,
      },
      {
        patientId: patient.id,
        doctorId: doctor.id,
        specialtyId: specialties[0].id,
        dateTime: new Date(tomorrow.getTime() + 2 * 60 * 60 * 1000),
        status: AppointmentStatus.CONFIRMED,
        type: AppointmentType.ONLINE,
        reason: 'Seguimiento telemedicina',
        price: 25,
        durationMinutes: 60,
      },
    ],
  });

  await prisma.chatConversation.create({
    data: {
      doctorId: doctor.id,
      patientId: patient.id,
      lastMessage: 'Buenos días doctor, tengo una consulta sobre mi medicación.',
      lastMessageAt: new Date(),
      lastChatMessage: 'Buenos días doctor, tengo una consulta sobre mi medicación.',
      lastChatMessageAt: new Date(),
    },
  });

  console.log('Seed completado (PostgreSQL):');
  console.log(`  Super Admin:    ${superAdmin.email} / password`);
  console.log(`  Admin Clínica:  ${clinicAdmin.email} / password`);
  console.log(`  Admin Farmacia: ${pharmacyAdmin.email} / password`);
  console.log(`  Farmacéutico:   farmacista@vita.com / password`);
  console.log(`  Cajero:         cajero@vita.com / password`);
  console.log(`  Paciente: ${patient.email} / password`);
  console.log(`  Doctor:  ${doctor.email} / password`);
  console.log(`  Especialidades: ${specialties.length}`);
  console.log(`  Sedes: ${facilities.length}`);
  console.log(`  Perfil doctor: ${doctorProfile.id}`);

  await disconnectDatabase();
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
