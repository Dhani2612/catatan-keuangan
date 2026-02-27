class TransactionModel {
  int? id;
  String type;
  String category;
  double amount;
  String description;
  String date;
  String? createdAt;

  TransactionModel({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    this.description = '',
    required this.date,
    this.createdAt,
  });

  // Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  // Create from SQLite Map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      category: map['category'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      date: map['date'],
      createdAt: map['created_at'],
    );
  }

  // Copy with new values (for editing)
  TransactionModel copyWith({
    int? id,
    String? type,
    String? category,
    double? amount,
    String? description,
    String? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }
}
