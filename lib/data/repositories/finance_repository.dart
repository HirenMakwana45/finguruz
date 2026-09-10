import '../../core/database/db_helper.dart';
import '../datasources/currency_api_datasource.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/exchange_rates_model.dart';
import '../models/transaction_model.dart';

class FinanceRepository {
  final DBHelper dbHelper;
  final CurrencyApiDatasource apiDatasource;

  FinanceRepository({
    DBHelper? dbHelper,
    CurrencyApiDatasource? apiDatasource,
  })  : dbHelper = dbHelper ?? DBHelper.instance,
        apiDatasource = apiDatasource ?? CurrencyApiDatasource();

  // Transactions
  Future<List<TransactionModel>> getTransactions() => dbHelper.getTransactions();
  Future<int> addTransaction(TransactionModel transaction) => dbHelper.insertTransaction(transaction);
  Future<int> updateTransaction(TransactionModel transaction) => dbHelper.updateTransaction(transaction);
  Future<int> deleteTransaction(int id) => dbHelper.deleteTransaction(id);

  // Categories
  Future<List<CategoryModel>> getCategories() => dbHelper.getCategories();
  Future<int> addCategory(CategoryModel category) => dbHelper.insertCategory(category);

  // Budgets
  Future<List<BudgetModel>> getBudgetsForMonth(String monthYear) => dbHelper.getBudgetsForMonth(monthYear);
  Future<int> saveBudget(BudgetModel budget) => dbHelper.insertOrUpdateBudget(budget);
  Future<int> deleteBudget(int id) => dbHelper.deleteBudget(id);

  // Exchange Rates
  Future<ExchangeRatesModel> getExchangeRates({String baseCurrency = 'USD'}) {
    return apiDatasource.getExchangeRates(baseCurrency: baseCurrency);
  }
}
