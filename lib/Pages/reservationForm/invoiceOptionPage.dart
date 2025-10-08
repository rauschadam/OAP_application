import 'package:airport_test/api_Services/api_service.dart';
import 'package:airport_test/api_services/api_classes/reservation.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:airport_test/Pages/homePage.dart';
import 'package:flutter/material.dart';

class InvoiceOptionPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Számlázás';

  final String authToken;
  final String partnerId;
  final String payTypeId;
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
      required this.partnerId,
      required this.payTypeId,
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
  InvoiceOption selectedInvoiceOption = InvoiceOption.no;

  /// Megnzézzük, hogy lehet-e egyből érkeztetni
  bool checkCustomerArrivalIsSoon() {
    if (widget.arriveDate == null) return false;
    final now = DateTime.now();
    final diff = widget.arriveDate!.difference(now);
    return diff.inHours < 24;
  }

  /// Felveti az érkeztetés lehetőségét
  void showArrivalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Szeretné érkeztetni az ügyfelet?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                goToHomePage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Nem'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                attemptRegisterArrival(widget.licensePlateController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text("Érkeztetés"),
            ),
          ],
        );
      },
    );
  }

  /// Ügyfél érkeztetése
  Future<void> attemptRegisterArrival(String licensePlate) async {
    final api = ApiService();
    await api.logCustomerArrival(context, licensePlate);
    goToHomePage();
  }

  /// HomePage-re navigálás
  void goToHomePage() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BasePage(
          child: HomePage(),
        ),
      ),
    );
  }

  /// Foglalás rögzítése
  void submitReservation() async {
    final reservation = Reservation(
      parkingService: 1,
      partnerId: widget.partnerId,
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
      payTypeId: widget.payTypeId,
      description: widget.descriptionController.text,
      carWashArticleId: widget.carWashArticleId,
    );

    await ApiService()
        .submitReservation(context, reservation, widget.authToken);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyRadioListTile<InvoiceOption>(
          title: 'Nem kérek számlát',
          value: InvoiceOption.no,
          groupValue: selectedInvoiceOption,
          onChanged: (InvoiceOption? value) {
            setState(() {
              selectedInvoiceOption = value!;
            });
          },
        ),
        MyRadioListTile<InvoiceOption>(
          title: 'Kérek számlát',
          value: InvoiceOption.yes,
          groupValue: selectedInvoiceOption,
          onChanged: (InvoiceOption? value) {
            setState(() {
              selectedInvoiceOption = value!;
            });
          },
        ),
        NextPageButton(
          text: "Foglalás küldése",
          onPressed: () {
            submitReservation();
            if (checkCustomerArrivalIsSoon()) {
              showArrivalDialog();
            } else {
              goToHomePage();
            }
          },
        ),
      ],
    );
  }
}
