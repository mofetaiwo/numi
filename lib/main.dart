import 'package:flutter/material.dart';
import 'views/app_controller.dart';
import 'utils/theme.dart';

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
    );
  }
}