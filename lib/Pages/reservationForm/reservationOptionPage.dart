import 'package:airport_test/Pages/reservationForm/registrationOptionPage.dart';
import 'package:airport_test/api_services/api_classes/reservation.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReservationOptionPage extends ConsumerStatefulWidget {
  const ReservationOptionPage({super.key});

  @override
  ConsumerState<ReservationOptionPage> createState() =>
      _ReservationOptionPageState();
}

class _ReservationOptionPageState extends ConsumerState<ReservationOptionPage> {
  BookingOption selectedBookingOption = BookingOption.parking;

  void onNextPageButtonPressed() {
    // Adat beírása a Riverpod állapotba
    ref.read(reservationProvider.notifier).updateOptions(
          bookingOption: selectedBookingOption,
          alreadyRegistered: false, // Ezt a következő oldalon felülírjuk
          withoutRegistration: false, // Ezt a következő oldalon felülírjuk
        );
    // Navigálás
    Navigation(
      context: context,
      page: const RegistrationOptionPage(),
    ).push();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      pageTitle: "Foglalási lehetőségek",
      haveMargins: true,
      child: Column(
        children: [
          buildRadioListTiles(),
          NextPageButton(
            onPressed: onNextPageButtonPressed,
            pushAndRemoveAll: false,
          ),
        ],
      ),
    );
  }

  /// Kiválasztható opciók
  Widget buildRadioListTiles() {
    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.small),
      child: Column(
        children: [
          MyRadioListTile<BookingOption>(
            title: 'Parkolás',
            value: BookingOption.parking,
            groupValue: selectedBookingOption,
            onChanged: (BookingOption? value) {
              setState(() {
                selectedBookingOption = value!;
              });
            },
            leading: Icon(
              Icons.local_parking_rounded,
              color: selectedBookingOption == BookingOption.parking
                  ? Colors.blue
                  : Colors.grey,
            ),
          ),
          MyRadioListTile<BookingOption>(
            title: 'Mosás',
            subtitle:
                'Jelenleg kötelező a parkolás megadása, ne ezzel tesztelj',
            value: BookingOption.washing,
            groupValue: selectedBookingOption,
            onChanged: (BookingOption? value) {
              setState(() {
                selectedBookingOption = value!;
              });
            },
            leading: Icon(
              Icons.local_car_wash_rounded,
              color: selectedBookingOption == BookingOption.washing
                  ? Colors.green
                  : Colors.grey,
            ),
          ),
          MyRadioListTile<BookingOption>(
            title: 'Parkolás és mosás',
            value: BookingOption.both,
            groupValue: selectedBookingOption,
            onChanged: (BookingOption? value) {
              setState(() {
                selectedBookingOption = value!;
              });
            },
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_parking,
                  color: selectedBookingOption == BookingOption.both
                      ? Colors.blue
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.local_car_wash,
                  color: selectedBookingOption == BookingOption.both
                      ? Colors.green
                      : Colors.grey,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
