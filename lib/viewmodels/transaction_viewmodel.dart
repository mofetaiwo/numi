// import 'dart:io';
// import 'package:flutter/foundation.dart';
// // import 'package:vibration/vibration.dart';
// import '../models/transaction_model.dart';
// import '../services/firebase_service.dart';
// import '../services/camera_service.dart';

// class TransactionViewModel extends ChangeNotifier {
//   final FirebaseService _firebaseService;
//   final CameraService _cameraService;
  
//   List<TransactionModel> _transactions = [];
//   List<TransactionModel> _filteredTransactions = [];
//   bool _isLoading = false;
//   String? _error;
//   ExpenseCategory? _selectedCategory;
//   DateTime _selectedDate = DateTime.now();
//   File? _receiptImage;

//   TransactionViewModel({
//     FirebaseService? firebaseService,
//     CameraService? cameraService,
//   })  : _firebaseService = firebaseService ?? FirebaseService(),
//         _cameraService = cameraService ?? CameraService() {
//     _initializeServices();
//   }

//   // Getters
//   List<TransactionModel> get transactions => _filteredTransactions.isEmpty 
//       ? _transactions 
//       : _filteredTransactions;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   bool get hasError => _error != null;
//   bool get isEmpty => _transactions.isEmpty && !_isLoading;
//   ExpenseCategory? get selectedCategory => _selectedCategory;
//   DateTime get selectedDate => _selectedDate;
//   File? get receiptImage => _receiptImage;

//   double get totalIncome {
//     return _transactions
//         .where((t) => t.type == TransactionType.income)
//         .fold(0.0, (sum, t) => sum + t.amount);
//   }

//   double get totalExpenses {
//     return _transactions
//         .where((t) => t.type == TransactionType.expense)
//         .fold(0.0, (sum, t) => sum + t.amount);
//   }

//   double get balance => totalIncome - totalExpenses;

//   // Initialize
//   Future<void> _initializeServices() async {
//     await _cameraService.initializeCameras();
//     loadTransactions();
//   }

//   // Load transactions
//   void loadTransactions() {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     _firebaseService.getTransactionsStream().listen(
//       (transactions) {
//         _transactions = transactions;
//         _isLoading = false;
//         _error = null;
//         applyFilters();
//         notifyListeners();
//       },
//       onError: (error) {
//         _error = error.toString();
//         _isLoading = false;
//         notifyListeners();
//       },
//     );
//   }

//   // Add transaction with haptic feedback
//   Future<void> addTransaction({
//     required double amount,
//     required String description,
//     required ExpenseCategory category,
//     required TransactionType type,
//     DateTime? date,
//   }) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       String? receiptPath;
//       if (_receiptImage != null) {
//         receiptPath = await _cameraService.saveReceiptLocally(_receiptImage!);
//       }

//       final transaction = TransactionModel(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         userId: _firebaseService.userId ?? '',
//         amount: amount,
//         description: description,
//         category: category,
//         type: type,
//         date: date ?? DateTime.now(),
//         receiptUrl: receiptPath,
//       );

//       await _firebaseService.addTransaction(transaction);
      
//       // Haptic feedback on success
//       if (await Vibration.hasVibrator() ?? false) {
//         Vibration.vibrate(duration: 50);
//       }
      
//       _receiptImage = null;
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = 'Failed to add transaction: $e';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Update transaction
//   Future<void> updateTransaction(TransactionModel transaction) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       await _firebaseService.updateTransaction(transaction);
      
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _error = 'Failed to update transaction: $e';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Delete with swipe gesture support
//   Future<void> deleteTransaction(String transactionId) async {
//     try {
//       // Haptic feedback before delete
//       if (await Vibration.hasVibrator() ?? false) {
//         Vibration.vibrate(pattern: [0, 50, 100, 50]);
//       }

//       await _firebaseService.deleteTransaction(transactionId);
//     } catch (e) {
//       _error = 'Failed to delete transaction: $e';
//       notifyListeners();
//     }
//   }

//   // Camera functions
//   Future<void> captureReceipt() async {
//     _receiptImage = await _cameraService.captureReceipt();
//     notifyListeners();
//   }

//   Future<void> pickReceiptFromGallery() async {
//     _receiptImage = await _cameraService.pickReceiptFromGallery();
//     notifyListeners();
//   }

//   void clearReceipt() {
//     _receiptImage = null;
//     notifyListeners();
//   }

//   // Filters
//   void setSelectedCategory(ExpenseCategory? category) {
//     _selectedCategory = category;
//     applyFilters();
//     notifyListeners();
//   }

//   void setSelectedDate(DateTime date) {
//     _selectedDate = date;
//     applyFilters();
//     notifyListeners();
//   }

//   void applyFilters() {
//     _filteredTransactions = _transactions.where((transaction) {
//       bool categoryMatch = _selectedCategory == null || 
//                           transaction.category == _selectedCategory;
//       bool dateMatch = transaction.date.year == _selectedDate.year && 
//                       transaction.date.month == _selectedDate.month;
      
//       return categoryMatch && dateMatch;
//     }).toList();
//   }

//   void clearFilters() {
//     _selectedCategory = null;
//     _selectedDate = DateTime.now();
//     _filteredTransactions = [];
//     notifyListeners();
//   }

//   // Analytics
//   Map<ExpenseCategory, double> getCategoryBreakdown() {
//     Map<ExpenseCategory, double> breakdown = {};
    
//     for (var transaction in _transactions) {
//       if (transaction.type == TransactionType.expense) {
//         breakdown[transaction.category] = 
//             (breakdown[transaction.category] ?? 0) + transaction.amount;
//       }
//     }
    
//     return breakdown;
//   }

//   List<TransactionModel> getRecentTransactions({int limit = 5}) {
//     return _transactions.take(limit).toList();
//   }
// }