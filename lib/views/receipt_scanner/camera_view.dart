// lib/pages/receipt_scanner/camera.dart

import 'package:flutter/material.dart';
import '../../viewmodels/receipt_scanner/receipt_scanner_viewmodel.dart';
import 'receipt_verification.dart'; 
import '../../services/receipt_ocr_service.dart';
import '../../repositories/transaction_repository.dart';

// Class renamed to match usage in camera_permission.dart
class CameraViewPage extends StatelessWidget {
  const CameraViewPage({super.key});

  // Note: In a real app, the ViewModel would be accessed via Provider/Riverpod
  // from the widget tree, not instantiated here.
  ReceiptScannerViewModel _getViewModel(BuildContext context) {
    // Instantiate dependencies locally for this mock setup
    final ocrService = TesseractService();
    final transactionRepository = MockTransactionRepository();
    return ReceiptScannerViewModel(ocrService, transactionRepository);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _getViewModel(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      // body: Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       // --- Placeholder for Camera Preview ---
      //       const Icon(Icons.camera_alt, size: 100, color: Colors.grey),
      //       const Text('Live Camera Viewfinder Placeholder (Tap button below to capture)'),
      //       const SizedBox(height: 32),
            
      //       // --- Capture Button ---
      //       ElevatedButton.icon(
      //         icon: const Icon(Icons.camera),
      //         label: const Text('Capture Receipt'),
      //         onPressed: () async {
      //           // MOCK: This path is passed to the Tesseract simulation service
      //           final mockImagePath = '/data/user/0/com.appname/cache/receipt_temp_123.jpg'; 
                
      //           // 1. Call the ViewModel to start the OCR process
      //           await viewModel.startProcessing(mockImagePath);

      //           // 2. Navigate to the review screen
      //           if (viewModel.errorMessage == null && viewModel.receiptData != null) {
      //               Navigator.of(context).pushReplacement( // Use pushReplacement to prevent going back to camera
      //                 MaterialPageRoute(
      //                   builder: (context) => ReceiptDetailsPage(viewModel: viewModel),
      //                 ),
      //               );
      //           } else {
      //             // Show error to the user (e.g., a Snackbar)
      //             ScaffoldMessenger.of(context).showSnackBar(
      //               SnackBar(content: Text(viewModel.errorMessage ?? 'OCR processing failed.')),
      //             );
      //           }
      //         },
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}