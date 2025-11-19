import 'package:flutter/foundation.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';

class BudgetViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;
  
  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _error;

  BudgetViewModel({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService() {
    loadBudgets();
  }

  // Getters
  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _budgets.isEmpty && !_isLoading;

  double get totalBudgetLimit {
    return _budgets.fold(0.0, (sum, budget) => sum + budget.limit);
  }

  double get totalBudgetSpent {
    return _budgets.fold(0.0, (sum, budget) => sum + budget.spent);
  }

  List<BudgetModel> get overBudgetCategories {
    return _budgets.where((budget) => budget.isOverBudget).toList();
  }

  // Load budgets
  void loadBudgets() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _firebaseService.getBudgetsStream().listen(
      (budgets) {
        _budgets = budgets;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Add budget
  Future<void> addBudget({
    required ExpenseCategory category,
    required double limit,
    String period = 'monthly',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      DateTime now = DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, 1);
      DateTime endDate = DateTime(now.year, now.month + 1, 0);

      final budget = BudgetModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _firebaseService.userId ?? '',
        category: category,
        limit: limit,
        period: period,
        startDate: startDate,
        endDate: endDate,
      );

      await _firebaseService.addBudget(budget);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add budget: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update budget
  Future<void> updateBudget(BudgetModel budget) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.updateBudget(budget);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update budget: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get budget for category
  BudgetModel? getBudgetForCategory(ExpenseCategory category) {
    try {
      return _budgets.firstWhere((budget) => budget.category == category);
    } catch (e) {
      return null;
    }
  }

  // Check if over budget
  bool isOverBudgetForCategory(ExpenseCategory category) {
    BudgetModel? budget = getBudgetForCategory(category);
    return budget?.isOverBudget ?? false;
  }

  // Get budget progress
  double getBudgetProgress(ExpenseCategory category) {
    BudgetModel? budget = getBudgetForCategory(category);
    if (budget == null) return 0.0;
    return (budget.percentageUsed * 100).clamp(0, 100);
  }
}