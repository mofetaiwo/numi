import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

enum ExpenseCategory {
  food,
  transport,
  shopping,
  entertainment,
  bills,
  healthcare,
  education,
  other
}

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String description;
  final ExpenseCategory category;
  final TransactionType type;
  final DateTime date;
  final String? receiptUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    this.currency = 'USD',
    required this.description,
    required this.category,
    required this.type,
    required this.date,
    this.receiptUrl,
    this.metadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      description: data['description'] ?? '',
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString() == 'ExpenseCategory.${data['category']}',
        orElse: () => ExpenseCategory.other,
      ),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type']}',
        orElse: () => TransactionType.expense,
      ),
      date: (data['date'] as Timestamp).toDate(),
      receiptUrl: data['receiptUrl'],
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'category': category.toString().split('.').last,
      'type': type.toString().split('.').last,
      'date': Timestamp.fromDate(date),
      'receiptUrl': receiptUrl,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TransactionModel copyWith({
    String? description,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? receiptUrl,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      amount: amount ?? this.amount,
      currency: currency,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type,
      date: date ?? this.date,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      metadata: metadata,
      createdAt: createdAt,
    );
  }
}