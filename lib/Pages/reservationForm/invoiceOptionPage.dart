import 'package:airport_test/Pages/homePage/homePage.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/api_classes/reservation.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
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
    ref.read(reservationProvider.notifier).resetState();
    Navigation(context: context, page: HomePage()).pushAndRemoveAll();
  }

  /// Foglalás rögzítése
  Future<String?> submitReservation() async {
    final state =
        ref.read(reservationProvider); // Minden adat olvasása az állapotból

    int parkingService = getParkingService(state.bookingOption);

    final reservation = Reservation(
      parkingService: parkingService,
      partnerId: state.partnerId,
      alreadyRegistered: state.alreadyRegistered,
      withoutRegistration: state.withoutRegistration,
      name: state.name,
      email: state.email,
      phone: state.phone,
      licensePlate: state.licensePlate,
      arriveDate: state.arriveDate,
      leaveDate: state.leaveDate,
      parkingArticleId: state.parkingArticleId,
      parkingArticleVolume: state.parkingArticleId != null ? "1" : "0",
      transferPersonCount: state.transferPersonCount,
      vip: state.vip,
      suitcaseWrappingCount: state.suitcaseWrappingCount,
      washDateTime: state.washDateTime,
      payTypeId: state.payTypeId,
      description: state.description,
      carWashArticleId: state.carWashArticleId,
      webReserve: false,
    );

    // await ApiService().submitReservation(context, reservation, state.authToken);

    // Hívja meg a módosított ApiService metódust és adja vissza az eredményét
    String? errorMessage =
        await ApiService().submitReservation(reservation, state.authToken);
    return errorMessage;
  }

  int getParkingService(BookingOption selectedBookingOption) {
    switch (selectedBookingOption) {
      case BookingOption.parking:
        return 0;
      case BookingOption.washing:
        return 1;
      case BookingOption.both:
        return 2;
    }
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
            onPressed: () async {
              // 1. Várja be az eredményt (ami siker esetén null, hiba esetén string)
              String? errorMessage = await submitReservation();

              // 2. Ellenőrizze, hogy a widget még "mounted"
              if (!mounted) return;

              if (errorMessage == null) {
                // 3. Siker esetén (nincs hibaüzenet) navigáljon
                if (checkCustomerArrivalIsSoon()) {
                  showArrivalDialog();
                } else {
                  goToHomePage();
                }
              } else {
                // 4. Hiba esetén jelenítsen meg egy dialógust a hibaüzenettel
                AwesomeDialog(
                  context: context,
                  width: 300,
                  dialogType: DialogType.error,
                  title: "Foglalás rögzítése sikertelen",
                  desc: errorMessage,
                ).show();
              }
            },
          ),
        ],
      ),
    );
  }
}
