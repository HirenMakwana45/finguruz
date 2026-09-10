import 'package:finguruz/data/models/exchange_rates_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExchangeRatesModel Unit Tests', () {
    final ratesModel = ExchangeRatesModel(
      baseCurrency: 'USD',
      rates: {
        'USD': 1.0,
        'EUR': 0.90,
        'INR': 80.0,
        'GBP': 0.80,
      },
      lastFetchedDate: '2026-09-10',
    );

    test('should return same amount when converting between same currency', () {
      final converted = ratesModel.convertAmount(100.0, 'USD', 'USD');
      expect(converted, equals(100.0));
    });

    test('should convert USD to EUR correctly', () {
      final converted = ratesModel.convertAmount(100.0, 'USD', 'EUR');
      expect(converted, equals(90.0));
    });

    test('should convert EUR to INR correctly', () {
      final converted = ratesModel.convertAmount(90.0, 'EUR', 'INR');
      expect(converted, closeTo(8000.0, 0.01));
    });
  });
}
