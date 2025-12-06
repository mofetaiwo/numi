import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  final String category;
  final DateTime date;
  final double amount;
  final bool isIncome;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.category,
    required this.date,
    required this.amount,
    required this.isIncome,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amountText =
        '${isIncome ? '+' : '-'}\$${amount.toStringAsFixed(2)}';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncome ? Colors.green[700] : Colors.red[700],
          size: 18,
        ),
      ),
      title: Text(category),
      subtitle: Text(
        '${date.month}/${date.day}/${date.year}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        amountText,
        style: TextStyle(
          color: isIncome ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
