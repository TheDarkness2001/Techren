/// Academy calendar is always Asia/Tashkent (UTC+5, no DST).
class AcademyTime {
  AcademyTime._();

  static const Duration offset = Duration(hours: 5);

  /// Wall clock in Tashkent (stored as a UTC DateTime whose fields are Tashkent).
  static DateTime now([DateTime? instant]) {
    final utc = (instant ?? DateTime.now()).toUtc();
    return utc.add(offset);
  }

  static int get month => now().month;
  static int get year => now().year;

  static String ymd([DateTime? instant]) {
    final t = now(instant);
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
