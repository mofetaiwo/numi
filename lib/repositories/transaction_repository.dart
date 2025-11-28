// lib/repositories/transaction_repository.dart

import '../models/transaction_model.dart';
// Note: TransactionModel, TransactionType, and ExpenseCategory must be available here

/// Defines the contract for all Transaction data operations.
abstract class ITransactionRepository {
  Future<void> saveTransaction(TransactionModel transaction);
  Future<TransactionModel?> getTransactionById(String id);
  Future<List<TransactionModel>> getTransactionsForUser(String userId); // Uncommented
}

/// Mock implementation for local development and testing.
/// In a real app, this would be implemented by a Firestore or SQL repository.
class MockTransactionRepository implements ITransactionRepository {
  final List<TransactionModel> _transactions = [];

  @override
  Future<void> saveTransaction(TransactionModel transaction) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if transaction exists (for updates)
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    
    if (index >= 0) {
      _transactions[index] = transaction; // Update existing
      print('Mock Repository: Updated transaction ${transaction.id}');
    } else {
      _transactions.add(transaction); // Add new
      print('Mock Repository: Saved new transaction ${transaction.id}');
    }
    // Note: Do not rely on print in production apps for debugging.
  }
  
  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    // FIX: Use .where().firstOrNull pattern for null safety
    final found = _transactions.where((t) => t.id == id);
    return found.isNotEmpty ? found.first : null;
  }
  
  @override
  Future<List<TransactionModel>> getTransactionsForUser(String userId) async {
    // In a real implementation, you would filter by userId.
    // For this mock, we return all transactions.
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_transactions);
  }
}