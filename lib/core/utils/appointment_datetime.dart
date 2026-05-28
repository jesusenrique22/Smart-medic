// Fechas/horas de citas: la API guarda UTC; la UI muestra hora local en formato 12 h (AM/PM).

const _monthsShortEs = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

/// Parsea ISO del backend como instante UTC.
DateTime parseAppointmentDateTime(String raw) {
  final parsed = DateTime.parse(raw);
  return parsed.isUtc ? parsed : parsed.toUtc();
}

/// Envía al API en UTC (ISO 8601).
String appointmentDateTimeToApi(DateTime dateTime) {
  return dateTime.toUtc().toIso8601String();
}

/// Hora local del dispositivo para mostrar en pantalla.
DateTime appointmentDisplayLocal(DateTime dateTime) {
  return dateTime.toLocal();
}

/// Hora en 12 h con AM/PM (ej. "12:00 PM", "9:30 AM").
({int hour12, String minute, String period}) time12Parts(DateTime dateTime) {
  final local = appointmentDisplayLocal(dateTime);
  final period = local.hour >= 12 ? 'PM' : 'AM';
  var hour12 = local.hour % 12;
  if (hour12 == 0) hour12 = 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return (hour12: hour12, minute: minute, period: period);
}

/// Solo hora: "12:00 PM"
String formatTime12h(DateTime dateTime) {
  final p = time12Parts(dateTime);
  return '${p.hour12}:${p.minute} ${p.period}';
}

/// Convierte "HH:mm" en 24 h a "h:mm AM/PM" (horarios de agenda del API).
String formatWallClockTime12h(String hhmm) {
  final parts = hhmm.trim().split(':');
  if (parts.length < 2) return hhmm;
  final hour24 = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  var hour12 = hour24 % 12;
  if (hour12 == 0) hour12 = 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}

/// Ej: "28 May, 12:00 PM"
String formatAppointmentDateTime(DateTime dateTime) {
  final local = appointmentDisplayLocal(dateTime);
  return '${local.day} ${_monthsShortEs[local.month - 1]}, ${formatTime12h(dateTime)}';
}

/// Ej: "28/05/2026 · 12:00 PM"
String formatAppointmentDateTimeLong(DateTime dateTime) {
  final local = appointmentDisplayLocal(dateTime);
  final date =
      '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  return '$date · ${formatTime12h(dateTime)}';
}
