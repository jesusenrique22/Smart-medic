/// Formato de fechas sin depender de `initializeDateFormatting` (compatible web).
class AppDateFormat {
  AppDateFormat._();

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  static String timeHm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String dayMonth(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]}';
  }

  static String dayMonthYear(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  static String listTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return timeHm(dt);
    }
    if (dt.year == now.year) {
      return dayMonth(dt);
    }
    return dayMonthYear(dt);
  }
}
