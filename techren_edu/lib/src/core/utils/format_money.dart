/// Uzbekistan so'm — never USD `$`.
String formatUzs(num amount) {
  final n = amount.round();
  final sign = n < 0 ? '-' : '';
  final digits = n.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return "$sign$buffer so'm";
}
