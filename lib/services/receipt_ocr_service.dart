import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import '../models/receipt_model.dart';

class TesseractService {
  // --- Tesseract Configuration ---

  static const String _language = 'eng';
  static const String _languageDataPath = 'assets/tessdata/$_language.traineddata';
  
  // A variable to track if the language data has been initialized
  static bool _isInitialized = false;
  // NEW: Variable to store the explicit path where the trained data lives
  static String? _tessDataPath;

  // --- Initialization Method ---

  /// Ensures the Tesseract language data file is copied from assets 
  /// to the application's documents directory where Tesseract can access it.
  Future<String> initializeTesseract() async {
    if (_isInitialized && _tessDataPath != null) {
      return _tessDataPath!; // Return stored path if already initialized
    }

    try {
      // 1. Get the application's documents directory
      final dir = await getApplicationDocumentsDirectory();
      final tessdataDir = Directory('${dir.path}/tessdata');
      if (!await tessdataDir.exists()) {
        await tessdataDir.create(recursive: true);
      }
      
      final filePath = '${tessdataDir.path}/$_language.traineddata';
      
      // 2. Check if the file already exists to avoid unnecessary copy
      if (!await File(filePath).exists()) {
        // 3. Load the file bytes from assets
        final data = await rootBundle.load(_languageDataPath);
        final bytes = data.buffer.asUint8List();

        // 4. Write the bytes to the documents directory
        await File(filePath).writeAsBytes(bytes);
      }
      
      _tessDataPath = tessdataDir.path; // Store the successful path
      _isInitialized = true;
      return _tessDataPath!; // Return the path where the language data is located

    } catch (e) {
      print('Error initializing Tesseract: $e');
      // Clear path on failure
      _tessDataPath = null; 
      throw Exception('Failed to initialize Tesseract data files. Check assets/tessdata/ folder: $e');
    }
  }

  // --- OCR Execution Method ---

  /// Runs Tesseract OCR on a given image file path.
  Future<String> runOcr(String imagePath) async {
  // --- STEP 1: Log Function Entry ---
  // If you see this, the function was called.
  debugPrint('--- OCR Service: Starting runOcr function ---'); 
  debugPrint('Input imagePath: $imagePath'); 

  String? dataPath;

  try {
    // Attempt initialization
    dataPath = await initializeTesseract();
    
    // Check for initialization failure
    if (dataPath == null) {
      debugPrint('!!! ERROR: Tesseract initialization returned NULL dataPath.');
      throw Exception('Tesseract initialization failed to provide a valid data path.');
    }

    // --- STEP 2: Your original missing log line ---
    // If you see this, initialization succeeded.
    debugPrint('TESSDATA_PREFIX (dataPath): $dataPath'); 

    // --- STEP 3: Execute OCR ---
    final String result = await FlutterTesseractOcr.extractText(
      imagePath,
      language: _language,
      args: {
        "psm": "6",
        "TESSDATA_PREFIX": dataPath,
      }
    );

    // --- STEP 4: Log Success ---
    debugPrint('OCR SUCCESS. Extracted Text (first 50 chars): ${result.substring(0, result.length < 50 ? result.length : 50)}'); 
    return result;

  } catch (e, stack) {
    // --- STEP 5: Log ANY Failure ---
    debugPrint('!!! CRITICAL OCR FAILURE !!!');
    debugPrint('Exception: $e');
    debugPrint('StackTrace: $stack');
    
    // Re-throw the exception so the caller knows the operation failed
    throw Exception('OCR Operation Failed: $e');
  }
}

  // --- Data Parsing Method ---

  /// Takes the raw OCR text and attempts to parse it into a structured ReceiptModel.
  ReceiptModel parseOcrResult(String ocrText, String originalPath) {
    // Basic text cleanup and splitting
    final cleanedText = ocrText.replaceAll(RegExp(r'[^\w\s\$\.\:]'), ' ').toUpperCase();
    final lines = cleanedText.split('\n').map((line) => line.trim()).toList();

    // --- Parsing Logic ---
    
    // 1. Find Total Amount (most critical)
    double? totalAmount;
    // Enhanced regex to handle common OCR mistakes like O for 0, A for 4, and common total prefixes
    final totalRegex = RegExp(r'(TOTAL|AMOUNT DUE|BALANCE|T[O0][T][A4][L]|SUM)\s*[:\$]?\s*(\d+[\.,]\d{2})');
    
    for (var line in lines.reversed) { // Start from the bottom of the receipt
      final match = totalRegex.firstMatch(line);
      if (match != null) {
        // Replace comma with dot if locale uses comma for decimal separator
        final amountString = match.group(2)?.replaceAll(',', '.'); 
        totalAmount = double.tryParse(amountString ?? '');
        if (totalAmount != null) break;
      }
    }
    
    // 2. Find Store Name (simple mock for demonstration)
    String storeName = 'Unknown Vendor';
    if (lines.isNotEmpty) {
        // Assume the first few lines are header/store info, ignore purely numeric lines
        storeName = lines.take(5).firstWhere(
            (line) => line.length > 5 && !RegExp(r'^\d+[\.\,]?\d*$').hasMatch(line), // Exclude lines that are just numbers (like totals)
            orElse: () => 'OCR Vendor'
        );
    }

    debugPrint('Raw OCR Text:\n$ocrText');

    // 3. Create the Receipt Model
    return ReceiptModel(
      storeName: storeName,
      totalAmount: totalAmount,
      originalImagePath: originalPath,
      rawOcrText: ocrText, // Keep raw text for debugging/verification
    );
  }
}