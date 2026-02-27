import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'utils/app_theme.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catatan Keuangan',
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
