import 'package:flutter/material.dart';

import '../data/models/category_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/finance_repository.dart';

class FinanceProvider extends ChangeNotifier {
  final FinanceRepository repository;

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int? _selectedCategoryFilter;
  String _selectedTypeFilter = 'all'; // 'all', 'expense', 'income'

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryFilter => _selectedCategoryFilter;
  String get selectedTypeFilter => _selectedTypeFilter;

  FinanceProvider({FinanceRepository? repository})
      : repository = repository ?? FinanceRepository() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await loadCategories();
    await loadTransactions();
    await _checkAndProcessRecurringTransactions();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await repository.getCategories();
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _transactions = await repository.getTransactions();
    notifyListeners();
  }

  /// Automatic processing of recurring expenses/income
  Future<void> _checkAndProcessRecurringTransactions() async {
    final now = DateTime.now();
    bool hasNewTransactions = false;

    for (var tx in _transactions) {
      if (!tx.isRecurring || tx.recurringInterval == 'none') continue;

      DateTime lastDate = tx.lastProcessedDate ?? tx.date;
      DateTime nextDueDate = _calculateNextDueDate(lastDate, tx.recurringInterval);

      while (nextDueDate.isBefore(now) || isSameDay(nextDueDate, now)) {
        final newTx = TransactionModel(
          title: '${tx.title} (Auto)',
          amount: tx.amount,
          date: nextDueDate,
          categoryId: tx.categoryId,
          type: tx.type,
          isRecurring: false,
          note: 'Recurring ${tx.recurringInterval} from ${tx.title}',
          originalCurrency: tx.originalCurrency,
        );

        await repository.addTransaction(newTx);

        final updatedOriginal = tx.copyWith(lastProcessedDate: nextDueDate);
        await repository.updateTransaction(updatedOriginal);

        lastDate = nextDueDate;
        nextDueDate = _calculateNextDueDate(lastDate, tx.recurringInterval);
        hasNewTransactions = true;
      }
    }

    if (hasNewTransactions) {
      _transactions = await repository.getTransactions();
    }
  }

  DateTime _calculateNextDueDate(DateTime from, String interval) {
    switch (interval) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day);
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day);
      default:
        return from.add(const Duration(days: 30));
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await repository.addTransaction(transaction);
    await loadTransactions();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await repository.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await repository.deleteTransaction(id);
    await loadTransactions();
  }

  Future<void> addCategory(CategoryModel category) async {
    await repository.addCategory(category);
    await loadCategories();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryFilter = categoryId;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  List<TransactionModel> get filteredTransactions {
    return _transactions.where((tx) {
      final matchesSearch = tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (tx.note != null && tx.note!.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesCategory = _selectedCategoryFilter == null || tx.categoryId == _selectedCategoryFilter;

      final matchesType = _selectedTypeFilter == 'all' || tx.type == _selectedTypeFilter;

      return matchesSearch && matchesCategory && matchesType;
    }).toList();
  }

  // Summary Metrics
  double getTotalIncome({double Function(double amount, String currency)? convertFn}) {
    double total = 0.0;
    for (var tx in _transactions) {
      if (tx.type == 'income') {
        final amount = convertFn != null ? convertFn(tx.amount, tx.originalCurrency) : tx.amount;
        total += amount;
      }
    }
    return total;
  }

  double getTotalExpense({double Function(double amount, String currency)? convertFn}) {
    double total = 0.0;
    for (var tx in _transactions) {
      if (tx.type == 'expense') {
        final amount = convertFn != null ? convertFn(tx.amount, tx.originalCurrency) : tx.amount;
        total += amount;
      }
    }
    return total;
  }

  double getCurrentBalance({double Function(double amount, String currency)? convertFn}) {
    return getTotalIncome(convertFn: convertFn) - getTotalExpense(convertFn: convertFn);
  }

  CategoryModel? getCategoryById(int id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (_) {
      return null;
    }
  }
}
