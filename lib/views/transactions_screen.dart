import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_list_item.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  String _searchQuery = '';
  ExpenseCategory? _filterCategory;
  TransactionType? _filterType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        selectedCategory: _filterCategory,
        selectedType: _filterType,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (category, type, start, end) {
          setState(() {
            _filterCategory = category;
            _filterType = type;
            _startDate = start;
            _endDate = end;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    return transactions.where((transaction) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        if (!transaction.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Category filter
      if (_filterCategory != null && transaction.category != _filterCategory) {
        return false;
      }

      // Type filter
      if (_filterType != null && transaction.type != _filterType) {
        return false;
      }

      // Date range filter
      if (_startDate != null && transaction.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && transaction.date.isAfter(_endDate!)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactionVM = context.watch<TransactionViewModel>();
    final filteredTransactions = _filterTransactions(transactionVM.transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.filter_list),
                        if (_filterCategory != null ||
                            _filterType != null ||
                            _startDate != null ||
                            _endDate != null)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: _showFilterBottomSheet,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: transactionVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactionVM.hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${transactionVM.error}'),
            ElevatedButton(
              onPressed: () => transactionVM.loadTransactions(),
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : filteredTransactions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ||
                  _filterCategory != null ||
                  _filterType != null
                  ? 'No transactions match your filters'
                  : 'No transactions yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isEmpty &&
                _filterCategory == null &&
                _filterType == null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTransactionScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Transaction'),
                ),
              ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async {
          transactionVM.loadTransactions();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            final transaction = filteredTransactions[index];
            return FadeTransition(
              opacity: _slideAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.1 * (index + 1)),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: TransactionListItem(
                  transaction: transaction,
                  onTap: () => _showTransactionDetails(transaction),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailsSheet(transaction: transaction),
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final ExpenseCategory? selectedCategory;
  final TransactionType? selectedType;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(ExpenseCategory?, TransactionType?, DateTime?, DateTime?) onApply;

  const FilterBottomSheet({
    Key? key,
    this.selectedCategory,
    this.selectedType,
    this.startDate,
    this.endDate,
    required this.onApply,
  }) : super(key: key);

  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  ExpenseCategory? _category;
  TransactionType? _type;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _type = widget.selectedType;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filter Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Transaction Type
          const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip('All', null),
              const SizedBox(width: 8),
              _buildTypeChip('Income', TransactionType.income),
              const SizedBox(width: 8),
              _buildTypeChip('Expense', TransactionType.expense),
            ],
          ),
          const SizedBox(height: 20),

          // Category
          const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip('All', null),
              ...ExpenseCategory.values.map((cat) =>
                  _buildCategoryChip(_getCategoryName(cat), cat)),
            ],
          ),
          const SizedBox(height: 20),

          // Date Range
          const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  'Start Date',
                  _startDate,
                      (date) => setState(() => _startDate = date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  'End Date',
                  _endDate,
                      (date) => setState(() => _endDate = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null, null, null, null);
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_category, _type, _startDate, _endDate);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, TransactionType? type) {
    bool isSelected = _type == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _type = selected ? type : null;
        });
      },
    );
  }

  Widget _buildCategoryChip(String label, ExpenseCategory? category) {
    bool isSelected = _category == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _category = selected ? category : null;
        });
      },
    );
  }

  Widget _buildDateButton(String label, DateTime? date, Function(DateTime?) onSelect) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onSelect(picked);
        }
      },
      child: Text(
        date != null
            ? '${date.day}/${date.month}/${date.year}'
            : label,
      ),
    );
  }

  String _getCategoryName(ExpenseCategory category) {
    return category.toString().split('.').last.substring(0, 1).toUpperCase() +
        category.toString().split('.').last.substring(1);
  }
}

class TransactionDetailsSheet extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailsSheet({Key? key, required this.transaction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (transaction.type == TransactionType.income
                      ? Colors.green
                      : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  transaction.type == TransactionType.income
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: transaction.type == TransactionType.income
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${transaction.type == TransactionType.income ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: transaction.type == TransactionType.income
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Category', _getCategoryName(transaction.category)),
          _buildDetailRow('Date', '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}'),
          _buildDetailRow('Time', '${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}'),
          if (transaction.receiptUrl != null)
            _buildDetailRow('Receipt', 'Attached', hasIcon: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool hasIcon = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasIcon)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.attach_file, size: 16),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCategoryName(ExpenseCategory category) {
    return category.toString().split('.').last.substring(0, 1).toUpperCase() +
        category.toString().split('.').last.substring(1);
  }
}