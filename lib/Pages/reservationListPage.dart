import 'dart:async';

import 'package:airport_test/Pages/reservationForm/reservationOptionPage.dart';
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
  /// Automatikusan frissítjük az adatokat 1 perecnként
  Timer? refreshTimer;

  /// Mostani idő (1 perceként frissül)
  late DateTime now = DateTime.now();

  /// Lekérdezett foglalások
  List<dynamic>? reservations;

  /// Kiválasztott foglalás
  dynamic selectedReservation;

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
      padding: EdgeInsets.symmetric(
          horizontal: AppPadding.xlarge, vertical: AppPadding.large),
      color: BasePage.defaultColors.background,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: buildReservationList(
                      reservations: reservations,
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
                            child: ReservationOptionPage(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          selectedReservation != null
              ? Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.medium),
                    child: buildReservationInformation(
                        reservation: selectedReservation),
                  ),
                )
              : Container()
        ],
      ),
    );
  }

  /// Foglalások listája
  Widget buildReservationList({
    required List<dynamic>? reservations,
    double? maxHeight,
  }) {
    if (reservations == null) {
      return ShimmerPlaceholderTemplate(
          width: double.infinity, height: maxHeight ?? double.infinity);
    }

    // Kiszűrjük azokat a foglalásokat, amelyeknek az LeaveDate-je a múltban van. Tehát már nem lényeges
    final List<dynamic> upcomingReservations = [];

    for (var reservation in reservations) {
      final leaveDate = DateTime.parse(reservation['LeaveDate']);
      if (leaveDate.isAfter(now)) {
        upcomingReservations.add(reservation);
      }
    }

    // Rendezzük ArriveDate szerint.
    upcomingReservations.sort((a, b) => DateTime.parse(a['ArriveDate'])
        .compareTo(DateTime.parse(b['ArriveDate'])));

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          color: BasePage.defaultColors.secondary),
      child: Flexible(
        child: ReservationList(
          onRowTap: (reservation) {
            setState(() {
              selectedReservation = reservation;
            });
          },
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
      ),
    );
  }

  /// Kiválasztott foglalás információi
  Widget buildReservationInformation({required dynamic reservation}) {
    // Dátum formázó függvény
    String formatDate(String dateString) {
      try {
        final date = DateTime.parse(dateString);
        return DateFormat('yyyy.MM.dd HH:mm').format(date);
      } catch (e) {
        return dateString;
      }
    }

    // Speciális formázás bizonyos mezőkhöz
    String formatValue(String key, dynamic value) {
      if (value == null) return 'N/A';

      // Dátum mezők automatikus formázása
      if (key.toLowerCase().contains('date')) {
        return formatDate(value.toString());
      }

      // Lista típusú mezők formázása
      if (value is List) {
        if (value.isEmpty) return 'Nincsenek elemek';
        return value.map((item) => item.toString()).join(', ');
      }

      // Map típusú mezők formázása
      if (value is Map) {
        if (value.isEmpty) return 'Nincsenek elemek';
        return value.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', ');
      }

      return value.toString();
    }

    // Kulcsok formázása (névformázás)
    String formatKey(String key) {
      // Eltávolítjuk a speciális karaktereket és camelCase-t alakítunk szóközökké
      final formattedKey = key
          .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
          .trim();

      // Nagybetűvel kezdjük
      return formattedKey[0].toUpperCase() + formattedKey.substring(1);
    }

    return Container(
      decoration: BoxDecoration(
          color: BasePage.defaultColors.secondary,
          borderRadius: BorderRadius.circular(AppBorderRadius.large)),
      padding: EdgeInsets.all(AppPadding.large),
      width: double.infinity,
      child: ListView(
        children: [
          for (var entry in reservation.entries)
            Column(
              children: [
                ListTile(
                  title: Text(
                    formatKey(entry.key),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: BasePage.defaultColors.text),
                  ),
                  subtitle: Text(
                    formatValue(entry.key, entry.value),
                    style: TextStyle(color: BasePage.defaultColors.text),
                  ),
                ),
                Divider(height: 1),
              ],
            ),
        ],
      ),
    );
  }
}
