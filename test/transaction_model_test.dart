import 'package:finguruz/data/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionModel Unit Tests', () {
    final now = DateTime(2026, 9, 10, 12, 0);

    test('should serialize to Map correctly', () {
      final transaction = TransactionModel(
        id: 1,
        title: 'Groceries',
        amount: 85.50,
        date: now,
        categoryId: 2,
        type: 'expense',
        isRecurring: true,
        recurringInterval: 'monthly',
        note: 'Weekly grocery run',
        originalCurrency: 'USD',
      );

      final map = transaction.toMap();

      expect(map['id'], equals(1));
      expect(map['title'], equals('Groceries'));
      expect(map['amount'], equals(85.50));
      expect(map['date'], equals(now.toIso8601String()));
      expect(map['categoryId'], equals(2));
      expect(map['type'], equals('expense'));
      expect(map['isRecurring'], equals(1));
      expect(map['recurringInterval'], equals('monthly'));
      expect(map['note'], equals('Weekly grocery run'));
      expect(map['originalCurrency'], equals('USD'));
    });

    test('should deserialize from Map correctly', () {
      final map = {
        'id': 10,
        'title': 'Salary',
        'amount': 3500.0,
        'date': now.toIso8601String(),
        'categoryId': 9,
        'type': 'income',
        'isRecurring': 0,
        'recurringInterval': 'none',
        'note': 'Monthly paycheck',
        'originalCurrency': 'EUR',
      };

      final transaction = TransactionModel.fromMap(map);

      expect(transaction.id, equals(10));
      expect(transaction.title, equals('Salary'));
      expect(transaction.amount, equals(3500.0));
      expect(transaction.type, equals('income'));
      expect(transaction.isRecurring, isFalse);
      expect(transaction.originalCurrency, equals('EUR'));
    });
  });
}
