import 'package:flutter/foundation.dart';
import '../../models/receipt_model.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';

/// ViewModel responsible for handling the state, validation, and persistence
/// of the receipt details verification form.
class ReceiptVerificationViewModel extends ChangeNotifier {
  final ITransactionRepository _transactionRepository;
  final ReceiptModel _initialReceiptData; 

  ReceiptModel get receiptData => _initialReceiptData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final String initialVendor;
  final String initialTotal;
  final String initialDate;
  final String initialCategory;

  ReceiptVerificationViewModel({
    required ITransactionRepository transactionRepository,
    required ReceiptModel initialReceiptData, 
  }) : _transactionRepository = transactionRepository,
        _initialReceiptData = initialReceiptData,
        initialVendor = initialReceiptData.storeName ?? 'Unknown Vendor',
        initialTotal = initialReceiptData.totalAmount?.toStringAsFixed(2) ?? '0.00',
        initialDate = initialReceiptData.purchaseDate?.toIso8601String().split('T').first ?? DateTime.now().toIso8601String().split('T').first,
        initialCategory = initialReceiptData.categoryName ?? 'other';

  /// Handles the form submission, validation, data mapping, and repository save.
  /// Returns true on success, false on failure.
  Future<bool> saveTransaction({
    required String vendor,
    required String total,
    required String date,
    required String category,
  }) async {
    _errorMessage = null;

    _setLoading(true);

    try {
      final double? amount = double.tryParse(total);
      if (amount == null || amount <= 0) { // check for positive amount
        _errorMessage = 'Invalid total amount entered.';
        return false;
      }
      
      final DateTime parsedDate = DateTime.parse(date);
   
      final ExpenseCategory expenseCategory = 
          ReceiptModel.categoryFromString(category); 

      final newTransaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Mock ID
        userId: 'mockUser123', // Static Mock User ID
        // Mapping vendor to description for TransactionModel
        description: vendor, 
        amount: amount,
        date: parsedDate,
        category: expenseCategory,
        type: TransactionType.expense,
        receiptUrl: _initialReceiptData.originalImagePath,
        metadata: {
          'storeName': vendor,
        },
      );

      await _transactionRepository.saveTransaction(newTransaction);
      return true; // Success
      
    } catch (e) {
      _errorMessage = 'Failed to save transaction: $e';
      print('Save Error: $e');
      return false; // Failure
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}