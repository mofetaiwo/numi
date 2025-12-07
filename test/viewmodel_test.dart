import 'package:flutter_test/flutter_test.dart';
import 'package:numi/models/transaction_model.dart';
import 'package:numi/models/budget_model.dart';

// Mock ViewModel for testing core business logic without Firebase
class MockTransactionViewModel {
  List<TransactionModel> transactions = [];
  bool isLoading = false;
  String? error;
  ExpenseCategory? selectedCategory;
  TransactionType? selectedType;
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpenses;

  List<TransactionModel> get filteredTransactions {
    return transactions.where((transaction) {
      // Category filter
      if (selectedCategory != null && transaction.category != selectedCategory) {
        return false;
      }

      // Type filter
      if (selectedType != null && transaction.type != selectedType) {
        return false;
      }

      // Search filter
      if (searchQuery.isNotEmpty &&
          !transaction.description.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }

      // Date filter (same month/year)
      if (transaction.date.month != selectedDate.month ||
          transaction.date.year != selectedDate.year) {
        return false;
      }

      return true;
    }).toList();
  }

  Map<ExpenseCategory, double> getCategoryBreakdown() {
    final Map<ExpenseCategory, double> breakdown = {};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        breakdown[transaction.category] =
            (breakdown[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return breakdown;
  }

  void addTransaction(TransactionModel transaction) {
    transactions.add(transaction);
  }

  void deleteTransaction(String id) {
    transactions.removeWhere((t) => t.id == id);
  }

  void setFilters({
    ExpenseCategory? category,
    TransactionType? type,
    String? search,
    DateTime? date,
  }) {
    if (category != null) selectedCategory = category;
    if (type != null) selectedType = type;
    if (search != null) searchQuery = search;
    if (date != null) selectedDate = date;
  }

  void clearFilters() {
    selectedCategory = null;
    selectedType = null;
    searchQuery = '';
    selectedDate = DateTime.now();
  }
}

void main() {
  group('TransactionViewModel Unit Test', () {
    late MockTransactionViewModel viewModel;

    setUp(() {
      viewModel = MockTransactionViewModel();

      // Add test data
      viewModel.addTransaction(TransactionModel(
        id: '1',
        userId: 'test',
        amount: 2000.0,
        type: TransactionType.income,
        category: ExpenseCategory.other,
        description: 'Salary',
        date: DateTime.now(),
      ));

      viewModel.addTransaction(TransactionModel(
        id: '2',
        userId: 'test',
        amount: 50.0,
        type: TransactionType.expense,
        category: ExpenseCategory.food,
        description: 'Groceries',
        date: DateTime.now(),
      ));

      viewModel.addTransaction(TransactionModel(
        id: '3',
        userId: 'test',
        amount: 30.0,
        type: TransactionType.expense,
        category: ExpenseCategory.transport,
        description: 'Bus fare',
        date: DateTime.now(),
      ));

      viewModel.addTransaction(TransactionModel(
        id: '4',
        userId: 'test',
        amount: 100.0,
        type: TransactionType.expense,
        category: ExpenseCategory.food,
        description: 'Restaurant',
        date: DateTime.now(),
      ));

      viewModel.addTransaction(TransactionModel(
        id: '5',
        userId: 'test',
        amount: 500.0,
        type: TransactionType.income,
        category: ExpenseCategory.other,
        description: 'Freelance',
        date: DateTime.now().subtract(Duration(days: 35)), // Last month
      ));
    });

    test('ViewModel calculates totals and filters correctly', () {
      // Test initial calculations
      expect(viewModel.totalIncome, equals(2500.0));
      expect(viewModel.totalExpenses, equals(180.0));
      expect(viewModel.balance, equals(2320.0));
      expect(viewModel.transactions.length, equals(5));


      // Test category breakdown
      final breakdown = viewModel.getCategoryBreakdown();
      expect(breakdown[ExpenseCategory.food], equals(150.0));
      expect(breakdown[ExpenseCategory.transport], equals(30.0));

      // Test filtering by category
      viewModel.setFilters(category: ExpenseCategory.food);
      expect(viewModel.filteredTransactions.length, equals(2));
      expect(viewModel.filteredTransactions.every((t) => t.category == ExpenseCategory.food), isTrue);

      // Test filtering by type
      viewModel.clearFilters();
      viewModel.setFilters(type: TransactionType.income);
      expect(viewModel.filteredTransactions.length, equals(1));
      expect(viewModel.filteredTransactions.first.description, equals('Salary'));

      // Test search functionality
      viewModel.clearFilters();
      viewModel.setFilters(search: 'bus');
      expect(viewModel.filteredTransactions.length, equals(1));
      expect(viewModel.filteredTransactions.first.description, equals('Bus fare'));

      // Test combined filters
      viewModel.clearFilters();
      viewModel.setFilters(
        category: ExpenseCategory.food,
        type: TransactionType.expense,
        search: 'groceries',
      );
      expect(viewModel.filteredTransactions.length, equals(1));
      expect(viewModel.filteredTransactions.first.amount, equals(50.0));

      // Test delete transaction
      final initialCount = viewModel.transactions.length;
      viewModel.deleteTransaction('1');
      expect(viewModel.transactions.length, equals(initialCount - 1));
      expect(viewModel.transactions.any((t) => t.id == '1'), isFalse);

      // Test that last month's transaction is not in filtered (current month)
      viewModel.clearFilters();
      expect(viewModel.filteredTransactions.any((t) => t.description == 'Freelance'), isFalse);
    });
  });
}