// ignore_for_file: file_names

import 'package:airport_test/basePage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:airport_test/homePage.dart';
import 'package:flutter/material.dart';

class InvoiceOptionPage extends StatefulWidget {
  final BookingOption bookingOption;
  // final int parkingService;
  // final bool alreadyRegistered;
  // final bool withoutRegistration;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController licensePlateController;
  final DateTime? arriveDate;
  final DateTime? leaveDate;
  //final String parkingArticleId;
  //final String parkingArticleVolume;
  final int? transferPersonCount;
  final bool? vip;
  //final int? suitcaseWrappingCount;
  //final String carWashArticleId;
  final DateTime? washDateTime;
  final TextEditingController descriptionController;
  const InvoiceOptionPage(
      {super.key,
      required this.nameController,
      required this.emailController,
      required this.phoneController,
      required this.licensePlateController,
      required this.arriveDate,
      required this.leaveDate,
      required this.transferPersonCount,
      required this.vip,
      this.washDateTime,
      required this.descriptionController,
      required this.bookingOption});

  @override
  State<InvoiceOptionPage> createState() => _InvoiceOptionPageState();
}

class _InvoiceOptionPageState extends State<InvoiceOptionPage> {
  InvoiceOption? selectedInvoiceOption = InvoiceOption.no;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<InvoiceOption>(
          title: const Text('Nem kérek számlát'),
          value: InvoiceOption.no,
          groupValue: selectedInvoiceOption,
          onChanged: (InvoiceOption? value) {
            setState(() {
              selectedInvoiceOption = value;
            });
          },
        ),
        RadioListTile<InvoiceOption>(
          title: const Text('Kérek számlát'),
          value: InvoiceOption.yes,
          groupValue: selectedInvoiceOption,
          onChanged: (InvoiceOption? value) {
            setState(() {
              selectedInvoiceOption = value;
            });
          },
        ),
        NextPageButton(
            text: "Foglalás küldése",
            onPressedExtra: () {
              print('bookingOption: ${widget.bookingOption}\n'
                  'name: ${widget.nameController.text}\n'
                  'email: ${widget.emailController.text}\n'
                  'phone: ${widget.phoneController.text}\n'
                  'licensePlate: ${widget.licensePlateController.text}\n'
                  'arriveDate: ${widget.arriveDate}\n'
                  'leaveDate: ${widget.leaveDate}\n'
                  'transferPersonCount: ${widget.transferPersonCount}\n'
                  'vip: ${widget.vip}\n'
                  'washDateTime: ${widget.washDateTime}\n'
                  'description: ${widget.descriptionController.text}');
            },
            title: "Menü",
            nextPage: const HomePage())
      ],
    );
  }
}
