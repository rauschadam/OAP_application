import 'dart:async';

import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/constant_widgets.dart';
import 'package:airport_test/bookingForm/bookingOptionPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class HomePage extends StatefulWidget with PageWithTitle {
  HomePage({super.key});

  @override
  String get pageTitle => 'Menü';

  @override
  bool get showBackButton => false;

  @override
  bool get haveMargins => false;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// automatikusan frissítjük az adatokat
  Timer? refreshTimer;

  late DateTime now = DateTime.now();

  String? authToken;

  Future<String?> loginReceptionist() async {
    final api = ApiService();
    final token =
        await api.loginUser('receptionAdmin@gmail.com', 'AdminPassword1');

    if (token == null) {
      print('Nem sikerült bejelentkezni');
    } else {
      print('token: $token');
      setState(() {
        authToken = token;
      });
      fetchReservations();
    }
    return token;
  }

  /// Lekérdezett foglalások
  List<dynamic>? reservations;

  Future<void> fetchReservations() async {
    final api = ApiService();
    final data = await api.getReservations(authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        reservations = data;
      });
      fetchServiceTemplates();
    }
  }

  /// Lekérdezett szolgáltatások
  List<dynamic>? serviceTemplates;

  Future<void> fetchServiceTemplates() async {
    final api = ApiService();
    final data = await api.getServiceTemplates(authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        serviceTemplates = data;
      });
      zoneCounters =
          mapCurrentOccupancyByZones(reservations!, serviceTemplates!);
    }
  }

  Map<String, int> zoneCounters = {};

  // parkoló zóna -> jelenlegi foglalások száma
  Map<String, int> mapCurrentOccupancyByZones(
      List<dynamic> reservations, List<dynamic> serviceTemplates) {
    zoneCounters = {}; // kinullázzuk, hogy frissítésekkor ne duplikálódjon

    // mostani idő lekerekítve félórára
    final currentSlot = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute - (now.minute % 30),
    );

    for (var reservation in reservations) {
      final parkingArticleId = reservation['ParkingArticleId'];
      if (parkingArticleId == null || parkingArticleId == "") continue;

      final arrive = DateTime.parse(reservation['ArriveDate']);
      final leave = DateTime.parse(reservation['LeaveDate']);

      // Megnézi hogy a foglalás szerint most itt van-e az autó
      if (!currentSlot.isBefore(arrive) && currentSlot.isBefore(leave)) {
        zoneCounters[parkingArticleId] =
            (zoneCounters[parkingArticleId] ?? 0) + 1;
      }
    }

    return zoneCounters;
  }

  Widget buildZoneOccupancyIndicators({
    required List<dynamic> serviceTemplates,
    required Map<String, int> zoneCounters,
  }) {
    final parkingTemplates =
        serviceTemplates.where((t) => t['ParkingServiceType'] == 1).toList();

    return Wrap(
      spacing: 20,
      children: [
        for (var template in parkingTemplates)
          ZoneOccupancyIndicator(
            zoneName: template['ParkingServiceName'].split(' ').last,
            occupied: zoneCounters[template['ArticleId']] ?? 0,
            capacity: template['ZoneCapacity'],
          ),
      ],
    );
  }

  Widget buildReservationList({
    required List<dynamic> reservations,
  }) {
    /// Kiszűrjük azokat a foglalásokat, amelyeknek az ArriveDate-je a múltban van.
    /// Rendezzük ArriveDate szerint.
    final List<dynamic> upcomingReservations = [];

    for (var reservation in reservations) {
      final arriveDate = DateTime.parse(reservation['ArriveDate']);
      if (arriveDate.isAfter(now)) {
        upcomingReservations.add(reservation);
      }
    }

    // Rendezés arriveDate szerint
    upcomingReservations.sort((a, b) => DateTime.parse(a['ArriveDate'])
        .compareTo(DateTime.parse(b['ArriveDate'])));

    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade300,
        ),
        child: ReservationList(
          listTitle: 'Foglalások',
          reservations: upcomingReservations,
          columns: {
            'Felhasználó név': 'Name',
            'Rendszám': 'LicensePlate',
            'Érkezés dátuma': 'ArriveDate',
          },
          formatters: {
            'ArriveDate': (reservation) => DateFormat('yyyy.MM.dd HH:mm')
                .format(DateTime.parse(reservation['ArriveDate'])),
          },
        ));
  }

  Widget buildTodoList({
    required dynamic reservations,
    required DateTime startTime,
    required DateTime endTime,
    required String listTitle,
  }) {
    // Szűrés: csak a mai napon érkező vagy távozó foglalások
    final List<dynamic> todaysReservations = [];

    // Segédfüggvény: Megvizsgálja hogy az ArriveDate elmúlt-e már
    // ArriveDate nem múlt el -> ArriveDate jön
    // ArriveDate elmúlt -> LeaveDate jön
    DateTime getEarliestTime(
        DateTime arrive, DateTime leave, DateTime startTime) {
      final bool isArriveFuture = arrive.isAfter(startTime);

      if (isArriveFuture) {
        return arrive;
      } else {
        return leave;
      }
    }

    for (var reservation in reservations) {
      final arriveDate = DateTime.parse(reservation['ArriveDate']);
      final leaveDate = DateTime.parse(reservation['LeaveDate']);

      // Csak azok a foglalások, amelyeknek arrive vagy leave date-je a jövőben, de még ma van
      final bool isArriveToday =
          arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);
      final bool isLeaveToday =
          leaveDate.isAfter(startTime) && leaveDate.isBefore(endTime);

      if (isArriveToday || isLeaveToday) {
        todaysReservations.add(reservation);
      }
    }

    // Rendezés: a korábbi dátum (arrive vagy leave) szerint
    todaysReservations.sort((a, b) {
      final aArrive = DateTime.parse(a['ArriveDate']);
      final aLeave = DateTime.parse(a['LeaveDate']);
      final bArrive = DateTime.parse(b['ArriveDate']);
      final bLeave = DateTime.parse(b['LeaveDate']);

      // Mindkét foglalásnál megnézzük a korábbi mai időpontot
      final aEarliest = getEarliestTime(aArrive, aLeave, startTime);
      final bEarliest = getEarliestTime(bArrive, bLeave, startTime);

      return aEarliest.compareTo(bEarliest);
    });

    // Widget visszaadása
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade300,
      ),
      child: ReservationList(
        listTitle: listTitle,
        reservations: todaysReservations,
        columns: {
          'Felhasználó név': 'Name',
          'Rendszám': 'LicensePlate',
          'Időpont': 'Time',
          'Típus': 'Type',
        },
        formatters: {
          'Time': (reservation) {
            final arriveDate = DateTime.parse(reservation['ArriveDate']);
            final leaveDate = DateTime.parse(reservation['LeaveDate']);
            final isArriveToday =
                arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);

            if (isArriveToday) {
              return DateFormat('HH:mm').format(arriveDate);
            } else {
              return DateFormat('HH:mm').format(leaveDate);
            }
          },
          'Type': (reservation) {
            final arriveDate = DateTime.parse(reservation['ArriveDate']);
            final isArriveToday =
                arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);

            if (isArriveToday) {
              return 'Érkezés';
            } else {
              return 'Távozás';
            }
          },
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    loginReceptionist();

    // percenként frissítjük a foglalásokat
    refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Container()),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: reservations != null
                          ? Column(
                              children: [
                                buildTodoList(
                                    listTitle: 'Ma',
                                    reservations: reservations,
                                    startTime: now,
                                    endTime: DateTime(
                                        now.year, now.month, now.day + 1)),
                                SizedBox(height: 16),
                                buildTodoList(
                                    listTitle: 'Holnap',
                                    reservations: reservations,
                                    startTime: DateTime(
                                        now.year, now.month, now.day + 1),
                                    endTime: DateTime(
                                        now.year, now.month, now.day + 2)),
                                SizedBox(height: 16),
                              ],
                            )
                          : ShimmerPlaceholderTemplate(
                              width: double.infinity, height: 100),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          MyIconButton(
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
                        ],
                      ),
                    ),
                  ],
                ),
                reservations != null
                    ? buildReservationList(reservations: reservations!)
                    : Shimmer(
                        child: ShimmerPlaceholderTemplate(
                            width: double.infinity, height: 350),
                      ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                (serviceTemplates != null && reservations != null)
                    ? buildZoneOccupancyIndicators(
                        serviceTemplates: serviceTemplates!,
                        zoneCounters: zoneCounters,
                      )
                    : Wrap(
                        spacing: 20,
                        children: [
                          for (int i = 0; i <= 2; i++)
                            ShimmerPlaceholderTemplate(width: 50, height: 60)
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
