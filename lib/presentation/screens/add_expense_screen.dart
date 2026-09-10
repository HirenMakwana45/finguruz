import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/currency_provider.dart';
import '../../providers/finance_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final TransactionModel? transactionToEdit;

  const AddExpenseScreen({super.key, this.transactionToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _type;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late DateTime _selectedDate;
  int? _selectedCategoryId;
  late String _selectedCurrency;
  late bool _isRecurring;
  late String _recurringInterval;

  @override
  void initState() {
    super.initState();
    final tx = widget.transactionToEdit;

    _type = tx?.type ?? 'expense';
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(text: tx != null ? tx.amount.toString() : '');
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedDate = tx?.date ?? DateTime.now();
    _selectedCategoryId = tx?.categoryId;
    _selectedCurrency = tx?.originalCurrency ?? 'USD';
    _isRecurring = tx?.isRecurring ?? false;
    _recurringInterval = tx?.recurringInterval ?? 'monthly';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final double amount = double.parse(_amountController.text.trim());

    final transaction = TransactionModel(
      id: widget.transactionToEdit?.id,
      title: _titleController.text.trim(),
      amount: amount,
      date: _selectedDate,
      categoryId: _selectedCategoryId!,
      type: _type,
      isRecurring: _isRecurring,
      recurringInterval: _isRecurring ? _recurringInterval : 'none',
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      originalCurrency: _selectedCurrency,
    );

    final financeProv = Provider.of<FinanceProvider>(context, listen: false);

    if (widget.transactionToEdit == null) {
      financeProv.addTransaction(transaction);
    } else {
      financeProv.updateTransaction(transaction);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transactionToEdit != null;
    final categories = Provider.of<FinanceProvider>(context).categories;
    final activeBaseCurrency = Provider.of<CurrencyProvider>(context, listen: false).baseCurrency;

    if (!isEditing && widget.transactionToEdit == null && _selectedCurrency == 'USD') {
      _selectedCurrency = activeBaseCurrency;
    }

    final filteredCategories = categories.where((cat) => cat.type == _type || cat.name == 'Other').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'New Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _type = 'expense';
                            _selectedCategoryId = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'expense' ? AppColors.expense : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Expense',
                            style: TextStyle(
                              color: _type == 'expense' ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _type = 'income';
                            _selectedCategoryId = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'income' ? AppColors.income : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Income',
                            style: TextStyle(
                              color: _type == 'income' ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Grocery Shopping, Monthly Salary',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter a title';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter amount';
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null || parsed <= 0) return 'Invalid amount';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                      ),
                      items: AppConstants.currencySymbols.keys.map((curr) {
                        return DropdownMenuItem(
                          value: curr,
                          child: Text(curr),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCurrency = val);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: filteredCategories.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  final catColor = Color(cat.colorValue);
                  final catIcon = IconData(cat.iconCode, fontFamily: 'MaterialIcons');

                  return InkWell(
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor : catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? catColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            catIcon,
                            size: 18,
                            color: isSelected ? Colors.white : catColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text('Transaction Date'),
                subtitle: Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectDate,
              ),

              const Divider(),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Text(
                  'Recurring Transaction',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Automatically repeat this entry in the future'),
                value: _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),

              if (_isRecurring) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _recurringInterval,
                  decoration: const InputDecoration(
                    labelText: 'Repeat Interval',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _recurringInterval = val);
                  },
                ),
              ],

              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Additional details...',
                  prefixIcon: Icon(Icons.note),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveTransaction,
                child: Text(isEditing ? 'Update Transaction' : 'Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
