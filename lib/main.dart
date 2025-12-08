import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:numi/views/home_screen.dart';
import 'package:provider/provider.dart';
import 'viewmodels/transaction_viewmodel.dart';
import 'viewmodels/budget_viewmodel.dart';
import 'services/firebase_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),
        ChangeNotifierProvider<TransactionViewModel>(
          create: (context) => TransactionViewModel(
            firebaseService: context.read<FirebaseService>(),
          ),
        ),
        ChangeNotifierProvider<BudgetViewModel>(
          create: (context) => BudgetViewModel(
            firebaseService: context.read<FirebaseService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Finance Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}