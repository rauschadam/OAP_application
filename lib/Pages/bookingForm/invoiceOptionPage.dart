import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/reservation.dart';
import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/constant_widgets/next_page_button.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:airport_test/Pages/homePage.dart';
import 'package:flutter/material.dart';

class InvoiceOptionPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Számlázás';

  final String? authToken;
  final BookingOption bookingOption;
  // final int parkingService;
  final bool alreadyRegistered;
  final bool withoutRegistration;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController licensePlateController;
  final DateTime? arriveDate;
  final DateTime? leaveDate;
  final String? parkingArticleId;
  //final String parkingArticleVolume;
  final int? transferPersonCount;
  final bool? vip;
  final int? suitcaseWrappingCount;
  final String? carWashArticleId;
  final DateTime? washDateTime;
  final TextEditingController descriptionController;
  const InvoiceOptionPage(
      {super.key,
      required this.authToken,
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
      required this.bookingOption,
      this.parkingArticleId,
      this.suitcaseWrappingCount,
      this.carWashArticleId,
      required this.alreadyRegistered,
      required this.withoutRegistration});

  @override
  State<InvoiceOptionPage> createState() => _InvoiceOptionPageState();
}

class _InvoiceOptionPageState extends State<InvoiceOptionPage> {
  InvoiceOption? selectedInvoiceOption = InvoiceOption.no;

  void submitReservation() async {
    final reservation = Reservation(
      parkingService: 1,
      alreadyRegistered: widget.alreadyRegistered,
      withoutRegistration: widget.withoutRegistration,
      name: widget.nameController.text,
      email: widget.emailController.text,
      phone: '+${widget.phoneController.text}',
      licensePlate: widget.licensePlateController.text,
      arriveDate: widget.arriveDate!,
      leaveDate: widget.leaveDate!,
      parkingArticleId: widget.parkingArticleId,
      parkingArticleVolume: "1",
      transferPersonCount: widget.transferPersonCount,
      vip: widget.vip!,
      suitcaseWrappingCount: widget.suitcaseWrappingCount,
      washDateTime: widget.washDateTime,
      payType: 1,
      description: widget.descriptionController.text,
      carWashArticleId: widget.carWashArticleId,
    );

    await ApiService().submitReservation(reservation, widget.authToken);
  }

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
          onPressed: () {
            submitReservation();
          },
          nextPage: HomePage(),
          showBackButton: false,
        )
      ],
    );
  }
}
