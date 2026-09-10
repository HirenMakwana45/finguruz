class AppConstants {
  static const String appName = 'FinGuruz';

  // Currency API (open-source free exchangerate-api endpoint)
  static const String currencyApiBaseUrl = 'https://open.er-api.com/v6/latest/';

  // Supported Currencies with symbols
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
    'CAD': 'CA\$',
    'AUD': 'AU\$',
    'CHF': 'CHF',
  };

  static const String defaultCurrency = 'USD';

  // Recurring intervals
  static const List<String> recurringIntervals = [
    'none',
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];
}
