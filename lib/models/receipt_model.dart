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

  // Factory constructor to deserialize JSON response from the API
  factory ReceiptModel.fromJson(Map<String, dynamic> json, String imagePath) {
    return ReceiptModel(
      storeName: json['storeName'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      categoryName: json['category'] as String?,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.tryParse(json['purchaseDate'])
          : null,
      originalImagePath: imagePath,
      rawOcrText: null, 
    );
  }

  static ReceiptModel empty(String imagePath) {
    return ReceiptModel(
      storeName: 'Processing...',
      totalAmount: 0.0,
      categoryName: 'other',
      purchaseDate: DateTime.now(),
      originalImagePath: imagePath,
      rawOcrText: '',
    );
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