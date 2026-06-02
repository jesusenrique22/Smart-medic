import dotenv from 'dotenv';
import path from 'path';

// Debe ejecutarse antes de leer process.env en otros módulos.
dotenv.config({ path: path.join(__dirname, '..', '.env') });

export const config = {
  port: Number(process.env.PORT) || 3001,
  jwtSecret: process.env.JWT_SECRET || 'vita-os-super-secret',
  backendUrl: process.env.BACKEND_URL || 'http://localhost:3000',
  internalSecret: process.env.INTERNAL_REALTIME_SECRET || 'smart-medic-internal-dev',
};
