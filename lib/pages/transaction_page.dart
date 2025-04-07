import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class AddTransactionPage extends StatefulWidget {
  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  String? _selectedType;
  String? _selectedCategory;
  double _amount = 0;
  String _description = "";
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _formatter = NumberFormat.decimalPattern('id');

  final List<String> _incomeCategories = ["Transfer", "Gaji"];
  final List<String> _expenseCategories = ["Makan & Minum", "Jajan" , "Transportasi", "Pulsa", "Lainnya"];

  Future<void> _saveTransaction() async {
    if (_selectedType == null || _selectedCategory == null || _amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Harap lengkapi semua data transaksi!")),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> transactions = prefs.getStringList('transactions') ?? [];

    TransactionModel newTransaction = TransactionModel(
      type: _selectedType!,
      category: _selectedCategory!,
      amount: _amount,
      description: _description,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );

    transactions.add(jsonEncode(newTransaction.toJson()));
    await prefs.setStringList('transactions', transactions);

    double currentBalance = prefs.getDouble('balance') ?? 0;
    if (_selectedType == "Pemasukan") {
      currentBalance += _amount;
    } else {
      currentBalance -= _amount;
    }
    await prefs.setDouble('balance', currentBalance);

    Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Transaksi'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              hint: Text("Pilih Jenis"),
              items: ["Pemasukan", "Pengeluaran"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedType = newValue;
                  _selectedCategory = null;
                });
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: Text("Pilih Kategori"),
              items: (_selectedType == "Pemasukan" ? _incomeCategories : _expenseCategories).map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Nominal"),
              onChanged: _formatAmountInput,
            ),
            TextField(
              decoration: InputDecoration(labelText: "Deskripsi"),
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: Text("Pilih Tanggal: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }
}
