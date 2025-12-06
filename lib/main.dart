import 'package:flutter/material.dart';
import 'views/app_controller.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/analytics_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Numi Personal Finance',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme, 
      themeMode: ThemeMode.system,
      home: const AppController(),

      routes: {
        HomeScreen.routeName: (_) => const HomeScreen(),
        TransactionsScreen.routeName: (_) => const TransactionsScreen(),
        AddTransactionScreen.routeName: (_) => const AddTransactionScreen(),
        AnalyticsScreen.routeName: (_) => const AnalyticsScreen(),
      },
    );
  }
}
