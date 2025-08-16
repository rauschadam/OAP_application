import 'package:airport_test/constantWidgets.dart';
import 'package:airport_test/bookingForm/bookingOptionPage.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[50], // gomb háttérszíne
        ),
        icon: const Icon(
          Icons.add,
          color: Colors.blue, // ikon színe
        ),
        label: const Text(
          "Foglalás",
          style: TextStyle(color: Colors.blue),
        ),
        onPressed: () {
          BasePage.defaultColorEnum = BackGroundColor.blue;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BasePage(
                title: 'Foglalási Opciók',
                child: BookingOptionPage(),
              ),
            ),
          );
        },
      ),
    );
  }
}
