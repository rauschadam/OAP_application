// ignore_for_file: non_constant_identifier_names

import 'package:airport_test/parkingForm.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ParkingApp());

class ParkingApp extends StatelessWidget {
  const ParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ParkingFormWizard(),
    );
  }
}
