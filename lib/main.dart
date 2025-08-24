import 'package:airport_test/constantWidgets.dart';
import 'package:airport_test/homePage.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BasePage(
        // title: "Menü",
        child: HomePage(),
      ),
    );
  }
}
