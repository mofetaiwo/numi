import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_model.dart';

class BudgetModel {
  final String id;
  final String userId;
  final ExpenseCategory category;
  final double limit;
  final double spent;
  final String period; // monthly, weekly, yearly
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.limit,
    this.spent = 0.0,
    this.period = 'monthly',
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  double get remaining => limit - spent;
  double get percentageUsed => spent / limit;
  bool get isOverBudget => spent > limit;

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BudgetModel(
      id: doc.id,
      userId: data['userId'],
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString() == 'ExpenseCategory.${data['category']}',
        orElse: () => ExpenseCategory.other,
      ),
      limit: (data['limit'] ?? 0.0).toDouble(),
      spent: (data['spent'] ?? 0.0).toDouble(),
      period: data['period'] ?? 'monthly',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'category': category.toString().split('.').last,
      'limit': limit,
      'spent': spent,
      'period': period,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
    };
  }
}