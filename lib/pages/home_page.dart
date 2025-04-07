import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'transaction_page.dart';
import 'history_page.dart';
import 'report_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _saldo = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSaldo();
  }

  Future<void> _loadSaldo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _saldo = prefs.getDouble('balance') ?? 0.0;
    });
  }

  Future<void> _updateSaldo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double newSaldo = prefs.getDouble('balance') ?? 0.0;
    setState(() {
      _saldo = newSaldo;
    });
  }

  String _formatCurrency(double value) {
    final formatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finance App'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSaldoCard(),
            SizedBox(height: 20),
            _buildMenuButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaldoCard() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Saldo Saat Ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _formatCurrency(_saldo),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMenuButton(
          context,
          'Tambah Transaksi',
          Icons.add,
          Colors.blue,
          AddTransactionPage(),
          true,
        ),
        SizedBox(height: 12),
        _buildMenuButton(
          context,
          'Riwayat Transaksi',
          Icons.history,
          Colors.red,
          HistoryPage(),
          false,
        ),
        SizedBox(height: 12),
        _buildMenuButton(
          context,
          'Laporan Keuangan',
          Icons.bar_chart,
          Colors.green,
          ReportPage(),
          false,
        ),
      ],
    );
  }

  Widget _buildMenuButton(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      Widget page,
      bool shouldUpdate,
      ) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24, color: Colors.white),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          title,
          style: TextStyle(fontSize: 16),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () async {
        bool? result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
        if (shouldUpdate && result == true) {
          _updateSaldo();
        }
      },
    );
  }
}
