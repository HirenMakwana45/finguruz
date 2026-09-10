class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final int categoryId;
  final String type; // 'expense' or 'income'
  final bool isRecurring;
  final String recurringInterval; // 'none', 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime? lastProcessedDate;
  final String? note;
  final String originalCurrency;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.type,
    this.isRecurring = false,
    this.recurringInterval = 'none',
    this.lastProcessedDate,
    this.note,
    this.originalCurrency = 'USD',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'type': type,
      'isRecurring': isRecurring ? 1 : 0,
      'recurringInterval': recurringInterval,
      'lastProcessedDate': lastProcessedDate?.toIso8601String(),
      'note': note,
      'originalCurrency': originalCurrency,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['categoryId'] as int,
      type: map['type'] as String,
      isRecurring: (map['isRecurring'] as int) == 1,
      recurringInterval: map['recurringInterval'] as String? ?? 'none',
      lastProcessedDate: map['lastProcessedDate'] != null
          ? DateTime.parse(map['lastProcessedDate'] as String)
          : null,
      note: map['note'] as String?,
      originalCurrency: map['originalCurrency'] as String? ?? 'USD',
    );
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    int? categoryId,
    String? type,
    bool? isRecurring,
    String? recurringInterval,
    DateTime? lastProcessedDate,
    String? note,
    String? originalCurrency,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
      note: note ?? this.note,
      originalCurrency: originalCurrency ?? this.originalCurrency,
    );
  }
}
