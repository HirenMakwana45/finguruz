import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/exchange_rates_model.dart';
import '../data/repositories/finance_repository.dart';

class CurrencyProvider extends ChangeNotifier {
  final FinanceRepository repository;

  String _baseCurrency = 'USD';
  ExchangeRatesModel? _exchangeRates;
  bool _isLoading = false;

  String get baseCurrency => _baseCurrency;
  ExchangeRatesModel? get exchangeRates => _exchangeRates;
  bool get isLoading => _isLoading;

  CurrencyProvider({FinanceRepository? repository})
      : repository = repository ?? FinanceRepository() {
    _loadUserCurrency();
  }

  Future<void> _loadUserCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _baseCurrency = prefs.getString('baseCurrency') ?? 'USD';
    await fetchRates();
  }

  Future<void> setBaseCurrency(String newCurrency) async {
    if (_baseCurrency == newCurrency) return;
    _baseCurrency = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseCurrency', newCurrency);
    await fetchRates();
  }

  Future<void> fetchRates() async {
    _isLoading = true;
    notifyListeners();

    _exchangeRates = await repository.getExchangeRates(baseCurrency: _baseCurrency);

    _isLoading = false;
    notifyListeners();
  }

  double convert(double amount, String fromCurrency) {
    if (_exchangeRates == null) return amount;
    return _exchangeRates!.convertAmount(amount, fromCurrency, _baseCurrency);
  }
}
