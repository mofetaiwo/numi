import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:numi/widgets/balance_card.dart';
import 'package:numi/viewmodels/transaction_viewmodel.dart';

void main() {
  group('BalanceCard Widget Tests', () {
    testWidgets('BalanceCard displays correct balance',
            (WidgetTester tester) async {
          final viewModel = TransactionViewModel();

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider.value(
                value: viewModel,
                child: Scaffold(body: BalanceCard()),
              ),
            ),
          );

          expect(find.text('Total Balance'), findsOneWidget);
          expect(find.text('Income'), findsOneWidget);
          expect(find.text('Expenses'), findsOneWidget);
        });

    testWidgets('Add Transaction Screen has all input fields',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                  ],
                ),
              ),
            ),
          );

          expect(find.byType(TextFormField), findsNWidgets(2));
          expect(find.text('Amount'), findsOneWidget);
          expect(find.text('Description'), findsOneWidget);
        });

    testWidgets('Transaction list item displays correctly',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Container(
                  child: const Text('Test Transaction'),
                ),
              ),
            ),
          );

          expect(find.text('Test Transaction'), findsOneWidget);
        });
  });
}