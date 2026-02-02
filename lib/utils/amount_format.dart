String formatAmount(num value, {int decimalDigits = 2}) {
  if (value.isNaN || value.isInfinite) return '0.00';
  final sign = value < 0 ? '-' : '';
  final absValue = value.abs();
  final parts = absValue.toStringAsFixed(decimalDigits).split('.');
  final intPart = parts[0];
  final decPart = parts[1];
  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(intPart[i]);
  }
  return '$sign${buffer.toString()}.$decPart';
}

/// Montant formaté avec symbole devise (ex. "12 000.34 CNY").
String formatAmountWithSymbol(num value, String symbol,
    {int decimalDigits = 2}) {
  return '${formatAmount(value, decimalDigits: decimalDigits)} $symbol';
}
