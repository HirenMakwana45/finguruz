import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/currency_provider.dart';
import '../../providers/finance_provider.dart';
import '../widgets/recent_transaction_tile.dart';
import 'add_expense_screen.dart';

class ExpenseTrackerScreen extends StatelessWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer2<FinanceProvider, CurrencyProvider>(
        builder: (context, financeProv, currencyProv, _) {
          final activeCurrency = currencyProv.baseCurrency;
          final filteredList = financeProv.filteredTransactions;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => financeProv.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: financeProv.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => financeProv.setSearchQuery(''),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFilterChip(
                          context,
                          label: 'All',
                          isSelected: financeProv.selectedTypeFilter == 'all',
                          onTap: () => financeProv.setTypeFilter('all'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          label: 'Expenses',
                          isSelected: financeProv.selectedTypeFilter == 'expense',
                          onTap: () => financeProv.setTypeFilter('expense'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          label: 'Income',
                          isSelected: financeProv.selectedTypeFilter == 'income',
                          onTap: () => financeProv.setTypeFilter('income'),
                        ),
                        const Spacer(),
                        DropdownButton<int?>(
                          value: financeProv.selectedCategoryFilter,
                          hint: const Text('Category', style: TextStyle(fontSize: 13)),
                          icon: const Icon(Icons.filter_list, size: 18),
                          underline: const SizedBox.shrink(),
                          onChanged: (catId) => financeProv.setCategoryFilter(catId),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All Categories', style: TextStyle(fontSize: 13)),
                            ),
                            ...financeProv.categories.map((cat) {
                              return DropdownMenuItem<int?>(
                                value: cat.id,
                                child: Text(cat.name, style: const TextStyle(fontSize: 13)),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'No transactions found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try adjusting your search or filters.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (ctx, index) {
                          final tx = filteredList[index];
                          final category = financeProv.getCategoryById(tx.categoryId);
                          final convertedAmount = currencyProv.convert(tx.amount, tx.originalCurrency);

                          return Dismissible(
                            key: Key('tx_${tx.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.expense,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (dir) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Transaction'),
                                  content: const Text('Are you sure you want to delete this entry?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) {
                              if (tx.id != null) {
                                financeProv.deleteTransaction(tx.id!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transaction deleted')),
                                );
                              }
                            },
                            child: RecentTransactionTile(
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
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
