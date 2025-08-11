// ignore_for_file: file_names

import 'package:airport_test/basePage.dart';
import 'package:airport_test/bookingForm/registrationOptionPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';

class BookingOptionPage extends StatefulWidget {
  const BookingOptionPage({super.key});

  @override
  State<BookingOptionPage> createState() => _BookingOptionPageState();
}

class _BookingOptionPageState extends State<BookingOptionPage> {
  BookingOption? selectedBookingOption = BookingOption.parking;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<BookingOption>(
          title: const Text('Parkolni szeretnék'),
          value: BookingOption.parking,
          groupValue: selectedBookingOption,
          onChanged: (BookingOption? value) {
            setState(() {
              selectedBookingOption = value;
            });
          },
        ),
        RadioListTile<BookingOption>(
          title: const Text('Csak mosatni szeretnék'),
          value: BookingOption.washing,
          groupValue: selectedBookingOption,
          onChanged: (BookingOption? value) {
            setState(() {
              selectedBookingOption = value;
            });
          },
        ),
        RadioListTile<BookingOption>(
          title: const Text('Parkolni és mosatni is szeretnék'),
          value: BookingOption.both,
          groupValue: selectedBookingOption,
          onChanged: (BookingOption? value) {
            setState(() {
              selectedBookingOption = value;
            });
          },
        ),
        NextPageButton(
            title: "Bejelentkezési lehetőségek",
            nextPage: RegistrationOptionPage(
              bookingOption: selectedBookingOption!,
            )),
      ],
    );
  }
}
