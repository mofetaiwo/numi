import 'package:flutter_test/flutter_test.dart';
import 'package:numi/viewmodels/transaction_viewmodel.dart';
import 'package:numi/models/transaction_model.dart';

void main() {
  group('TransactionViewModel Tests', () {
    late TransactionViewModel viewModel;

    setUp(() {
      viewModel = TransactionViewModel();
    });

    test('Initial state should be correct', () {
      expect(viewModel.transactions, isEmpty);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, isNull);
      expect(viewModel.totalIncome, equals(0.0));
      expect(viewModel.totalExpenses, equals(0.0));
      expect(viewModel.balance, equals(0.0));
    });

    test('Category filter should work correctly', () {
      viewModel.setSelectedCategory(ExpenseCategory.food);
      expect(viewModel.selectedCategory, equals(ExpenseCategory.food));
    });

    test('Clear filters should reset state', () {
      viewModel.setSelectedCategory(ExpenseCategory.food);
      viewModel.clearFilters();
      expect(viewModel.selectedCategory, isNull);
      expect(viewModel.selectedDate.month, equals(DateTime.now().month));
    });
  });
}