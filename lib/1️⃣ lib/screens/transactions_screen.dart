import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  static const routeName = '/transactions';

  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: const Center(
        child: Text('Transactions Screen Placeholder'),
      ),
    );
  }
}
