import 'package:airport_test/Pages/receptionLoginPage.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(ProviderScope(child: const MainApp()));
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
