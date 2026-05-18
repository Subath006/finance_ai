import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  return NumberFormat('#,##0.00').format(amount);
}

String formatCurrencyWhole(double amount) {
  return NumberFormat('#,##0').format(amount);
}

String stripCommas(String text) {
  return text.replaceAll(',', '');
}

/// A [TextInputFormatter] that adds comma separators as the user types.
/// Supports decimals — commas are only applied to the integer part.
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final raw = newValue.text.replaceAll(',', '');

    if (!RegExp(r'^\d*\.?\d*$').hasMatch(raw)) {
      return oldValue;
    }

    final parts = raw.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    String formatted = '';
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      formatted = intPart[i] + formatted;
      count++;
      if (count % 3 == 0 && i > 0) {
        formatted = ',$formatted';
      }
    }
    formatted += decPart;

    final oldCursor = newValue.selection.baseOffset;
    final rawBeforeCursor = newValue.text
        .substring(0, oldCursor.clamp(0, newValue.text.length))
        .replaceAll(',', '');
    int newCursor = 0;
    int rawCount = 0;
    for (
      int i = 0;
      i < formatted.length && rawCount < rawBeforeCursor.length;
      i++
    ) {
      if (formatted[i] == ',') {
        newCursor++;
      } else {
        newCursor++;
        rawCount++;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursor.clamp(0, formatted.length),
      ),
    );
  }
}
