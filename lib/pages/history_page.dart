import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'transaction_page.dart';

class HistoryPage extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const HistoryPage({super.key, this.onDataChanged});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  String _filterType = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final db = DatabaseHelper.instance;
    final transactions = await db.getAllTransactions();
    setState(() {
      _allTransactions = transactions;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<TransactionModel> result = _allTransactions;
    if (_filterType != 'Semua') {
      result = result.where((t) => t.type == _filterType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result =
          result
              .where(
                (t) =>
                    t.category.toLowerCase().contains(q) ||
                    t.description.toLowerCase().contains(q),
              )
              .toList();
    }
    _filteredTransactions = result;
  }

  Map<String, List<TransactionModel>> _groupByDate(
    List<TransactionModel> list,
  ) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (var t in list) {
      grouped.putIfAbsent(t.date, () => []).add(t);
    }
    return grouped;
  }

  Future<void> _deleteTransaction(TransactionModel t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Hapus Transaksi'),
            content: Text(
              'Hapus ${t.category} — ${_currencyFormat.format(t.amount)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Batal',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.expenseColor.withValues(alpha: 0.1),
                ),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: AppTheme.expenseColor),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && t.id != null) {
      await DatabaseHelper.instance.deleteTransaction(t.id!);
      _loadTransactions();
      widget.onDataChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
      }
    }
  }

  Future<void> _editTransaction(TransactionModel t) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTransactionPage(transaction: t)),
    );
    if (result == true) {
      _loadTransactions();
      widget.onDataChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(_filteredTransactions);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Transaksi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildFilterChips(),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child:
                _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: grouped.keys.length,
                      itemBuilder: (context, index) {
                        final date = grouped.keys.elementAt(index);
                        final transactions = grouped[date]!;
                        return _buildDateGroup(date, transactions);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari transaksi...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textHint,
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textHint,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _applyFilters();
                      });
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: AppTheme.textPrimary),
        onChanged: (v) {
          setState(() {
            _searchQuery = v;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'Pemasukan', 'Pengeluaran'];
    return Row(
      children:
          filters.map((f) {
            final isSelected = _filterType == f;
            Color chipColor;
            if (f == 'Pemasukan') {
              chipColor = AppTheme.incomeColor;
            } else if (f == 'Pengeluaran') {
              chipColor = AppTheme.expenseColor;
            } else {
              chipColor = AppTheme.primaryBlue;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _filterType = f;
                    _applyFilters();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? chipColor.withValues(alpha: 0.12)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected
                              ? chipColor.withValues(alpha: 0.4)
                              : Colors.grey.shade200,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: chipColor.withValues(alpha: 0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? chipColor : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDateGroup(String date, List<TransactionModel> transactions) {
    String formattedDate;
    try {
      formattedDate = DateFormat(
        'dd MMMM yyyy',
        'id_ID',
      ).format(DateTime.parse(date));
    } catch (_) {
      formattedDate = date;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ...transactions.map((t) => _buildTransactionCard(t)),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel t) {
    final cat = AppConstants.getCategoryByName(t.category, t.type);
    final isIncome = t.type == 'Pemasukan';

    return Dismissible(
      key: Key('transaction_${t.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.expenseColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.expenseColor,
          size: 24,
        ),
      ),
      confirmDismiss: (_) async {
        await _deleteTransaction(t);
        return false;
      },
      child: GestureDetector(
        onTap: () => _editTransaction(t),
        child: Container(
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
                    if (t.description.isNotEmpty)
                      Text(
                        t.description,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'} ${_currencyFormat.format(t.amount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isIncome
                              ? AppTheme.incomeColor
                              : AppTheme.expenseColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textHint,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppTheme.primaryBlue.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada hasil untuk "$_searchQuery"'
                : 'Belum ada transaksi',
            style: const TextStyle(
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
