import 'dart:async';

import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/constant_widgets/reservation_list.dart';
import 'package:airport_test/constants/constant_widgets/shimmer_placeholder_template.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationListPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Foglalások';

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

  /// Adat lekérés
  // Future<void> fetchData() async {
  //   final api = ApiService();
  //   final reservationData = await api.getReservations(widget.authToken);
  //   final templateData = await api.getServiceTemplates(widget.authToken);

  //   if (reservationData == null && templateData == null) {
  //     print('Nem sikerült a lekérdezés');
  //   } else {
  //     setState(() {
  //       reservations = reservationData;
  //       serviceTemplates = templateData;
  //     });
  //   }
  // }

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
  Widget build(BuildContext context) {
    return buildReservationList(reservations: reservations);
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
        color: Colors.grey.shade300,
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
