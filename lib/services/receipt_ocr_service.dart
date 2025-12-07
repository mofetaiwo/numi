import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import '../models/receipt_model.dart';
import 'package:image/image.dart' as img;

class TesseractService {
    static const String _language = 'eng';
    static const String _languageDataPath = 'assets/tessdata/$_language.traineddata';
    
    static bool _isInitialized = false;
    static String? _tessDataPath;

    static const int _targetWidth = 1500;

    /// Loads the Tessract training data for English
    Future<String> initializeTesseract() async {
        if (_isInitialized && _tessDataPath != null) {
            return _tessDataPath!;
        }

        try {
            final dir = await getApplicationDocumentsDirectory();
            final tessdataDir = Directory('${dir.path}/tessdata');
            if (!await tessdataDir.exists()) {
                await tessdataDir.create(recursive: true);
            }
            
            final filePath = '${tessdataDir.path}/$_language.traineddata';
            
            if (!await File(filePath).exists()) {
                final data = await rootBundle.load(_languageDataPath);
                final bytes = data.buffer.asUint8List();

                await File(filePath).writeAsBytes(bytes);
            }
            
            _tessDataPath = tessdataDir.path;
            _isInitialized = true;
            return _tessDataPath!;

        } catch (e) {
            // Clear path on failure
            _tessDataPath = null; 
            throw Exception('Failed to initialize Tesseract data files. Check assets/tessdata/ folder: $e');
        }
    }

    /// Resizing image to improve runtime
    Future<String> _preprocessImage(String imagePath) async {
        final imageFile = File(imagePath);
        
        img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());

        if (originalImage == null) {
            throw Exception('Failed to decode image for preprocessing.');
        }

