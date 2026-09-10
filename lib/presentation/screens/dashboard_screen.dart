import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/finance_provider.dart';
import '../widgets/budget_alert_card.dart';
import '../widgets/recent_transaction_tile.dart';
import '../widgets/summary_card.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int index) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back 👋',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.normal,
              ),
            ),
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<CurrencyProvider>(
            builder: (context, currencyProv, _) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currencyProv.baseCurrency,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    isDense: true,
                    onChanged: (String? newCurrency) {
                      if (newCurrency != null) {
                        currencyProv.setBaseCurrency(newCurrency);
                      }
                    },
                    items: AppConstants.currencySymbols.keys.map((String curr) {
                      return DropdownMenuItem<String>(
                        value: curr,
                        child: Text(
                          '$curr (${AppConstants.currencySymbols[curr]})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer3<FinanceProvider, CurrencyProvider, BudgetProvider>(
        builder: (context, financeProv, currencyProv, budgetProv, _) {
          if (financeProv.isLoading || currencyProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeCurrency = currencyProv.baseCurrency;
          final convertFn = (double amt, String curr) => currencyProv.convert(amt, curr);

          final balance = financeProv.getCurrentBalance(convertFn: convertFn);
          final income = financeProv.getTotalIncome(convertFn: convertFn);
          final expense = financeProv.getTotalExpense(convertFn: convertFn);

          final warningBudgets = budgetProv
              .calculateBudgetStatuses(financeProv.transactions, convertFn: convertFn)
              .where((b) => b.status != BudgetStatus.normal)
              .toList();

          final recentTxs = financeProv.transactions.take(5).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await financeProv.loadTransactions();
              await currencyProv.fetchRates();
              await budgetProv.loadBudgets();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SummaryCard(
                    balance: balance,
                    income: income,
                    expense: expense,
                    currencyCode: activeCurrency,
                  ),

                  const SizedBox(height: 20),

                  BudgetAlertCard(
                    warningBudgets: warningBudgets,
                    getCategoryName: (catId) =>
                        financeProv.getCategoryById(catId)?.name ?? 'Category',
                    onViewBudgets: () => onNavigateTab(2),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.add_circle_outline,
                          label: 'Add Transaction',
                          color: Theme.of(context).primaryColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddExpenseScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.pie_chart_outline,
                          label: 'Reports',
                          color: Colors.purple,
                          onTap: () => onNavigateTab(3),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigateTab(1),
                        child: const Text('See All'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (recentTxs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No transactions yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap + button below to log your first transaction.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentTxs.length,
                      itemBuilder: (ctx, index) {
                        final tx = recentTxs[index];
                        final category = financeProv.getCategoryById(tx.categoryId);
                        final convertedAmount = currencyProv.convert(tx.amount, tx.originalCurrency);

                        return RecentTransactionTile(
                          transaction: tx,
                          category: category,
                          activeCurrencyCode: activeCurrency,
                          convertedAmount: convertedAmount,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddExpenseScreen(transactionToEdit: tx),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
