import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  double totalIncome = 0;
  double totalExpense = 0;
  String selectedPeriod = 'Hari Ini';
  DateTime? startDate;
  DateTime? endDate;
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _calculateTotals();
  }

  Future<void> _calculateTotals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> transactions = prefs.getStringList('transactions') ?? [];
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

    DateTime startFilterDate = firstDayOfMonth;
    DateTime endFilterDate = now;

    switch (selectedPeriod) {
      case 'Hari Ini':
        startFilterDate = now;
        break;
      case '7 Hari Kebelakang':
        startFilterDate = now.subtract(Duration(days: 6));
        break;
      case '15 Hari Kebelakang':
        startFilterDate = now.subtract(Duration(days: 14));
        break;
      case 'Bulan Ini':
        startFilterDate = firstDayOfMonth;
        break;
      case 'Kustom':
        if (startDate != null && endDate != null) {
          startFilterDate = startDate!;
          endFilterDate = endDate!;
        }
        break;
    }

    double income = 0;
    double expense = 0;

    for (var item in transactions) {
      TransactionModel transaction = TransactionModel.fromJson(jsonDecode(item));
      DateTime transactionDate = DateTime.parse(transaction.date);
      if (transactionDate.isAfter(startFilterDate.subtract(Duration(days: 1))) && transactionDate.isBefore(endFilterDate.add(Duration(days: 1)))) {
        if (transaction.type == "Pemasukan") {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }
    }

    setState(() {
      totalIncome = income;
      totalExpense = expense;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        _calculateTotals();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Keuangan'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedPeriod,
              items: ['Hari Ini', '7 Hari Kebelakang', '15 Hari Kebelakang', 'Bulan Ini', 'Kustom']
                  .map((String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedPeriod = newValue!;
                  if (selectedPeriod == 'Kustom') {
                    _selectDateRange(context);
                  } else {
                    _calculateTotals();
                  }
                });
              },
            ),
            if (selectedPeriod == 'Kustom' && startDate != null && endDate != null)
              Text(
                'Rentang: ${DateFormat('dd MMM yyyy').format(startDate!)} - ${DateFormat('dd MMM yyyy').format(endDate!)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Total Pemasukan: ${currencyFormat.format(totalIncome)}',
                        style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('Total Pengeluaran: ${currencyFormat.format(totalExpense)}',
                        style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalIncome,
                      color: Colors.green,
                      title: totalIncome > 0 ? '${(totalIncome / (totalIncome + totalExpense) * 100).toStringAsFixed(1)}%' : '',
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: totalExpense,
                      color: Colors.red,
                      title: totalExpense > 0 ? '${(totalExpense / (totalIncome + totalExpense) * 100).toStringAsFixed(1)}%' : '',
                      radius: 80,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}