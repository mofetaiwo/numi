import 'package:flutter/material.dart';
import '../widgets/summary_card.dart';
import '../widgets/section_header.dart';
import 'transactions_screen.dart';
import 'add_transaction_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showContent = false;

  // fake sample values for now – can be replaced with real ViewModel later
  final double _income = 2500;
  final double _expense = 1750;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      setState(() => _showContent = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final net = _income - _expense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Overview'),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContent(context, net),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AddTransactionScreen.routeName),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, double net) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'This Month',
            icon: Icons.calendar_today_outlined,
          ),
          AnimatedScale(
            duration: const Duration(milliseconds: 400),
            scale: _showContent ? 1.0 : 0.9,
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _showContent ? 1.0 : 0.0,
              child: Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'Income',
                      value: '\$${_income.toStringAsFixed(2)}',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'Expenses',
                      value: '\$${_expense.toStringAsFixed(2)}',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _showContent ? 1.0 : 0.0,
            child: SummaryCard(
              title: 'Net',
              value: '\$${net.toStringAsFixed(2)}',
              color: net >= 0 ? Colors.teal : Colors.red,
              onTap: () =>
                  Navigator.pushNamed(context, AnalyticsScreen.routeName),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Quick Actions',
            icon: Icons.flash_on_outlined,
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, TransactionsScreen.routeName),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Transactions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AnalyticsScreen.routeName),
                  icon: const Icon(Icons.pie_chart_outline),
                  label: const Text('Analytics'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
