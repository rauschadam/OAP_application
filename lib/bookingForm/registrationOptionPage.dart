import 'package:airport_test/constantWidgets.dart';
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
  RegistrationOption selectedRegistrationOption = RegistrationOption.registered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: MyRadioListTile<RegistrationOption>(
            title: 'Regisztrált partner vagyok',
            value: RegistrationOption.registered,
            groupValue: selectedRegistrationOption,
            onChanged: (RegistrationOption? value) {
              setState(() {
                selectedRegistrationOption = value!;
              });
            },
            leading: Icon(
              Icons.login_rounded,
              color: selectedRegistrationOption == RegistrationOption.registered
                  ? Colors.blue
                  : Colors.grey,
            ),
          ),
        ),
        MyRadioListTile<RegistrationOption>(
          title: 'Most szeretnék regisztrálni',
          value: RegistrationOption.registerNow,
          groupValue: selectedRegistrationOption,
          onChanged: (RegistrationOption? value) {
            setState(() {
              selectedRegistrationOption = value!;
            });
          },
          leading: Icon(
            Icons.app_registration_rounded,
            color: selectedRegistrationOption == RegistrationOption.registerNow
                ? Colors.green
                : Colors.grey,
          ),
        ),
        MyRadioListTile<RegistrationOption>(
          title: 'Regisztráció nélkül vásárolok',
          value: RegistrationOption.withoutRegistration,
          groupValue: selectedRegistrationOption,
          onChanged: (RegistrationOption? value) {
            setState(() {
              selectedRegistrationOption = value!;
            });
          },
          leading: Icon(
            Icons.no_accounts_rounded,
            color: selectedRegistrationOption ==
                    RegistrationOption.withoutRegistration
                ? Colors.grey[700]
                : Colors.grey,
          ),
        ),
        switch (selectedRegistrationOption) {
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
            ),
        },
      ],
    );
  }
}
