import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/category_model.dart';
import '../../providers/budget_provider.dart';

class BudgetProgressCard extends StatelessWidget {
  final CategoryBudgetStatus status;
  final CategoryModel? category;
  final String activeCurrencyCode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BudgetProgressCard({
    super.key,
    required this.status,
    required this.category,
    required this.activeCurrencyCode,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final double budgetAmount = status.budget.amount;
    final double spentAmount = status.spentAmount;
    final double remaining = budgetAmount - spentAmount;
    final double progressClamped = status.progress.clamp(0.0, 1.0);

    Color progressColor;
    String statusText;

    switch (status.status) {
      case BudgetStatus.exceeded:
        progressColor = AppColors.expense;
        statusText = 'Exceeded by ${CurrencyFormatter.format(spentAmount - budgetAmount, currencyCode: activeCurrencyCode)}';
        break;
      case BudgetStatus.warning:
        progressColor = AppColors.warning;
        statusText = '${CurrencyFormatter.format(remaining, currencyCode: activeCurrencyCode)} remaining (Nearing limit)';
        break;
      case BudgetStatus.normal:
        progressColor = AppColors.primary;
        statusText = '${CurrencyFormatter.format(remaining, currencyCode: activeCurrencyCode)} remaining';
        break;
    }

    final categoryColor = category != null ? Color(category!.colorValue) : Colors.grey;
    final categoryIcon = category != null
        ? IconData(category!.iconCode, fontFamily: 'MaterialIcons')
        : Icons.category;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status.status == BudgetStatus.exceeded
              ? AppColors.expense.withOpacity(0.5)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Category',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: status.status == BudgetStatus.exceeded
                            ? AppColors.expense
                            : status.status == BudgetStatus.warning
                                ? AppColors.warning
                                : Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontWeight: status.status != BudgetStatus.normal ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Budget'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppColors.expense),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.expense)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressClamped,
              minHeight: 10,
              backgroundColor: progressColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyFormatter.format(spentAmount, currencyCode: activeCurrencyCode)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                'Limit: ${CurrencyFormatter.format(budgetAmount, currencyCode: activeCurrencyCode)}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
