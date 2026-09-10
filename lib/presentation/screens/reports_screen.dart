import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/currency_provider.dart';
import '../../providers/finance_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _touchedIndex = -1;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports & Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer2<FinanceProvider, CurrencyProvider>(
        builder: (context, financeProv, currencyProv, _) {
          final activeCurrency = currencyProv.baseCurrency;
          double convertFn(double amt, String curr) => currencyProv.convert(amt, curr);

          final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);

          final monthTxs = financeProv.transactions.where((tx) {
            final txMonthStr = DateFormat('yyyy-MM').format(tx.date);
            return txMonthStr == monthStr;
          }).toList();

          double monthIncome = 0;
          double monthExpense = 0;
          Map<int, double> categoryExpenses = {};

          for (var tx in monthTxs) {
            final convertedAmt = convertFn(tx.amount, tx.originalCurrency);
            if (tx.type == 'income') {
              monthIncome += convertedAmt;
            } else {
              monthExpense += convertedAmt;
              categoryExpenses[tx.categoryId] = (categoryExpenses[tx.categoryId] ?? 0) + convertedAmt;
            }
          }

          final savings = monthIncome - monthExpense;
          final savingsRate = monthIncome > 0 ? ((savings / monthIncome) * 100).clamp(0, 100).toInt() : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Total Income',
                        value: CurrencyFormatter.format(monthIncome, currencyCode: activeCurrency),
                        color: AppColors.income,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Total Expenses',
                        value: CurrencyFormatter.format(monthExpense, currencyCode: activeCurrency),
                        color: AppColors.expense,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.savings, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Savings: ${CurrencyFormatter.format(savings, currencyCode: activeCurrency)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Savings Rate: $savingsRate%',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Category Spending Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (monthExpense == 0)
                  Container(
                    height: 180,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('No expenses recorded for this month.'),
                  )
                else ...[
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: _generatePieChartSections(
                          categoryExpenses,
                          monthExpense,
                          financeProv,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Column(
                    children: categoryExpenses.entries.map((entry) {
                      final category = financeProv.getCategoryById(entry.key);
                      final catName = category?.name ?? 'Other';
                      final catColor = category != null ? Color(category.colorValue) : Colors.grey;
                      final percent = ((entry.value / monthExpense) * 100).toStringAsFixed(1);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                catName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '$percent% (${CurrencyFormatter.format(entry.value, currencyCode: activeCurrency)})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 24),

                const Text(
                  'Income vs Expense Comparison',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (monthIncome > monthExpense ? monthIncome : monthExpense) * 1.2 + 100,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() == 0) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text('Income', style: TextStyle(fontWeight: FontWeight.bold)),
                                );
                              }
                              if (value.toInt() == 1) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text('Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: monthIncome,
                              color: AppColors.income,
                              width: 28,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: monthExpense,
                              color: AppColors.expense,
                              width: 28,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(
    Map<int, double> categoryExpenses,
    double totalExpense,
    FinanceProvider financeProv,
  ) {
    int index = 0;
    return categoryExpenses.entries.map((entry) {
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 65.0 : 55.0;

      final category = financeProv.getCategoryById(entry.key);
      final catColor = category != null ? Color(category.colorValue) : Colors.grey;
      final percent = ((entry.value / totalExpense) * 100).toStringAsFixed(0);

      index++;

      return PieChartSectionData(
        color: catColor,
        value: entry.value,
        title: '$percent%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
