import 'package:flutter/material.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state.dart';

class TransactionsScreen extends StatefulWidget {
  static const routeName = '/transactions';

  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // fake in-memory sample transactions – can be wired to real data later
  final List<_TransactionItem> _transactions = [
    _TransactionItem(
      category: 'Food',
      date: DateTime.now().subtract(const Duration(days: 1)),
      amount: 24.99,
      isIncome: false,
    ),
    _TransactionItem(
      category: 'Rent',
      date: DateTime.now().subtract(const Duration(days: 3)),
      amount: 900,
      isIncome: false,
    ),
    _TransactionItem(
      category: 'Salary',
      date: DateTime.now().subtract(const Duration(days: 5)),
      amount: 1500,
      isIncome: true,
    ),
  ];

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_transactions.isEmpty) {
      child = const EmptyState(
        message: 'No transactions yet.\nAdd one from the home screen.',
        icon: Icons.money_off,
      );
    } else {
      child = ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final tx = _transactions[index];
          return Dismissible(
            key: ValueKey(tx.hashCode),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.red[300],
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              setState(() {
                _transactions.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction deleted')),
              );
            },
            child: TransactionTile(
              category: tx.category,
              date: tx.date,
              amount: tx.amount,
              isIncome: tx.isIncome,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${tx.category}: \$${tx.amount.toStringAsFixed(2)}',
                    ),
                    duration: const Duration(milliseconds: 900),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
        ),
      ),
    );
  }
}

class _TransactionItem {
  final String category;
  final DateTime date;
  final double amount;
  final bool isIncome;

  _TransactionItem({
    required this.category,
    required this.date,
    required this.amount,
    required this.isIncome,
  });
}
