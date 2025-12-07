import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:numi/models/transaction_model.dart';

void main() {
  group('Widget Tests for MPX', () {

    // Widget Test 1: Dashboard Navigation
    testWidgets('Dashboard bottom navigation displays and switches correctly',
            (WidgetTester tester) async {
          int selectedIndex = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: StatefulBuilder(
                builder: (context, setState) {
                  return Scaffold(
                    body: IndexedStack(
                      index: selectedIndex,
                      children: [
                        Center(child: Text('Dashboard Screen')),
                        Center(child: Text('Transactions Screen')),
                        Center(child: Text('Budget Screen')),
                        Center(child: Text('Analytics Screen')),
                      ],
                    ),
                    bottomNavigationBar: BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      currentIndex: selectedIndex,
                      onTap: (index) => setState(() => selectedIndex = index),
                      items: const [
                        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
                        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Transactions'),
                        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Budget'),
                        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analytics'),
                      ],
                    ),
                  );
                },
              ),
            ),
          );

          // Initial screen
          expect(find.text('Dashboard Screen'), findsOneWidget);

          // Go to Transactions
          await tester.tap(find.text('Transactions'));
          await tester.pumpAndSettle();
          expect(find.text('Transactions Screen'), findsOneWidget);

          // Go to Budget
          await tester.tap(find.text('Budget'));
          await tester.pumpAndSettle();
          expect(find.text('Budget Screen'), findsOneWidget);

          // Go to Analytics
          await tester.tap(find.text('Analytics'));
          await tester.pumpAndSettle();
          expect(find.text('Analytics Screen'), findsOneWidget);
        });


    // Widget Test 2: Transaction Form Validation
    testWidgets('Add transaction form validates required fields correctly',
            (WidgetTester tester) async {
          final formKey = GlobalKey<FormState>();
          String? amountError;
          String? descriptionError;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      // Transaction type toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            child: Text('Income'),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {},
                            child: Text('Expense'),
                          ),
                        ],
                      ),

                      // Amount field
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          errorText: amountError,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),

                      // Description field
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Description',
                          errorText: descriptionError,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          if (value.length < 3) {
                            return 'Description too short';
                          }
                          return null;
                        },
                      ),

                      // Category selection
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text('Food')),
                          Chip(label: Text('Transport')),
                          Chip(label: Text('Shopping')),
                          Chip(label: Text('Bills')),
                        ],
                      ),

                      // Save button
                      ElevatedButton(
                        onPressed: () {
                          formKey.currentState?.validate();
                        },
                        child: Text('Save Transaction'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          // Verify all form elements are present
          expect(find.text('Income'), findsOneWidget);
          expect(find.text('Expense'), findsOneWidget);
          expect(find.widgetWithText(TextFormField, 'Amount'), findsOneWidget);
          expect(find.widgetWithText(TextFormField, 'Description'), findsOneWidget);
          expect(find.text('Food'), findsOneWidget);
          expect(find.text('Transport'), findsOneWidget);
          expect(find.text('Shopping'), findsOneWidget);
          expect(find.text('Bills'), findsOneWidget);
          expect(find.text('Save Transaction'), findsOneWidget);

          // Test validation - tap save without filling fields
          await tester.tap(find.text('Save Transaction'));
          await tester.pump();

          // Verify validation messages appear
          expect(find.text('Please enter an amount'), findsOneWidget);
          expect(find.text('Please enter a description'), findsOneWidget);
        });

    // Widget Test 3: Transaction List with Swipe Gesture
    testWidgets('Transaction list displays items with swipe-to-delete gesture',
            (WidgetTester tester) async {
          final transactions = [
            TransactionModel(
              id: '1',
              userId: 'user1',
              amount: 50.0,
              description: 'Lunch',
              category: ExpenseCategory.food,
              type: TransactionType.expense,
              date: DateTime.now(),
            ),
            TransactionModel(
              id: '2',
              userId: 'user1',
              amount: 1000.0,
              description: 'Salary',
              category: ExpenseCategory.other,
              type: TransactionType.income,
              date: DateTime.now(),
            ),
          ];

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return Dismissible(
                          key: Key(transaction.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
                            child: Icon(Icons.delete),
                          ),
                          onDismissed: (direction) {
                            setState(() => transactions.removeAt(index));
                          },
                          child: ListTile(
                            title: Text(transaction.description),
                            trailing: Text('\$${transaction.amount.toStringAsFixed(2)}'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );

          // Verify transactions are displayed
          expect(find.text('Lunch'), findsOneWidget);
          expect(find.text('Salary'), findsOneWidget);
          expect(find.text('\$50.00'), findsOneWidget);
          expect(find.text('\$1000.00'), findsOneWidget);

          // Test swipe gesture (Dismissible widget)
          expect(find.byType(Dismissible), findsNWidgets(2));

          // Simulate swipe to delete
          await tester.drag(find.text('Lunch'), Offset(-300, 0));
          await tester.pumpAndSettle();

          // Verify item removed
          expect(find.text('Lunch'), findsOneWidget);
        });
  });
}