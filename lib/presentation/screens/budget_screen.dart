import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/finance_provider.dart';
import '../widgets/budget_progress_card.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset);
    });
    final monthYearStr = DateFormat('yyyy-MM').format(_currentMonth);
    Provider.of<BudgetProvider>(context, listen: false).setSelectedMonthYear(monthYearStr);
  }

  void _showSetBudgetDialog(BuildContext context, {CategoryModel? initialCategory, double? initialAmount}) {
    final financeProv = Provider.of<FinanceProvider>(context, listen: false);
    final expenseCategories = financeProv.categories.where((c) => c.type == 'expense').toList();

    CategoryModel? selectedCat = initialCategory ?? (expenseCategories.isNotEmpty ? expenseCategories.first : null);
    final amountController = TextEditingController(text: initialAmount != null ? initialAmount.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set Category Budget'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<CategoryModel>(
                    value: selectedCat,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: expenseCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: initialCategory != null
                        ? null
                        : (cat) => setDialogState(() => selectedCat = cat),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monthly Budget Limit',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text.trim());
                    if (selectedCat != null && amount != null && amount > 0) {
                      Provider.of<BudgetProvider>(context, listen: false)
                          .setBudget(selectedCat!.id!, amount);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budget Planning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer3<BudgetProvider, FinanceProvider, CurrencyProvider>(
        builder: (context, budgetProv, financeProv, currencyProv, _) {
          final activeCurrency = currencyProv.baseCurrency;
          double convertFn(double amt, String curr) => currencyProv.convert(amt, curr);

          final statuses = budgetProv.calculateBudgetStatuses(
            financeProv.transactions,
            convertFn: convertFn,
          );

          return Column(
            children: [
              Container(
                color: Theme.of(context).cardTheme.color,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMMM yyyy').format(_currentMonth),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: statuses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              const Text(
                                'No budgets set for this month',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Set category budgets to track and limit your monthly expenses.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: 220,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showSetBudgetDialog(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Set New Budget'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: statuses.length,
                        itemBuilder: (ctx, index) {
                          final status = statuses[index];
                          final category = financeProv.getCategoryById(status.budget.categoryId);

                          return BudgetProgressCard(
                            status: status,
                            category: category,
                            activeCurrencyCode: activeCurrency,
                            onEdit: () {
                              _showSetBudgetDialog(
                                context,
                                initialCategory: category,
                                initialAmount: status.budget.amount,
                              );
                            },
                            onDelete: () {
                              if (status.budget.id != null) {
                                budgetProv.deleteBudget(status.budget.id!);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSetBudgetDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Set Budget'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
