import 'package:airport_test/Pages/bookingForm/loginPage.dart';
import 'package:airport_test/Pages/bookingForm/registrationPage.dart';
import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/constant_widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/constant_widgets/next_page_button.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';

class RegistrationOptionPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Bejelentkezési lehetőségek';

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
          padding: const EdgeInsets.only(top: AppPadding.small),
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
              nextPage: RegistrationPage(
                bookingOption: widget.bookingOption,
                alreadyRegistered: false,
                withoutRegistration: false,
              ),
            ),
          RegistrationOption.registered => NextPageButton(
              nextPage: LoginPage(
                bookingOption: widget.bookingOption,
                alreadyRegistered: true,
                withoutRegistration: false,
              ),
            ),
          RegistrationOption.withoutRegistration => NextPageButton(
              nextPage: LoginPage(
                bookingOption: widget.bookingOption,
                alreadyRegistered: false,
                withoutRegistration: true,
              ),
            ),
        },
      ],
    );
  }
}
