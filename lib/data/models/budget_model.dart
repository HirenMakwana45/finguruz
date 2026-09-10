class BudgetModel {
  final int? id;
  final int categoryId;
  final double amount;
  final String monthYear; // Format: 'YYYY-MM'

  BudgetModel({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.monthYear,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'monthYear': monthYear,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int,
      amount: (map['amount'] as num).toDouble(),
      monthYear: map['monthYear'] as String,
    );
  }

  BudgetModel copyWith({
    int? id,
    int? categoryId,
    double? amount,
    String? monthYear,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      monthYear: monthYear ?? this.monthYear,
    );
  }
}
