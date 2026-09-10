import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/db_helper.dart';
import '../models/exchange_rates_model.dart';

class CurrencyApiDatasource {
  final DBHelper dbHelper;
  final http.Client httpClient;

  CurrencyApiDatasource({
    DBHelper? dbHelper,
    http.Client? httpClient,
  })  : dbHelper = dbHelper ?? DBHelper.instance,
        httpClient = httpClient ?? http.Client();

  /// Retrieves exchange rates obeying the constraint:
  /// Calls external API AT MOST ONCE per day.
  Future<ExchangeRatesModel> getExchangeRates({String baseCurrency = 'USD'}) async {
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Step 1: Check Local Database Cache
    final cachedRates = await dbHelper.getCachedExchangeRates(baseCurrency);

    // Step 2: If cached rates exist for TODAY, return immediately without API call!
    if (cachedRates != null && cachedRates.lastFetchedDate == todayStr) {
      return cachedRates;
    }

    // Step 3: Make API call
    try {
      final url = Uri.parse('${AppConstants.currencyApiBaseUrl}$baseCurrency');
      final response = await httpClient.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final newRates = ExchangeRatesModel.fromJson(data, baseCurrency, todayStr);

        // Cache for today
        await dbHelper.saveExchangeRates(newRates);
        return newRates;
      }
    } catch (e) {
      // Offline fallback
    }

    // Step 4: Fallback to old cached rates if available
    if (cachedRates != null) {
      return cachedRates;
    }

    // Step 5: Default fallback
    return ExchangeRatesModel(
      baseCurrency: baseCurrency,
      rates: {
        'USD': 1.0,
        'EUR': 0.92,
        'GBP': 0.79,
        'INR': 83.5,
        'JPY': 155.0,
        'CAD': 1.36,
        'AUD': 1.50,
        'CHF': 0.90,
      },
      lastFetchedDate: todayStr,
    );
  }
}
