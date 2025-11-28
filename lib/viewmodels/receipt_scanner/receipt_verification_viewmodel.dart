// import 'package:flutter/foundation.dart';
// import '../models/receipt_model.dart'; // Assuming ReceiptModel is located here
// import '../models/transaction_model.dart';
// import '../repositories/transaction_repository.dart';

// // NOTE: Renamed RawReceiptModel references to ReceiptModel to match the user's provided class.

// /// ViewModel responsible for handling the state, validation, and persistence
// /// of the receipt details verification form.
// class ReceiptVerificationViewModel extends ChangeNotifier {
//   final ITransactionRepository _transactionRepository;
//   final ReceiptModel _initialReceiptData; // Updated to ReceiptModel

//   // --- Observables (State) ---
//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   bool _addToExpenses = false;
//   bool get addToExpenses => _addToExpenses;

//   String? _errorMessage;
//   String? get errorMessage => _errorMessage;

//   // --- Form Data ---
//   // The view will initialize the TextEditingControllers with these initial values.
//   final String initialVendor;
//   final String initialTotal;
//   final String initialDate;
//   final String initialCategory;

//   ReceiptDetailsViewModel({
//     required ITransactionRepository transactionRepository,
//     required ReceiptModel initialReceiptData, // Updated to ReceiptModel
//   }) : _transactionRepository = transactionRepository,
//        _initialReceiptData = initialReceiptData,
//        // Handle potential null values from the ReceiptModel
//        initialVendor = initialReceiptData.storeName ?? 'Unknown Vendor',
//        initialTotal = initialReceiptData.totalAmount?.toStringAsFixed(2) ?? '0.00',
//        initialDate = initialReceiptData.purchaseDate?.toIso8601String().split('T').first ?? DateTime.now().toIso8601String().split('T').first,
//        initialCategory = initialReceiptData.categoryName ?? 'Other';


//   // --- State Mutators (Intent) ---

//   void toggleAddToExpenses(bool value) {
//     _addToExpenses = value;
//     notifyListeners();
//   }

//   /// Handles the form submission, validation, data mapping, and repository save.
//   /// Returns true on success, false on failure.
//   Future<bool> saveTransaction({
//     required String vendor,
//     required String total,
//     required String date,
//     required String category,
//   }) async {
//     _errorMessage = null;

//     if (!_addToExpenses) {
//       _errorMessage = 'Please confirm "Add to Expenses" before saving.';
//       notifyListeners();
//       return false;
//     }

//     _setLoading(true);

//     try {
//       final double? amount = double.tryParse(total);
//       if (amount == null) {
//         _errorMessage = 'Invalid total amount entered.';
//         return false;
//       }
      
//       final DateTime parsedDate = DateTime.parse(date); // Assumes YYYY-MM-DD format

//       final newTransaction = TransactionModel(
//         id: DateTime.now().millisecondsSinceEpoch.toString(), // Mock ID
//         userId: 'mockUser123', // Static Mock User ID
//         vendor: vendor,
//         amount: amount,
//         date: parsedDate,
//         category: ExpenseCategory.other, // Defaulted for simplicity
//         type: TransactionType.expense,
//         receiptImagePath: _initialReceiptData.originalImagePath, // Updated field name
//         notes: 'Verified OCR entry. Category: $category',
//       );

//       await _transactionRepository.saveTransaction(newTransaction);
//       return true; // Success
      
//     } catch (e) {
//       _errorMessage = 'Failed to save transaction: $e';
//       print('Save Error: $e');
//       return false; // Failure
//     } finally {
//       _setLoading(false);
//     }
//   }

//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
// }