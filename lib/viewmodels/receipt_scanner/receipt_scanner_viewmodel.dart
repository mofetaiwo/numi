import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/receipt_model.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../services/receipt_ocr_service.dart';

class ReceiptScannerViewModel extends ChangeNotifier {
  final TesseractService _ocrService;
  final ITransactionRepository _transactionRepository;
  
  ReceiptModel? _receiptData;
  bool _isLoading = false;
  String? _errorMessage;

  ReceiptModel? get receiptData => _receiptData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReceiptScannerViewModel(this._ocrService, this._transactionRepository);

  /// Starts the OCR process on the given image path.
  Future<void> startProcessing(String imagePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Set initial data state before starting to process
    _receiptData = ReceiptModel.empty(imagePath);
    notifyListeners();

    try {
      final data = await _ocrService.runOcr(imagePath);

      _receiptData = _ocrService.parseOcrResult(data, imagePath);
    } catch (e) {
      _errorMessage = e.toString().contains('Exception:') ? e.toString().split('Exception: ')[1] : 'Failed to extract receipt data.';
      _receiptData = null; // Clear data on failure
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the raw data after the user edits the fields.
  void updateReceiptData(ReceiptModel updatedData) {
    _receiptData = updatedData;
    notifyListeners();
  }

  /// Converts the RawReceiptModel into a final TransactionModel and saves it.
  Future<bool> saveFinalExpense({
    required ReceiptModel data,
    required ExpenseCategory category, // User-selected category
  }) async {
    if (data.totalAmount == null || data.totalAmount! <= 0) {
      _errorMessage = 'Total amount cannot be zero.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create the final TransactionModel
      final newTransaction = TransactionModel(
        id: const Uuid().v4(), // Generate unique ID for mock repository
        userId: 'mock-user-123', // Mock User ID
        amount: data.totalAmount!,
        description: data.storeName ?? 'Receipt Expense',
        category: category, 
        type: TransactionType.expense,
        date: data.purchaseDate ?? DateTime.now(),
        // Note: In a real app, receiptUrl would point to a storage bucket (e.g., Firebase Storage)
        receiptUrl: data.originalImagePath, // Using local path as mock URL
        metadata: {'ocr_raw_text': data.rawOcrText},
      );

      await _transactionRepository.saveTransaction(newTransaction);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save transaction: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}