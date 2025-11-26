import 'package:flutter/material.dart';
import '../../models/receipt_model.dart';
import '../../models/transaction_model.dart'; 
import '../../repositories/transaction_repository.dart';
import '../../viewmodels/receipt_scanner_viewmodel.dart';


class ReceiptVerificationPage extends StatelessWidget {
  final ReceiptModel receiptData;
  const ReceiptVerificationPage({required this.receiptData, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Details (Verification)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data received from ViewModel:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Store: ${receiptData.storeName}'),
              Text('Total: \$${receiptData.totalAmount?.toStringAsFixed(2)}'),
              Text('Image Path: ${receiptData.originalImagePath}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Confirm & Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}