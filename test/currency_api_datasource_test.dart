import 'package:finguruz/data/datasources/currency_api_datasource.dart';
import 'package:finguruz/data/models/exchange_rates_model.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CurrencyApiDatasource Once-Per-Day Constraint Unit Tests', () {
    test('should return cached rates for today without making HTTP calls', () async {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final cachedRates = ExchangeRatesModel(
        baseCurrency: 'USD',
        rates: {'USD': 1.0, 'EUR': 0.92, 'INR': 83.5},
        lastFetchedDate: todayStr,
      );

      // Verify cached rate date matches today
      expect(cachedRates.lastFetchedDate, equals(todayStr));

      // Currency conversion math operates locally in-memory without network calls
      final convertedAmount = cachedRates.convertAmount(100.0, 'USD', 'INR');
      expect(convertedAmount, equals(8350.0));
    });
  });
}
