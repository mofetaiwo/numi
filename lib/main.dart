import 'package:flutter/material.dart';
import 'views/app_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Numi Personal Finance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, primary: const Color(0xFF673AB7)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AppController(),
    );
  }
}