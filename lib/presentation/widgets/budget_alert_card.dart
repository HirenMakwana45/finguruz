import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/budget_provider.dart';

class BudgetAlertCard extends StatelessWidget {
  final List<CategoryBudgetStatus> warningBudgets;
  final String Function(int categoryId) getCategoryName;
  final VoidCallback onViewBudgets;

  const BudgetAlertCard({
    super.key,
    required this.warningBudgets,
    required this.getCategoryName,
    required this.onViewBudgets,
  });

  @override
  Widget build(BuildContext context) {
    if (warningBudgets.isEmpty) return const SizedBox.shrink();

    final hasExceeded = warningBudgets.any((b) => b.status == BudgetStatus.exceeded);
    final bgColor = hasExceeded ? AppColors.expense.withOpacity(0.1) : AppColors.warning.withOpacity(0.1);
    final borderColor = hasExceeded ? AppColors.expense : AppColors.warning;
    final iconColor = hasExceeded ? AppColors.expense : AppColors.warning;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasExceeded ? Icons.error_outline : Icons.warning_amber_rounded,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasExceeded ? 'Budget Limit Exceeded!' : 'Budget Warning',
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewBudgets,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...warningBudgets.map((status) {
            final catName = getCategoryName(status.budget.categoryId);
            final percent = (status.progress * 100).toInt();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '• $catName',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  Text(
                    '$percent% used',
                    style: TextStyle(
                      color: status.status == BudgetStatus.exceeded ? AppColors.expense : AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
