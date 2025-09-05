import 'package:airport_test/constants/constant_widgets.dart';
import 'package:airport_test/bookingForm/registrationOptionPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';

class BookingOptionPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Foglalási lehetőségek';

  const BookingOptionPage({super.key});

  @override
  State<BookingOptionPage> createState() => _BookingOptionPageState();
}

class _BookingOptionPageState extends State<BookingOptionPage> {
  BookingOption selectedBookingOption = BookingOption.parking;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: MyRadioListTile<BookingOption>(
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
        ),
        MyRadioListTile<BookingOption>(
          title: 'Csak mosatni szeretnék',
          subtitle: 'Jelenleg kötelező a parkolás megadása, ne ezzel tesztelj',
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
        ),
        NextPageButton(
          nextPage: RegistrationOptionPage(
            bookingOption: selectedBookingOption,
          ),
        ),
      ],
    );
  }
}
