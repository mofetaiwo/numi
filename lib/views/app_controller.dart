import 'package:flutter/material.dart';
// import pages
import 'main_page.dart';
import 'receipt_scanner/permissions_view.dart';
import 'second_page.dart';

class AppController extends StatefulWidget {
  const AppController({super.key});

  @override
  State<AppController> createState() => _AppController();
}

class _AppController extends State<AppController> {
  // Main Page is in the middle of the swipe deck
  final PageController _pageController = PageController(initialPage: 1);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        
        // Structure: [0] Receipt Scanner, [1] Main Page, [2] Settings
        children: const [
          PermissionsPage(),     // Index 0: Swipe RIGHT 
          MainPage(),        // Index 1: Main Page
          SecondPage(), // Index 2: Swipe LEFT 
        ],
      ),
    );
  }
}