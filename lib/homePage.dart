import 'package:airport_test/constantWidgets.dart';
import 'package:airport_test/bookingForm/bookingOptionPage.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: MyIconButton(
      icon: Icons.add_rounded,
      labelText: "Foglalás rögzítése",
      onPressed: () {
        BasePage.defaultColors = AppColors.blue;
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
    ));
  }
}
