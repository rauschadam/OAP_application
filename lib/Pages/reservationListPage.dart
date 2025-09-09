import 'dart:async';

import 'package:airport_test/Pages/bookingForm/bookingOptionPage.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/constant_widgets/my_icon_button.dart';
import 'package:airport_test/constants/constant_widgets/reservation_list.dart';
import 'package:airport_test/constants/constant_widgets/shimmer_placeholder_template.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationListPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Foglalások';

  @override
  bool get haveMargins => false;

  final String? authToken;
  const ReservationListPage({super.key, required this.authToken});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  /// automatikusan frissítjük az adatokat
  Timer? refreshTimer;

  /// Mostani idő (1 perceként frissül)
  late DateTime now = DateTime.now();

  /// Lekérdezett foglalások
  List<dynamic>? reservations;

  /// Lekérdezett szolgáltatások
  List<dynamic>? serviceTemplates;

  /// Foglalások lekérdezése
  Future<void> fetchReservations() async {
    final api = ApiService();
    final data = await api.getReservations(widget.authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        reservations = data;
      });
      fetchServiceTemplates();
    }
  }

  /// Szolgáltatások lekérdezése
  Future<void> fetchServiceTemplates() async {
    final api = ApiService();
    final data = await api.getServiceTemplates(widget.authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        serviceTemplates = data;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    fetchReservations();

    // percenként frissítjük a foglalásokat
    refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
      //fetchData();
      fetchReservations();
      now = DateTime.now();
      print('Frissítve');
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 70, vertical: 20),
      color: BasePage.defaultColors.secondary,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: buildReservationList(
                reservations: reservations,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 16,
            child: MyIconButton(
              icon: Icons.add_rounded,
              labelText: "Foglalás rögzítése",
              onPressed: () {
                BasePage.defaultColors = AppColors.blue;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BasePage(
                      child: BookingOptionPage(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReservationList({
    required List<dynamic>? reservations,
    double? maxHeight,
  }) {
    if (reservations == null) {
      return ShimmerPlaceholderTemplate(
          width: double.infinity, height: maxHeight ?? double.infinity);
    }

    /// Kiszűrjük azokat a foglalásokat, amelyeknek az LeaveDate-je a múltban van. Tehát már nem lényeges
    /// Rendezzük ArriveDate szerint.
    final List<dynamic> upcomingReservations = [];

    for (var reservation in reservations) {
      final leaveDate = DateTime.parse(reservation['LeaveDate']);
      if (leaveDate.isAfter(now)) {
        upcomingReservations.add(reservation);
      }
    }

    // Rendezés arriveDate szerint
    upcomingReservations.sort((a, b) => DateTime.parse(a['ArriveDate'])
        .compareTo(DateTime.parse(b['ArriveDate'])));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: ReservationList(
        maxHeight: maxHeight,
        listTitle: 'Foglalások',
        reservations: upcomingReservations,
        columns: {
          'Név': 'Name',
          'Rendszám': 'LicensePlate',
          'Érkezés dátuma': 'ArriveDate',
          'Távozás dátuma': 'LeaveDate'
        },
        formatters: {
          'ArriveDate': (reservation) => DateFormat('yyyy.MM.dd HH:mm')
              .format(DateTime.parse(reservation['ArriveDate'])),
          'LeaveDate': (reservation) => DateFormat('yyyy.MM.dd HH:mm')
              .format(DateTime.parse(reservation['LeaveDate'])),
        },
      ),
    );
  }
}
