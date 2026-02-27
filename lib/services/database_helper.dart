import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT DEFAULT '',
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // INSERT
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  // READ ALL
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ by date range
  Future<List<TransactionModel>> getTransactionsByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, id DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ recent N transactions
  Future<List<TransactionModel>> getRecentTransactions(int limit) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // UPDATE
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // DELETE
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // GET BALANCE
  Future<double> getBalance() async {
    final db = await database;
    final incomeResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'Pemasukan'",
    );
    final expenseResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'Pengeluaran'",
    );

    double income = (incomeResult.first['total'] as num).toDouble();
    double expense = (expenseResult.first['total'] as num).toDouble();
    return income - expense;
  }

  // GET totals for a date range
  Future<Map<String, double>> getTotals({
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;
    String whereClause = '';
    List<String> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = "WHERE date >= ? AND date <= ?";
      whereArgs = [startDate, endDate];
    }

    final incomeResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions $whereClause AND type = 'Pemasukan'"
          .replaceFirst('AND', whereClause.isEmpty ? 'WHERE' : 'AND'),
      whereArgs,
    );
    final expenseResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions $whereClause AND type = 'Pengeluaran'"
          .replaceFirst('AND', whereClause.isEmpty ? 'WHERE' : 'AND'),
      whereArgs,
    );

    return {
      'income': (incomeResult.first['total'] as num).toDouble(),
      'expense': (expenseResult.first['total'] as num).toDouble(),
    };
  }

  // GET totals grouped by category
  Future<List<Map<String, dynamic>>> getTotalsByCategory(
    String type, {
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;
    String whereClause = "WHERE type = ?";
    List<dynamic> whereArgs = [type];

    if (startDate != null && endDate != null) {
      whereClause += " AND date >= ? AND date <= ?";
      whereArgs.addAll([startDate, endDate]);
    }

    final result = await db.rawQuery(
      "SELECT category, SUM(amount) as total FROM transactions $whereClause GROUP BY category ORDER BY total DESC",
      whereArgs,
    );

    return result;
  }

  // Search transactions
  Future<List<TransactionModel>> searchTransactions(String query) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'category LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC, id DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
