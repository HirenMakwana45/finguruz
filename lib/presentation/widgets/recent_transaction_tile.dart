import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';

class RecentTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final String activeCurrencyCode;
  final double convertedAmount;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const RecentTransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.activeCurrencyCode,
    required this.convertedAmount,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final amountColor = isExpense ? AppColors.expense : AppColors.income;
    final prefix = isExpense ? '-' : '+';

    final categoryColor = category != null ? Color(category!.colorValue) : Colors.grey;
    final categoryIcon = category != null
        ? IconData(category!.iconCode, fontFamily: 'MaterialIcons')
        : Icons.category;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            categoryIcon,
            color: categoryColor,
            size: 22,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              category?.name ?? 'Uncategorized',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•  ${CurrencyFormatter.formatShortDate(transaction.date)}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            if (transaction.isRecurring) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.autorenew,
                size: 14,
                color: AppColors.accent,
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$prefix${CurrencyFormatter.format(convertedAmount, currencyCode: activeCurrencyCode)}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (transaction.originalCurrency != activeCurrencyCode)
              Text(
                '${transaction.amount.toStringAsFixed(2)} ${transaction.originalCurrency}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
