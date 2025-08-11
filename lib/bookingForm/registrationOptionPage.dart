// ignore_for_file: file_names

import 'package:airport_test/basePage.dart';
import 'package:airport_test/bookingForm/loginPage.dart';
import 'package:airport_test/bookingForm/registrationPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';

class RegistrationOptionPage extends StatefulWidget {
  final BookingOption bookingOption;
  const RegistrationOptionPage({super.key, required this.bookingOption});

  @override
  State<RegistrationOptionPage> createState() => _RegistrationOptionPageState();
}

class _RegistrationOptionPageState extends State<RegistrationOptionPage> {
  RegistrationOption? selectedRegistrationOption =
      RegistrationOption.registered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<RegistrationOption>(
          title: const Text('Regisztrált partner vagyok'),
          value: RegistrationOption.registered,
          groupValue: selectedRegistrationOption,
          onChanged: (RegistrationOption? value) {
            setState(() {
              selectedRegistrationOption = value;
            });
          },
        ),
        RadioListTile<RegistrationOption>(
          title: const Text('Most szeretnék regisztrálni'),
          value: RegistrationOption.registerNow,
          groupValue: selectedRegistrationOption,
          onChanged: (RegistrationOption? value) {
            setState(() {
              selectedRegistrationOption = value;
            });
          },
        ),
        RadioListTile<RegistrationOption>(
          title: const Text('Regisztráció nélkül vásárolok'),
          value: RegistrationOption.withoutRegistration,
          groupValue: selectedRegistrationOption,
          onChanged: (RegistrationOption? value) {
            setState(() {
              selectedRegistrationOption = value;
            });
          },
        ),
        switch (selectedRegistrationOption!) {
          RegistrationOption.registerNow => NextPageButton(
              title: "Regisztráció",
              nextPage: RegistrationPage(
                bookingOption: widget.bookingOption,
              ),
            ),
          RegistrationOption.registered => NextPageButton(
              title: "Bejelentkezés",
              nextPage: LoginPage(
                bookingOption: widget.bookingOption,
              ),
            ),
          RegistrationOption.withoutRegistration => NextPageButton(
              title: "Bejelentkezés",
              nextPage: LoginPage(
                bookingOption: widget.bookingOption,
              ),
            ), // Később más lesz...
        },
      ],
    );
  }
}
