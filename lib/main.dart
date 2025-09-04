import 'package:airport_test/constants/constant_widgets.dart';
import 'package:airport_test/homePage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BasePage(
        child: HomePage(),
      ),
    );
  }
}
