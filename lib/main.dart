import 'package:airport_test/Pages/receptionLoginPage.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: GlobalNavigatorKey,
      home: ReceptionLoginPage(),
    );
  }
}