        // Only resize if the image is wider than the target
        if (originalImage.width > _targetWidth) {
            final resizedImage = img.copyResize(originalImage, width: _targetWidth);
            
            final dir = await getTemporaryDirectory();
            final tempPath = '${dir.path}/resized_ocr_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final tempFile = File(tempPath);
            
            await tempFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 90));
            
            // Return the path to the resized (pre-processed) image
            return tempPath; 
        }

        // If no resizing is needed, return the original path
        return imagePath;
    }

    /// Runs Tesseract OCR on a given image file path.
    Future<String> runOcr(String imagePath) async {
    String? dataPath;

    try {
        // Attempt initialization
        dataPath = await initializeTesseract();
        final String preprocessedPath = await _preprocessImage(imagePath);

        // Check for initialization failure
        if (dataPath == "") {
            throw Exception('Tesseract initialization failed to provide a valid data path.');
        }

        final String result = await FlutterTesseractOcr.extractText(
            preprocessedPath,
            language: _language,
            args: {
                "psm": "6",
                "TESSDATA_PREFIX": dataPath,
                "load_system_dawg": "0", 
                "load_freq_dawg": "0",
                "preserve_interword_spaces": "0",
            }
        );

        return result;

    } catch (e) {
        throw Exception('OCR Operation Failed: $e');
    }
}
    /// This OCR processing definity needs some work if this was a real released app.
    /// If this was a real app, I would recommend the company fine-tune their own Computer Vision
    /// model and ensure the privacy of their users receipts.
    /// Takes the raw OCR text and attempts to parse it into a structured ReceiptModel.
    ReceiptModel parseOcrResult(String ocrText, String originalPath) {
        // Basic text cleanup and splitting
        final cleanedText = ocrText.replaceAll(RegExp(r'[^\w\s\$\.\:]'), ' ').toUpperCase();
        final lines = cleanedText.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

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
        
        String storeName = 'Unknown Vendor';
        double bestScore = -1.0; 
        
        // Aggressive Regex to check for common non-vendor lines (dates, addresses, phone numbers, employee/txn IDs, noise)
        final aggressiveNonVendorRegex = RegExp(
            r'(\d{4}[-\/]\d{2}[-\/]\d{2})|' + // Date format
            r'(\d{5})|' + // 5-digit zip code
            r'(PHONE|TEL|FAX|VAT|TAX ID|WWW|STREET|AVENUE|ROAD|BLVD|AVE|ST|BACK|RECEIPT|CASHIER|MANAGER|ORDER|TRANSACTION|ID|OP|CUST|VISA|MASTERCARD)' // Added many noise keywords
        );

        // Regex to detect likely junk/serial numbers (single word, high letters, but no spaces)
        final junkWordRegex = RegExp(r'^\w{6,20}$'); // 6 to 20 letters/digits, no spaces

        if (lines.isNotEmpty) {
            // Search the footer for a "Thank You" message
            final thankYouRegex = RegExp(r'THANK YOU (FOR SHOPPING AT|AT) (.*)');
            
            // Check the last 5 lines for the thank you message
            final footerLines = lines.sublist(lines.length > 5 ? lines.length - 5 : 0).toList();

            for (var line in footerLines) {
                final match = thankYouRegex.firstMatch(line);
                if (match != null) {
                    // Extract the text after the "SHOPPING AT" or "AT"
                    final extractedName = match.group(2)?.trim();
                    if (extractedName != null && extractedName.length > 2) {
                        storeName = extractedName.replaceAll(RegExp(r'[^\w\s]'), ' ').trim();
                        bestScore = 1.0; // Mark as highly confident
                        break;
                    }
                }
            }

            // If no store name was found in the footer, score the top lines
            if (bestScore < 0.0) {
                String bestCandidate = '';
                int bestCandidateIndex = -1;

                // Score the top 10 lines for best text density
                for (int i = 0; i < lines.length && i < 10; i++) {
                    final line = lines[i];

                    // Heuristics Check:
                    // 1. Must be reasonably long (> 4 characters) and contain letters
                    // 2. Must not match known noise patterns
                    // 3. Must not be a single long junk word (like DBANAMA)
                    if (line.length > 4 
                        && line.contains(RegExp(r'[A-Z]')) 
                        && !aggressiveNonVendorRegex.hasMatch(line)
                        && !junkWordRegex.hasMatch(line)
                    ) {
                        
                        // Calculate score: Ratio of letters to total length
                        final letterCount = line.replaceAll(RegExp(r'[^A-Z]'), '').length;
                        final score = letterCount / line.length;

                        // Prioritize candidates with a high text density (score > 0.5)
                        if (score > 0.5 && score > bestScore) {
                            bestScore = score;
                            bestCandidate = line.trim();
                            bestCandidateIndex = i;
                        }
                    }
                }
                
                // If a high-scoring candidate is found, attempt concatenation
                if (bestScore > 0.5) {
                    storeName = bestCandidate;

                    // Attempt concatenation only if the best candidate index is valid and there's a next line
                    if (bestCandidateIndex != -1 && bestCandidateIndex + 1 < lines.length && bestCandidateIndex + 1 < 10) {
                        final nextLine = lines[bestCandidateIndex + 1];
                        final combinedLine = '$bestCandidate $nextLine';
                        
                        // Recalculate score for the combined line
                        final combinedLetterCount = combinedLine.replaceAll(RegExp(r'[^A-Z]'), '').length;
                        final combinedScore = combinedLetterCount / combinedLine.length;

                        // Check if the next line is also clean and the combined score is better than or equal to the single line score
                        // We also check length to prevent merging a good name with a huge address block
                        if (nextLine.length > 3 
                            && !aggressiveNonVendorRegex.hasMatch(nextLine) 
                            && combinedLine.length < 35 
                            && combinedScore >= bestScore
                        ) {
                            storeName = combinedLine.trim();
                        }
                    }

                } else if (lines.first.length > 5 && lines.first.contains(RegExp(r'[A-Z]'))) {
                    // Fallback: use the very first line if all other filtering failed
                    storeName = lines.first;
                }
            }
            
            // Final cleanup: remove all non-word/space chars (like pipes) from the edges
            storeName = storeName.replaceAll(RegExp(r'[^\w\s]'), ' ').trim();
        }

        debugPrint('Raw OCR Text:\n$ocrText');
        debugPrint('Extracted Store Name: $storeName'); // Log the extracted name

        // Create the Receipt Model
        return ReceiptModel(
            storeName: storeName,
            totalAmount: totalAmount,
            originalImagePath: originalPath,
            rawOcrText: ocrText, // Keep raw text for debugging/verification
        );
    }
}