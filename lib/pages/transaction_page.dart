import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class AddTransactionPage extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionPage({super.key, this.transaction});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  String _selectedType = 'Pengeluaran';
  String? _selectedCategory;
  double _amount = 0;
  String _description = '';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final NumberFormat _formatter = NumberFormat.decimalPattern('id');

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.transaction!;
      _selectedType = t.type;
      _selectedCategory = t.category;
      _amount = t.amount;
      _description = t.description;
      _selectedDate = DateTime.parse(t.date);
      _amountController.text = _formatter.format(t.amount);
      _descriptionController.text = t.description;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_selectedCategory == null || _amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data transaksi!')),
      );
      return;
    }

    final db = DatabaseHelper.instance;
    final transaction = TransactionModel(
      id: widget.transaction?.id,
      type: _selectedType,
      category: _selectedCategory!,
      amount: _amount,
      description: _description,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );

    if (_isEditing) {
      await db.updateTransaction(transaction);
    } else {
      await db.insertTransaction(transaction);
    }

    if (mounted) Navigator.pop(context, true);
  }

  void _formatAmountInput(String value) {
    String numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericValue.isNotEmpty) {
      double parsed = double.parse(numericValue);
      setState(() {
        _amount = parsed;
        _amountController.text = _formatter.format(parsed);
        _amountController.selection = TextSelection.fromPosition(
          TextPosition(offset: _amountController.text.length),
        );
      });
    } else {
      setState(() {
        _amount = 0;
        _amountController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        _selectedType == 'Pemasukan'
            ? AppConstants.incomeCategories
            : AppConstants.expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 24),
            _buildAmountInput(),
            const SizedBox(height: 24),
            const Text(
              'Kategori',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryGrid(categories),
            const SizedBox(height: 24),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.textHint),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
              onChanged: (v) => _description = v,
            ),
            const SizedBox(height: 20),
            _buildDatePicker(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _selectedType == 'Pemasukan'
                          ? AppTheme.incomeColor
                          : AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  _isEditing ? 'Simpan Perubahan' : 'Simpan Transaksi',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTypeButton('Pengeluaran', AppTheme.expenseColor),
          _buildTypeButton('Pemasukan', AppTheme.incomeColor),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, Color activeColor) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedCategory = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? activeColor : AppTheme.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Nominal',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color:
                  _selectedType == 'Pemasukan'
                      ? AppTheme.incomeColor
                      : AppTheme.primaryBlue,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHint.withValues(alpha: 0.3),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(
                fontSize: 22,
                color: AppTheme.textSecondary,
              ),
            ),
            onChanged: _formatAmountInput,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<AppCategory> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = _selectedCategory == cat.name;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color:
                  isSelected ? cat.color.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isSelected
                        ? cat.color.withValues(alpha: 0.5)
                        : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: cat.color.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat.icon, color: cat.color, size: 24),
                const SizedBox(height: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? cat.color : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textHint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
