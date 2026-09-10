import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/budget_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/finance_repository.dart';

enum BudgetStatus {
  normal,    // < 80%
  warning,   // 80% - 99%
  exceeded,  // >= 100%
}

class CategoryBudgetStatus {
  final BudgetModel budget;
  final double spentAmount;
  final double progress; // 0.0 to 1.0+
  final BudgetStatus status;

  CategoryBudgetStatus({
    required this.budget,
    required this.spentAmount,
    required this.progress,
    required this.status,
  });
}

class BudgetProvider extends ChangeNotifier {
  final FinanceRepository repository;

  List<BudgetModel> _budgets = [];
  String _selectedMonthYear = DateFormat('yyyy-MM').format(DateTime.now());
  bool _isLoading = false;

  List<BudgetModel> get budgets => _budgets;
  String get selectedMonthYear => _selectedMonthYear;
  bool get isLoading => _isLoading;

  BudgetProvider({FinanceRepository? repository})
      : repository = repository ?? FinanceRepository() {
    loadBudgets();
  }

  void setSelectedMonthYear(String monthYear) {
    if (_selectedMonthYear == monthYear) return;
    _selectedMonthYear = monthYear;
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    _isLoading = true;
    notifyListeners();

    _budgets = await repository.getBudgetsForMonth(_selectedMonthYear);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setBudget(int categoryId, double amount) async {
    final budget = BudgetModel(
      categoryId: categoryId,
      amount: amount,
      monthYear: _selectedMonthYear,
    );
    await repository.saveBudget(budget);
    await loadBudgets();
  }

  Future<void> deleteBudget(int id) async {
    await repository.deleteBudget(id);
    await loadBudgets();
  }

  List<CategoryBudgetStatus> calculateBudgetStatuses(
    List<TransactionModel> allTransactions, {
    double Function(double amount, String currency)? convertFn,
  }) {
    List<CategoryBudgetStatus> statuses = [];

    for (var budget in _budgets) {
      double categorySpent = 0.0;
      for (var tx in allTransactions) {
        if (tx.categoryId == budget.categoryId && tx.type == 'expense') {
          final txMonthYear = DateFormat('yyyy-MM').format(tx.date);
          if (txMonthYear == _selectedMonthYear) {
            final convertedAmount = convertFn != null ? convertFn(tx.amount, tx.originalCurrency) : tx.amount;
            categorySpent += convertedAmount;
          }
        }
      }

      final progress = budget.amount > 0 ? (categorySpent / budget.amount) : 0.0;
      BudgetStatus status;

      if (progress >= 1.0) {
        status = BudgetStatus.exceeded;
      } else if (progress >= 0.8) {
        status = BudgetStatus.warning;
      } else {
        status = BudgetStatus.normal;
      }

      statuses.add(
        CategoryBudgetStatus(
          budget: budget,
          spentAmount: categorySpent,
          progress: progress,
          status: status,
        ),
      );
    }

    return statuses;
  }
}
