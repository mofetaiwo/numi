import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get userId => currentUser?.uid;

  // Authentication
  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Transactions
  Stream<List<TransactionModel>> getTransactionsStream() {
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList());
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _firestore.collection('transactions').add(transaction.toFirestore());
    await _updateBudgetSpent(transaction);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toFirestore());
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _firestore.collection('transactions').doc(transactionId).delete();
  }

  // Budgets
  Stream<List<BudgetModel>> getBudgetsStream() {
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BudgetModel.fromFirestore(doc))
        .toList());
  }

  Future<void> addBudget(BudgetModel budget) async {
    await _firestore.collection('budgets').add(budget.toFirestore());
  }

  Future<void> updateBudget(BudgetModel budget) async {
    await _firestore
        .collection('budgets')
        .doc(budget.id)
        .update(budget.toFirestore());
  }

  Future<void> _updateBudgetSpent(TransactionModel transaction) async {
    if (transaction.type != TransactionType.expense) return;

    QuerySnapshot budgetSnapshot = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: transaction.category.toString().split('.').last)
        .where('isActive', isEqualTo: true)
        .get();

    for (var doc in budgetSnapshot.docs) {
      BudgetModel budget = BudgetModel.fromFirestore(doc);
      if (transaction.date.isAfter(budget.startDate) &&
          transaction.date.isBefore(budget.endDate)) {
        await _firestore.collection('budgets').doc(doc.id).update({
          'spent': FieldValue.increment(transaction.amount),
        });
      }
    }
  }

  // Analytics
  Future<Map<ExpenseCategory, double>> getCategorySpending(
      DateTime startDate,
      DateTime endDate,
      ) async {
    if (userId == null) return {};

    QuerySnapshot snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    Map<ExpenseCategory, double> categoryTotals = {};

    for (var doc in snapshot.docs) {
      TransactionModel transaction = TransactionModel.fromFirestore(doc);
      categoryTotals[transaction.category] =
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }

    return categoryTotals;
  }
}