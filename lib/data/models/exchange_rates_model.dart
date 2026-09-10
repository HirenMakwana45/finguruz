import 'dart:convert';

class ExchangeRatesModel {
  final String baseCurrency;
  final Map<String, double> rates;
  final String lastFetchedDate; // YYYY-MM-DD

  ExchangeRatesModel({
    required this.baseCurrency,
    required this.rates,
    required this.lastFetchedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'baseCurrency': baseCurrency,
      'ratesJson': jsonEncode(rates),
      'lastFetchedDate': lastFetchedDate,
    };
  }

  factory ExchangeRatesModel.fromMap(Map<String, dynamic> map) {
    final ratesRaw = jsonDecode(map['ratesJson'] as String) as Map<String, dynamic>;
    final rates = ratesRaw.map((key, value) => MapEntry(key, (value as num).toDouble()));

    return ExchangeRatesModel(
      baseCurrency: map['baseCurrency'] as String,
      rates: rates,
      lastFetchedDate: map['lastFetchedDate'] as String,
    );
  }

  factory ExchangeRatesModel.fromJson(Map<String, dynamic> json, String baseCurrency, String dateStr) {
    Map<String, double> parsedRates = {};
    if (json.containsKey('rates') && json['rates'] is Map) {
      final Map<String, dynamic> rawRates = json['rates'];
      rawRates.forEach((key, value) {
        if (value is num) {
          parsedRates[key] = value.toDouble();
        }
      });
    }
    return ExchangeRatesModel(
      baseCurrency: baseCurrency,
      rates: parsedRates,
      lastFetchedDate: dateStr,
    );
  }

  double convertAmount(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;

    final double fromRate = rates[fromCurrency] ?? 1.0;
    final double toRate = rates[toCurrency] ?? 1.0;

    if (fromRate == 0) return amount;

    return (amount / fromRate) * toRate;
  }
}
