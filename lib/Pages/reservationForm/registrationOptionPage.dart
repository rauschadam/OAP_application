import 'package:airport_test/Pages/reservationForm/loginPage.dart';
import 'package:airport_test/Pages/reservationForm/registrationPage.dart';
import 'package:airport_test/api_services/api_classes/reservation.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationOptionPage extends ConsumerStatefulWidget {
  const RegistrationOptionPage({super.key});

  @override
  ConsumerState<RegistrationOptionPage> createState() =>
      _RegistrationOptionPageState();
}

class _RegistrationOptionPageState
    extends ConsumerState<RegistrationOptionPage> {
  RegistrationOption selectedRegistrationOption = RegistrationOption.registered;

  void onNextPageButtonPressed() {
    Widget? nextPage;
    bool alreadyRegistered = false;
    bool withoutRegistration = false;

    switch (selectedRegistrationOption) {
      case RegistrationOption.registerNow:
        nextPage = const RegistrationPage();
        break;
      case RegistrationOption.registered:
        nextPage = const LoginPage();
        alreadyRegistered = true;
        break;
      case RegistrationOption.withoutRegistration:
        nextPage = const LoginPage();
        withoutRegistration = true;
        break;
    }

    // A foglalás opciók frissítése (hozzáadva a regisztrációs opciókat)
    ref.read(reservationProvider.notifier).updateOptions(
          bookingOption: ref.read(reservationProvider).bookingOption,
          alreadyRegistered: alreadyRegistered,
          withoutRegistration: withoutRegistration,
        );

    Navigation(context: context, page: nextPage).push();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      pageTitle: "Bejelentkezési lehetőségek",
      haveMargins: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildRadioListTile(),
          NextPageButton(
            text: 'Tovább',
            onPressed: onNextPageButtonPressed,
            pushReplacement: false,
          ),
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
}
