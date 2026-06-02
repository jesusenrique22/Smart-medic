import { Request, Response, NextFunction } from 'express';

const INTERNAL_SECRET =
  process.env.INTERNAL_REALTIME_SECRET || 'smart-medic-internal-dev';

export function requireInternalRealtimeAuth(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  const key = req.header('X-Internal-Key');
  if (!key || key !== INTERNAL_SECRET) {
    res.status(401).json({ error: 'No autorizado (internal)' });
    return;
  }
  next();
}
