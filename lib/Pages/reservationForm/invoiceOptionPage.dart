import 'package:airport_test/Pages/homePage/homePage.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/api_classes/reservation.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvoiceOptionPage extends ConsumerStatefulWidget {
  const InvoiceOptionPage({super.key});

  @override
  ConsumerState<InvoiceOptionPage> createState() => _InvoiceOptionPageState();
}

class _InvoiceOptionPageState extends ConsumerState<InvoiceOptionPage> {
  InvoiceOption selectedInvoiceOption = InvoiceOption.no;

  /// Megnzézzük, hogy lehet-e egyből érkeztetni
  bool checkCustomerArrivalIsSoon() {
    final state = ref.read(reservationProvider);
    if (state.arriveDate == null) return false;
    final now = DateTime.now();
    final diff = state.arriveDate!.difference(now);
    return diff.inHours < 24;
  }

  /// Ügyfél érkeztetése
  Future<void> attemptRegisterArrival() async {
    final state = ref.read(reservationProvider);
    final api = ApiService();
    await api.logCustomerArrival(context, state.licensePlate);
    goToHomePage();
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
                attemptRegisterArrival();
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

  /// HomePage-re navigálás
  void goToHomePage() async {
    Navigation(context: context, page: HomePage()).pushReplacement();
  }

  /// Foglalás rögzítése
  void submitReservation() async {
    final state =
        ref.read(reservationProvider); // Minden adat olvasása az állapotból

    final reservation = Reservation(
      parkingService: 1,
      partnerId: state.partnerId,
      alreadyRegistered: state.alreadyRegistered,
      withoutRegistration: state.withoutRegistration,
      name: state.name,
      email: state.email,
      phone: state.phone,
      licensePlate: state.licensePlate,
      arriveDate: state.arriveDate!,
      leaveDate: state.leaveDate!,
      parkingArticleId: state.parkingArticleId,
      parkingArticleVolume: "1",
      transferPersonCount: state.transferPersonCount,
      vip: state.vip,
      suitcaseWrappingCount: state.suitcaseWrappingCount,
      washDateTime: state.washDateTime,
      payTypeId: state.payTypeId,
      description: state.description,
      carWashArticleId: state.carWashArticleId,
    );

    await ApiService().submitReservation(
        context, reservation, state.authToken); // AuthToken is az állapotból
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      pageTitle: "Számlázás",
      haveMargins: true,
      child: Column(
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
      ),
    );
  }
}
