import 'package:airport_test/basePage.dart';
import 'package:airport_test/bookingForm/bookingOptionPage.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BasePage(
                  title: 'Foglalási Opciók', child: BookingOptionPage()),
            ),
          );
        },
        child: const Text("Foglalás"),
      ),
    );
  }
}
