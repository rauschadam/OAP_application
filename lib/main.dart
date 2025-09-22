import 'package:airport_test/Pages/receptionLoginPage.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:flutter/material.dart';

/// Halllóóóó
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BasePage(
        child: ReceptionLoginPage(),
      ),
    );
  }
}
