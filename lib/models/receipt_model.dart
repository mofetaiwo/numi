import 'transaction_model.dart';

class ReceiptModel {
  final String? storeName;
  final double? totalAmount;
  final String? categoryName;
  final DateTime? purchaseDate;
  final String? originalImagePath;
  final String? rawOcrText;

  ReceiptModel({
    this.storeName,
    this.totalAmount,
    this.categoryName,
    this.purchaseDate,
    this.originalImagePath,
    this.rawOcrText,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json, String imagePath) {
    return ReceiptModel(
      storeName: json['storeName'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      // Category is left blank or set to a default, as the user will assign it manually
      categoryName: null, 
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.tryParse(json['purchaseDate'])
          : null,
      originalImagePath: imagePath,
      rawOcrText: null, // No need to store raw OCR text if structured data is parsed
    );
  }

  static ReceiptModel empty(String imagePath) {
    return ReceiptModel(
      storeName: 'Processing...',
      totalAmount: 0.0,
      categoryName: ExpenseCategory.other.toString().split('.').last, // Default to 'other' initially
      purchaseDate: DateTime.now(),
      originalImagePath: imagePath,
      rawOcrText: '',
    );
  }
  
  static ExpenseCategory categoryFromString(String categoryString) {
    try {
      // Normalize input string (e.g., 'Groceries' -> 'groceries')
      final normalized = categoryString.toLowerCase().trim();
      
      // Attempt to find the matching enum value
      return ExpenseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == normalized,
        // Default to 'other' if no match is found
        orElse: () => ExpenseCategory.other,
      );
    } catch (e) {
      // Fallback in case of any unexpected error
      return ExpenseCategory.other;
    }
  }

  ReceiptModel copyWith({
    String? storeName,
    double? totalAmount,
    String? categoryName,
    DateTime? purchaseDate,
  }) {
    return ReceiptModel(
      storeName: storeName ?? this.storeName,
      totalAmount: totalAmount ?? this.totalAmount,
      categoryName: categoryName ?? this.categoryName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      originalImagePath: this.originalImagePath,
      rawOcrText: this.rawOcrText,
    );
  }
}