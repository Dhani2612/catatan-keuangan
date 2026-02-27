import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'transaction_page.dart';
import 'history_page.dart';
import 'report_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  double _balance = 0.0;
  double _monthIncome = 0.0;
  double _monthExpense = 0.0;
  List<TransactionModel> _recentTransactions = [];
  Map<String, double> _last7DaysExpense = {};
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final balance = await db.getBalance();
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final totals = await db.getTotals(
      startDate: DateFormat('yyyy-MM-dd').format(firstDay),
      endDate: DateFormat('yyyy-MM-dd').format(now),
    );
    final recent = await db.getRecentTransactions(5);

    // Load last 7 days expense for mini chart
    final Map<String, double> dailyExpense = {};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      dailyExpense[DateFormat('E', 'id_ID').format(day)] = 0;
    }

    final last7 = await db.getTransactionsByDateRange(
      DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 6))),
      DateFormat('yyyy-MM-dd').format(now),
    );
    for (var t in last7) {
      if (t.type == 'Pengeluaran') {
        final day = DateTime.parse(t.date);
        final label = DateFormat('E', 'id_ID').format(day);
        dailyExpense[label] = (dailyExpense[label] ?? 0) + t.amount;
      }
    }

    setState(() {
      _balance = balance;
      _monthIncome = totals['income'] ?? 0;
      _monthExpense = totals['expense'] ?? 0;
      _recentTransactions = recent;
      _last7DaysExpense = dailyExpense;
    });
    _fadeController.forward(from: 0);
  }

  void _navigateToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      HistoryPage(onDataChanged: _loadData),
      const ReportPage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_rounded),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildBalanceCard(),
                    const SizedBox(height: 16),
                    _buildSummaryRow(),
                    const SizedBox(height: 24),
                    _buildMiniChart(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Transaksi Terakhir'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _recentTransactions.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState())
                : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildTransactionItem(_recentTransactions[index]),
                      childCount: _recentTransactions.length,
                    ),
                  ),
                ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Selamat Pagi ☀️';
    } else if (hour < 17) {
      greeting = 'Selamat Siang 🌤️';
    } else {
      greeting = 'Selamat Malam 🌙';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Catatan Keuangan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '💰 Total Saldo',
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
              const Spacer(),
              _buildHealthBadge(),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _currencyFormat.format(_balance),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now()),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBadge() {
    String status = 'Aman';
    Color bgColor = AppTheme.incomeColor;
    IconData icon = Icons.check_circle_outline_rounded;

    if (_monthIncome == 0 && _monthExpense == 0) {
      status = 'Belum ada data';
      bgColor = Colors.white.withValues(alpha: 0.2);
      icon = Icons.info_outline_rounded;
    } else if (_monthExpense > _monthIncome) {
      status = 'Defisit';
      bgColor = AppTheme.expenseColor;
      icon = Icons.warning_amber_rounded;
    } else if (_monthExpense >= _monthIncome * 0.8) {
      status = 'Waspada';
      bgColor = AppTheme.warningColor;
      icon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            status,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Pemasukan',
            _monthIncome,
            AppTheme.incomeColor,
            Icons.south_west_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Pengeluaran',
            _monthExpense,
            AppTheme.expenseColor,
            Icons.north_east_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart() {
    final hasData = _last7DaysExpense.values.any((v) => v > 0);

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pengeluaran 7 Hari',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currencyFormat.format(
                    _last7DaysExpense.values.fold(0.0, (s, v) => s + v),
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child:
                hasData
                    ? BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY:
                            _last7DaysExpense.values.reduce(
                              (a, b) => a > b ? a : b,
                            ) *
                            1.3,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            tooltipMargin: 4,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final label = _last7DaysExpense.keys.elementAt(
                                group.x,
                              );
                              return BarTooltipItem(
                                '$label\n${_currencyFormat.format(rod.toY)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx >= 0 &&
                                    idx < _last7DaysExpense.keys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _last7DaysExpense.keys.elementAt(idx),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textHint,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups:
                            _last7DaysExpense.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                                  final i = entry.key;
                                  final val = entry.value.value;
                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: val > 0 ? val : 0,
                                        color:
                                            i == _last7DaysExpense.length - 1
                                                ? AppTheme.primaryBlue
                                                : AppTheme.accentBlue
                                                    .withValues(alpha: 0.5),
                                        width: 20,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                      ),
                                    ],
                                  );
                                })
                                .toList(),
                      ),
                    )
                    : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 40,
                            color: AppTheme.textHint.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Belum ada data pengeluaran',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        if (_recentTransactions.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() => _currentIndex = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Lihat Semua →',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    final category = AppConstants.getCategoryByName(t.category, t.type);
    final isIncome = t.type == 'Pemasukan';

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
              color: (category?.color ?? Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category?.icon ?? Icons.help_outline,
              color: category?.color ?? Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.category,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.description.isNotEmpty ? t.description : t.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} ${_currencyFormat.format(t.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: AppTheme.primaryBlue.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + untuk menambah transaksi pertama',
            style: TextStyle(fontSize: 13, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}
