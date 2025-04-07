import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/transaction.dart';

class StorageService {
  static const String _keyTransactions = 'transactions';

  // Simpan transaksi ke SharedPreferences
  static Future<void> saveTransaction(TransactionModel transaction) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> transactions = prefs.getStringList(_keyTransactions) ?? [];

    transactions.add(jsonEncode(transaction.toJson()));

    await prefs.setStringList(_keyTransactions, transactions);
  }

  // Ambil semua transaksi dari SharedPreferences
  static Future<List<TransactionModel>> getTransactions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> transactions = prefs.getStringList(_keyTransactions) ?? [];

    return transactions.map((e) => TransactionModel.fromJson(jsonDecode(e))).toList();
  }
}
