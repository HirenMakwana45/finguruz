import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

class CurrencyFormatter {
  static String format(double amount, {String currencyCode = 'USD', bool showSymbol = true}) {
    final symbol = showSymbol ? (AppConstants.currencySymbols[currencyCode] ?? '\$') : '';
    final formatter = NumberFormat.currency(
      symbol: symbol.isNotEmpty ? '$symbol ' : '',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }
}
