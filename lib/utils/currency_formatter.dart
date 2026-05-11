import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats a number with comma separators and 2 decimal places.
/// e.g. 12500.5 → "12,500.50"
String formatCurrency(double amount) {
  return NumberFormat('#,##0.00').format(amount);
}

/// Formats a number with comma separators and no decimals.
/// e.g. 12500.5 → "12,501"
String formatCurrencyWhole(double amount) {
  return NumberFormat('#,##0').format(amount);
}

/// Strips commas from a formatted string so it can be parsed as a number.
/// e.g. "12,500.50" → "12500.50"
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
    // Allow empty
    if (newValue.text.isEmpty) return newValue;

    // Strip existing commas to get raw digits
    final raw = newValue.text.replaceAll(',', '');

    // Only allow digits and at most one decimal point
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(raw)) {
      return oldValue;
    }

    // Split integer and decimal parts
    final parts = raw.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    // Format integer part with commas
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

    // Calculate new cursor position
    // Count how many commas are before the cursor in the new string
    final oldCursor = newValue.selection.baseOffset;
    final rawBeforeCursor = newValue.text
        .substring(0, oldCursor.clamp(0, newValue.text.length))
        .replaceAll(',', '');
    int newCursor = 0;
    int rawCount = 0;
    for (int i = 0; i < formatted.length && rawCount < rawBeforeCursor.length; i++) {
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
