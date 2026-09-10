import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/exchange_rates_model.dart';
import '../../data/models/transaction_model.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finguruz_finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for desktop environments (Windows, Linux, macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        iconCode INTEGER NOT NULL,
        colorValue INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        type TEXT NOT NULL,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        recurringInterval TEXT NOT NULL DEFAULT 'none',
        lastProcessedDate TEXT,
        note TEXT,
        originalCurrency TEXT NOT NULL DEFAULT 'USD',
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        amount REAL NOT NULL,
        monthYear TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_exchange_rates (
        baseCurrency TEXT PRIMARY KEY,
        ratesJson TEXT NOT NULL,
        lastFetchedDate TEXT NOT NULL
      )
    ''');

    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      CategoryModel(name: 'Groceries', iconCode: Icons.shopping_cart.codePoint, colorValue: Colors.green.value, type: 'expense'),
      CategoryModel(name: 'Utilities', iconCode: Icons.flash_on.codePoint, colorValue: Colors.orange.value, type: 'expense'),
      CategoryModel(name: 'Dining Out', iconCode: Icons.restaurant.codePoint, colorValue: Colors.deepOrange.value, type: 'expense'),
      CategoryModel(name: 'Transportation', iconCode: Icons.directions_car.codePoint, colorValue: Colors.blue.value, type: 'expense'),
      CategoryModel(name: 'Entertainment', iconCode: Icons.movie.codePoint, colorValue: Colors.purple.value, type: 'expense'),
      CategoryModel(name: 'Shopping', iconCode: Icons.shopping_bag.codePoint, colorValue: Colors.pink.value, type: 'expense'),
      CategoryModel(name: 'Health', iconCode: Icons.medical_services.codePoint, colorValue: Colors.red.value, type: 'expense'),
      CategoryModel(name: 'Education', iconCode: Icons.school.codePoint, colorValue: Colors.indigo.value, type: 'expense'),
      CategoryModel(name: 'Salary', iconCode: Icons.account_balance_wallet.codePoint, colorValue: Colors.teal.value, type: 'income'),
      CategoryModel(name: 'Freelance', iconCode: Icons.work.codePoint, colorValue: Colors.cyan.value, type: 'income'),
      CategoryModel(name: 'Investment', iconCode: Icons.trending_up.codePoint, colorValue: Colors.lightGreen.value, type: 'income'),
      CategoryModel(name: 'Other', iconCode: Icons.category.codePoint, colorValue: Colors.blueGrey.value, type: 'expense'),
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat.toMap());
    }
  }

  // --- Category Operations ---
  Future<List<CategoryModel>> getCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'id ASC');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  // --- Transaction Operations ---
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Budget Operations ---
  Future<List<BudgetModel>> getBudgetsForMonth(String monthYear) async {
    final db = await instance.database;
    final result = await db.query(
      'budgets',
      where: 'monthYear = ?',
      whereArgs: [monthYear],
    );
    return result.map((json) => BudgetModel.fromMap(json)).toList();
  }

  Future<int> insertOrUpdateBudget(BudgetModel budget) async {
    final db = await instance.database;
    final existing = await db.query(
      'budgets',
      where: 'categoryId = ? AND monthYear = ?',
      whereArgs: [budget.categoryId, budget.monthYear],
    );

    if (existing.isNotEmpty) {
      final existingId = existing.first['id'] as int;
      return await db.update(
        'budgets',
        budget.copyWith(id: existingId).toMap(),
        where: 'id = ?',
        whereArgs: [existingId],
      );
    } else {
      return await db.insert('budgets', budget.toMap());
    }
  }

  Future<int> deleteBudget(int id) async {
    final db = await instance.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // --- Exchange Rates Operations ---
  Future<ExchangeRatesModel?> getCachedExchangeRates(String baseCurrency) async {
    final db = await instance.database;
    final result = await db.query(
      'cached_exchange_rates',
      where: 'baseCurrency = ?',
      whereArgs: [baseCurrency],
    );

    if (result.isNotEmpty) {
      return ExchangeRatesModel.fromMap(result.first);
    }
    return null;
  }

  Future<void> saveExchangeRates(ExchangeRatesModel rates) async {
    final db = await instance.database;
    await db.insert(
      'cached_exchange_rates',
      rates.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
