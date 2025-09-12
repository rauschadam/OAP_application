import 'package:airport_test/Pages/reservationForm/registrationOptionPage.dart';
import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/constant_widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/constant_widgets/next_page_button.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';

class ReservationOptionPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Foglalási lehetőségek';

  const ReservationOptionPage({super.key});

  @override
  State<ReservationOptionPage> createState() => _ReservationOptionPageState();
}

class _ReservationOptionPageState extends State<ReservationOptionPage> {
  BookingOption selectedBookingOption = BookingOption.parking;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildRadioListTiles(),
        NextPageButton(
          nextPage: RegistrationOptionPage(
            bookingOption: selectedBookingOption,
          ),
        ),
      ],
    );
  }

  /// Kiválasztható opciók
  Widget buildRadioListTiles() {
    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.small),
      child: Column(
        children: [
          MyRadioListTile<BookingOption>(
            title: 'Csak parkolni szeretnék',
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
            title: 'Csak mosatni szeretnék',
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
            title: 'Parkolni és mosatni is szeretnék',
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
