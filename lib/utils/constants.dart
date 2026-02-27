import 'package:flutter/material.dart';

class AppCategory {
  final String name;
  final IconData icon;
  final Color color;

  const AppCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AppConstants {
  // Income categories
  static const List<AppCategory> incomeCategories = [
    AppCategory(
      name: 'Gaji',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF4CAF50),
    ),
    AppCategory(
      name: 'Transfer',
      icon: Icons.swap_horiz,
      color: Color(0xFF2196F3),
    ),
    AppCategory(
      name: 'Freelance',
      icon: Icons.laptop_mac,
      color: Color(0xFF9C27B0),
    ),
    AppCategory(
      name: 'Investasi',
      icon: Icons.trending_up,
      color: Color(0xFFFF9800),
    ),
    AppCategory(
      name: 'Lainnya',
      icon: Icons.more_horiz,
      color: Color(0xFF607D8B),
    ),
  ];

  // Expense categories
  static const List<AppCategory> expenseCategories = [
    AppCategory(
      name: 'Makan & Minum',
      icon: Icons.restaurant,
      color: Color(0xFFE91E63),
    ),
    AppCategory(
      name: 'Jajan',
      icon: Icons.local_cafe,
      color: Color(0xFFFF5722),
    ),
    AppCategory(
      name: 'Transportasi',
      icon: Icons.directions_car,
      color: Color(0xFF3F51B5),
    ),
    AppCategory(
      name: 'Belanja',
      icon: Icons.shopping_bag,
      color: Color(0xFF8BC34A),
    ),
    AppCategory(
      name: 'Pulsa',
      icon: Icons.phone_android,
      color: Color(0xFF00BCD4),
    ),
    AppCategory(
      name: 'Tagihan',
      icon: Icons.receipt_long,
      color: Color(0xFFFF9800),
    ),
    AppCategory(name: 'Hiburan', icon: Icons.movie, color: Color(0xFF9C27B0)),
    AppCategory(
      name: 'Kesehatan',
      icon: Icons.local_hospital,
      color: Color(0xFFF44336),
    ),
    AppCategory(
      name: 'Pendidikan',
      icon: Icons.school,
      color: Color(0xFF2196F3),
    ),
    AppCategory(
      name: 'Lainnya',
      icon: Icons.more_horiz,
      color: Color(0xFF607D8B),
    ),
  ];

  // Get category info by name
  static AppCategory? getCategoryByName(String name, String type) {
    final list = type == 'Pemasukan' ? incomeCategories : expenseCategories;
    try {
      return list.firstWhere((c) => c.name == name);
    } catch (_) {
      return AppCategory(
        name: name,
        icon: Icons.help_outline,
        color: const Color(0xFF607D8B),
      );
    }
  }
}
