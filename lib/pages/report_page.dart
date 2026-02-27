import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_helper.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  double totalIncome = 0;
  double totalExpense = 0;
  String selectedPeriod = 'Bulan Ini';
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, dynamic>> _expenseByCategory = [];
  List<Map<String, dynamic>> _incomeByCategory = [];

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<String> _periods = [
    'Hari Ini',
    '7 Hari',
    '15 Hari',
    'Bulan Ini',
    'Kustom',
  ];

  @override
  void initState() {
    super.initState();
    _calculateTotals();
  }

  String _getStartDate() {
    final now = DateTime.now();
    switch (selectedPeriod) {
      case 'Hari Ini':
        return DateFormat('yyyy-MM-dd').format(now);
      case '7 Hari':
        return DateFormat(
          'yyyy-MM-dd',
        ).format(now.subtract(const Duration(days: 6)));
      case '15 Hari':
        return DateFormat(
          'yyyy-MM-dd',
        ).format(now.subtract(const Duration(days: 14)));
      case 'Bulan Ini':
        return DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(now.year, now.month, 1));
      case 'Kustom':
        if (startDate != null) {
          return DateFormat('yyyy-MM-dd').format(startDate!);
        }
        return DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(now.year, now.month, 1));
      default:
        return DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(now.year, now.month, 1));
    }
  }

  String _getEndDate() {
    if (selectedPeriod == 'Kustom' && endDate != null) {
      return DateFormat('yyyy-MM-dd').format(endDate!);
    }
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _calculateTotals() async {
    final db = DatabaseHelper.instance;
    final start = _getStartDate();
    final end = _getEndDate();

    final totals = await db.getTotals(startDate: start, endDate: end);
    final expenseCats = await db.getTotalsByCategory(
      'Pengeluaran',
      startDate: start,
      endDate: end,
    );
    final incomeCats = await db.getTotalsByCategory(
      'Pemasukan',
      startDate: start,
      endDate: end,
    );

    setState(() {
      totalIncome = totals['income'] ?? 0;
      totalExpense = totals['expense'] ?? 0;
      _expenseByCategory = expenseCats;
      _incomeByCategory = incomeCats;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _calculateTotals();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = totalIncome + totalExpense;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan Keuangan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPeriodChips(),

                  if (selectedPeriod == 'Kustom' &&
                      startDate != null &&
                      endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${DateFormat('dd MMM yyyy').format(startDate!)} — ${DateFormat('dd MMM yyyy').format(endDate!)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),

                  if (total > 0) ...[
                    const Text(
                      'Perbandingan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPieChart(total),
                    const SizedBox(height: 24),
                  ],

                  if (_expenseByCategory.isNotEmpty) ...[
                    const Text(
                      'Pengeluaran per Kategori',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),

          if (_expenseByCategory.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCategoryItem(
                    _expenseByCategory[index],
                    'Pengeluaran',
                    totalExpense,
                  ),
                  childCount: _expenseByCategory.length,
                ),
              ),
            ),

          if (_incomeByCategory.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: const Text(
                  'Pemasukan per Kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),

          if (_incomeByCategory.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCategoryItem(
                    _incomeByCategory[index],
                    'Pemasukan',
                    totalIncome,
                  ),
                  childCount: _incomeByCategory.length,
                ),
              ),
            ),

          if (total == 0) SliverToBoxAdapter(child: _buildEmptyState()),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildPeriodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            _periods.map((p) {
              final isSelected = selectedPeriod == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => selectedPeriod = p);
                    if (p == 'Kustom') {
                      _selectDateRange(context);
                    } else {
                      _calculateTotals();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppTheme.primaryBlue
                                : Colors.grey.shade200,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final net = totalIncome - totalExpense;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pemasukan',
                totalIncome,
                AppTheme.incomeColor,
                Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pengeluaran',
                totalExpense,
                AppTheme.expenseColor,
                Icons.north_east_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Selisih',
          net.abs(),
          net >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
          net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          prefix: net >= 0 ? '+' : '-',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    double amount,
    Color color,
    IconData icon, {
    String? prefix,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${prefix ?? ''}${_currencyFormat.format(amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(double total) {
    final incomePercent = (totalIncome / total * 100).toStringAsFixed(1);
    final expensePercent = (totalExpense / total * 100).toStringAsFixed(1);

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
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: totalIncome,
                    color: AppTheme.incomeColor,
                    title: totalIncome > 0 ? '$incomePercent%' : '',
                    titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    radius: 55,
                  ),
                  PieChartSectionData(
                    value: totalExpense,
                    color: AppTheme.expenseColor,
                    title: totalExpense > 0 ? '$expensePercent%' : '',
                    titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    radius: 55,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Pemasukan', AppTheme.incomeColor),
              const SizedBox(width: 24),
              _buildLegend('Pengeluaran', AppTheme.expenseColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
    Map<String, dynamic> data,
    String type,
    double total,
  ) {
    final category = data['category'] as String;
    final amount = (data['total'] as num).toDouble();
    final percent = total > 0 ? (amount / total * 100) : 0.0;
    final cat = AppConstants.getCategoryByName(category, type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (cat?.color ?? Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              cat?.icon ?? Icons.help_outline,
              color: cat?.color ?? Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(
                      cat?.color ?? Colors.grey,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: AppTheme.primaryBlue.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data untuk periode ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
