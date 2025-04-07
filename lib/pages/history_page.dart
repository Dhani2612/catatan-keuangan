import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Map<String, List<TransactionModel>> _groupedTransactions = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> transactions = prefs.getStringList('transactions') ?? [];

    List<TransactionModel> transactionList = transactions
        .map((e) => TransactionModel.fromJson(jsonDecode(e)))
        .toList();

    transactionList.sort((a, b) => b.date.compareTo(a.date)); // Urutkan dari terbaru ke terlama

    setState(() {
      _groupedTransactions = _groupByDate(transactionList);
    });
  }

  Map<String, List<TransactionModel>> _groupByDate(List<TransactionModel> transactions) {
    Map<String, List<TransactionModel>> grouped = {};
    for (var transaction in transactions) {
      grouped.putIfAbsent(transaction.date, () => []).add(transaction);
    }
    return grouped;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Transaksi'),
        backgroundColor: Colors.red,
      ),
      body: _groupedTransactions.isEmpty
          ? Center(child: Text('Belum ada transaksi'))
          : ListView.builder(
        itemCount: _groupedTransactions.keys.length,
        itemBuilder: (context, index) {
          String date = _groupedTransactions.keys.elementAt(index);
          List<TransactionModel> transactions = _groupedTransactions[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.parse(date)),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ...transactions.map((transaction) => Card(
                child: ListTile(
                  title: Text(transaction.category),
                  subtitle: Text(transaction.description),
                  trailing: Text(
                    '${transaction.type == "Pemasukan" ? "+" : "-"} ${_formatCurrency(transaction.amount)}',
                    style: TextStyle(
                      color: transaction.type == "Pemasukan" ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ))
            ],
          );
        },
      ),
    );
  }
}