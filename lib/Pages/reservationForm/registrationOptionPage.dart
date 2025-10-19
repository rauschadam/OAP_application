import 'package:airport_test/Pages/reservationForm/loginPage.dart';
import 'package:airport_test/Pages/reservationForm/registrationPage.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
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
    return BasePage(
      pageTitle: "Bejelentkezési lehetőségek",
      haveMargins: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildRadioListTile(),
          buildNextPageButton(),
        ],
      ),
    );
  }

  /// Kiválasztható opciók
  Widget buildRadioListTile() {
    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.small),
      child: Column(
        children: [
          MyRadioListTile<RegistrationOption>(
            title: 'Bejelentkezés',
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
          MyRadioListTile<RegistrationOption>(
            title: 'Regisztráció',
            value: RegistrationOption.registerNow,
            groupValue: selectedRegistrationOption,
            onChanged: (RegistrationOption? value) {
              setState(() {
                selectedRegistrationOption = value!;
              });
            },
            leading: Icon(
              Icons.app_registration_rounded,
              color:
                  selectedRegistrationOption == RegistrationOption.registerNow
                      ? Colors.green
                      : Colors.grey,
            ),
          ),
          MyRadioListTile<RegistrationOption>(
            title: 'Regisztráció nélkül vásárolok',
            subtitle: 'Még nem működik',
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
        ],
      ),
    );
  }

  /// Következő oldal gomb
  Widget buildNextPageButton() {
    switch (selectedRegistrationOption) {
      case RegistrationOption.registerNow:
        return NextPageButton(
          nextPage: RegistrationPage(
            bookingOption: widget.bookingOption,
            alreadyRegistered: false,
            withoutRegistration: false,
          ),
          pushReplacement: false,
        );
      case RegistrationOption.registered:
        return NextPageButton(
          nextPage: LoginPage(
            bookingOption: widget.bookingOption,
            alreadyRegistered: true,
            withoutRegistration: false,
          ),
          pushReplacement: false,
        );
      case RegistrationOption.withoutRegistration:
        return NextPageButton(
          nextPage: LoginPage(
            bookingOption: widget.bookingOption,
            alreadyRegistered: false,
            withoutRegistration: true,
          ),
          pushReplacement: false,
        );
    }
  }
}
