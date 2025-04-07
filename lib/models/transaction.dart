class TransactionModel {
  String type;
  String category;
  double amount;
  String description;
  String date;

  TransactionModel({
    required this.type,
    required this.category,
    required this.amount,
    this.description = '',
    required this.date,
  });

  // Convert object ke JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date,
    };
  }

  // Convert JSON ke object
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      type: json['type'],
      category: json['category'],
      amount: json['amount'],
      description: json['description'],
      date: json['date'],
    );
  }
}
