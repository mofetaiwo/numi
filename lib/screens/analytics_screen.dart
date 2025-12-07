import 'package:flutter/material.dart';
import '../widgets/section_header.dart';

class AnalyticsScreen extends StatelessWidget {
  static const routeName = '/analytics';

  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // fake spending data – can be replaced with real ViewModel later
    final data = <String, double>{
      'Food': 240,
      'Rent': 900,
      'Transport': 120,
      'Shopping': 180,
      'Other': 75,
    };

    final maxValue =
        data.values.isEmpty ? 0.0 : data.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: data.isEmpty
            ? const Center(
                child: Text(
                  'No spending data yet.\nAdd expenses to see analytics.',
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Spending by Category',
                    icon: Icons.pie_chart_outline,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 220,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: data.entries.map((entry) {
                        final label = entry.key;
                        final value = entry.value;
                        final fraction =
                            maxValue == 0 ? 0.0 : value / maxValue;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _AnimatedBar(
                              label: label,
                              fraction: fraction,
                              value: value,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Details',
                    icon: Icons.list_alt,
                  ),
                  Expanded(
                    child: ListView(
                      children: data.entries.map((e) {
                        return ListTile(
                          dense: true,
                          title: Text(e.key),
                          trailing: Text('\$${e.value.toStringAsFixed(2)}'),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final String label;
  final double fraction;
  final double value;

  const _AnimatedBar({
    required this.label,
    required this.fraction,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, val, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '\$${value.toStringAsFixed(0)}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 150 * val,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.black87),
            ),
          ],
        );
      },
    );
  }
}
