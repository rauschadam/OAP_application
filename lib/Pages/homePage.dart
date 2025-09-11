import 'dart:async';

import 'package:airport_test/Pages/reservationListPage.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/Pages/bookingForm/bookingOptionPage.dart';
import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/constant_widgets/my_icon_button.dart';
import 'package:airport_test/constants/constant_widgets/reservation_list.dart';
import 'package:airport_test/constants/constant_widgets/shimmer_placeholder_template.dart';
import 'package:airport_test/constants/constant_widgets/side_menu.dart';
import 'package:airport_test/constants/constant_widgets/zone_occupancy_indicator.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      //fetchData();
      fetchReservations();
    }
    return token;
  }

  /// Lekérdezett foglalások
  List<dynamic>? reservations;

  /// Lekérdezett szolgáltatások
  List<dynamic>? serviceTemplates;

  /// article id -> foglalt helyek száma
  Map<String, int> zoneCounters = {};

  /// Foglalások lekérdezése
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

  /// Szolgáltatások lekérdezése
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
      fullyBookedDateTimes =
          mapBookedDateTimesByZones(reservations!, serviceTemplates!);
    }
  }

  //Teljes időpontos foglalt időpontok
  Map<String, List<DateTime>> fullyBookedDateTimes =
      {}; // parkoló zóna ArticleId -> telített időpont

  // parkoló zóna -> telített időpontok
  Map<String, List<DateTime>> mapBookedDateTimesByZones(
      List<dynamic> reservations, List<dynamic> serviceTemplates) {
    // Kiveszi a zónák kapacitását a Templates-ekből
    final Map<String, int> zoneCapacities = {}; // parkoló zóna -> kapacitás
    for (var template in serviceTemplates) {
      if (template['ParkingServiceType'] != 1) {
        continue; // Csak a parkolásokat nézze
      }
      final String articleId = template['ArticleId'];
      final int capacity = template['ZoneCapacity'] ?? 1;
      zoneCapacities[articleId] = capacity;
    }

    // időpont számláló zónánként
    Map<String, Map<DateTime, int>> counters =
        {}; // parkoló zóna -> (egy időpont hányszor szerepel)

    for (var reservation in reservations) {
      final parkingArticleId = reservation['ParkingArticleId'];

      final arrive = DateTime.parse(reservation['ArriveDate']);
      final leave = DateTime.parse(reservation['LeaveDate']);

      counters.putIfAbsent(parkingArticleId, () => {});

      DateTime current = DateTime(
        arrive.year,
        arrive.month,
        arrive.day,
        arrive.hour,
        arrive.minute - (arrive.minute % 30),
      );

      // végig iterál az érkezéstől a távozás időpontjáig, az időpont számlálót növeli 1-el
      while (current.isBefore(leave)) {
        counters[parkingArticleId]![current] =
            (counters[parkingArticleId]![current] ?? 0) + 1;
        current = current.add(const Duration(minutes: 30));
      }
    }

    /// Parkoló zóna -> telített időpontok
    Map<String, List<DateTime>> fullyBookedDateTimesByZone = {};

    counters.forEach((parkingArticleId, counter) {
      if (parkingArticleId != "") {
        final capacity = zoneCapacities[parkingArticleId];
        fullyBookedDateTimesByZone[parkingArticleId] = counter.entries
            .where((entry) => entry.value >= capacity!)
            .map((entry) => entry.key)
            .toList();
      }
    });

    return fullyBookedDateTimesByZone;
  }

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
    required List<dynamic>? serviceTemplates,
    required Map<String, int> zoneCounters,
    required int parkingServiceType,
  }) {
    if (serviceTemplates == null) {
      return Padding(
        padding: const EdgeInsets.all(AppPadding.xlarge),
        child: Wrap(
          spacing: 20,
          children: [
            for (int i = 0; i <= 2; i++)
              ShimmerPlaceholderTemplate(width: 100, height: 120)
          ],
        ),
      );
    }
    final parkingTemplates = serviceTemplates
        .where((t) => t['ParkingServiceType'] == parkingServiceType)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.large),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          color: BasePage.defaultColors.secondary,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Wrap(
            spacing: 20,
            children: [
              for (var template in parkingTemplates)
                ZoneOccupancyIndicator(
                  zoneName: template['ParkingServiceName'].split(' ').last,
                  occupied: zoneCounters[template['ArticleId']] ?? 0,
                  capacity: template['ZoneCapacity'],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFullyBookedTimeList(
      {required Map<String, List<DateTime>> fullyBookedDateTimes}) {
    String getZoneNameById(String articleId) {
      switch (articleId) {
        case "1-95426": // Premium
          return 'Premium';
        case "1-95427": // Normal
          return 'Normal';
        case "1-95428": // Eco
          return 'Eco';
        default:
          return 'Egyéb';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            color: BasePage.defaultColors.secondary),
        padding: EdgeInsets.all(AppPadding.large),
        width: double.infinity,
        height: double.infinity < MediaQuery.of(context).size.height * 0.4
            ? double.infinity
            : MediaQuery.of(context).size.height * 0.4,
        child: ListView(
          children: [
            for (var entry in fullyBookedDateTimes.entries)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header a string kulccsal
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      title: Text(
                        getZoneNameById(entry.key),
                      ),
                      initiallyExpanded: true,
                      children: [
                        // Dátumtartományok csoportosítása
                        ...groupConsecutiveTimeSlots(entry.value)
                            .map((range) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppPadding.large,
                                    vertical: AppPadding.small,
                                  ),
                                  child: Text(
                                    range.length == 1
                                        ? DateFormat('yyyy.MM.dd HH:mm')
                                            .format(range.first)
                                        : '${DateFormat('yyyy.MM.dd HH:mm').format(range.first)} - ${DateFormat('yyyy.MM.dd HH:mm').format(range.last)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                )),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Segédfüggvény az egybefüggő időpontok csoportosításához
  List<List<DateTime>> groupConsecutiveTimeSlots(List<DateTime> timeSlots) {
    if (timeSlots.isEmpty) return [];

    // Rendezzük dátum szerint
    timeSlots.sort((a, b) => a.compareTo(b));

    List<List<DateTime>> groups = [];
    List<DateTime> currentGroup = [timeSlots.first];

    for (int i = 1; i < timeSlots.length; i++) {
      final currentTime = timeSlots[i];
      final previousTime = timeSlots[i - 1];

      // Ellenőrizzük, hogy a következő időpont pontosan 30 perccel későbbi-e
      if (currentTime.difference(previousTime) == Duration(minutes: 30)) {
        currentGroup.add(currentTime);
      } else {
        groups.add(List.from(currentGroup));
        currentGroup = [currentTime];
      }
    }

    // Az utolsó csoport hozzáadása
    groups.add(currentGroup);

    return groups;
  }

  Widget buildTodoList({
    required List<dynamic>? reservations,
    required DateTime startTime,
    required DateTime endTime,
    required String listTitle,
    double? maxHeight,
  }) {
    if (reservations == null) {
      return ShimmerPlaceholderTemplate(
          width: double.infinity, height: maxHeight ?? double.infinity);
    }
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
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          color: BasePage.defaultColors.secondary //Colors.grey.shade300,
          ),
      child: ReservationList(
        maxHeight: maxHeight,
        listTitle: listTitle,
        reservations: todaysReservations,
        columns: {
          'Név': 'Name',
          'Rendszám': 'LicensePlate',
          'Időpont': 'Time',
          'Típus': 'Type',
        },
        formatters: {
          'Time': (reservation) {
            final arriveDate = DateTime.parse(reservation['ArriveDate']);
            final leaveDate = DateTime.parse(reservation['LeaveDate']);
            final carWashDate = DateTime.parse(reservation['WashDateTime']);
            final isCarWashToday =
                carWashDate.isAfter(startTime) && carWashDate.isBefore(endTime);
            final isArriveToday =
                arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);

            if (isArriveToday) {
              return DateFormat('HH:mm').format(arriveDate);
            } else if (!isCarWashToday) {
              return DateFormat('HH:mm').format(leaveDate);
            } else {
              return DateFormat('HH:mm').format(carWashDate);
            }
          },
          'Type': (reservation) {
            final arriveDate = DateTime.parse(reservation['ArriveDate']);
            final carWashDate = DateTime.parse(reservation['WashDateTime']);
            final isCarWashToday =
                carWashDate.isAfter(startTime) && carWashDate.isBefore(endTime);
            final isArriveToday =
                arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);

            if (isArriveToday) {
              return 'Érkezés';
            } else if (!isCarWashToday) {
              return 'Távozás';
            } else {
              return 'Mosás';
            }
          },
        },
      ),
    );
  }

  void GoToReservationPage() async {
    final token = await loginReceptionist();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bejelentkezés folyamatban!')),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BasePage(
            child: ReservationListPage(authToken: authToken!),
          ),
        ),
      );
    }
  }

  Widget buildSideMenu() {
    List<MenuItem> menuItems = [
      MenuItem(
          icon: Icons.list_alt_rounded,
          title: "Foglalások",
          onPressed: GoToReservationPage),
    ];
    return SideMenu(menuItems: menuItems);
  }

  @override
  void initState() {
    super.initState();

    loginReceptionist();

    // percenként frissítjük a foglalásokat
    refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
      fetchReservations();
      //fetchData();
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
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: buildSideMenu(),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.bottomRight,
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
                SizedBox(height: 8),
                Column(
                  children: [
                    buildTodoList(
                        maxHeight: 200,
                        listTitle: 'Ma',
                        reservations: reservations,
                        startTime: now,
                        endTime: DateTime(now.year, now.month, now.day + 1)),
                    SizedBox(height: 16),
                    buildTodoList(
                        maxHeight: 200,
                        listTitle: 'Holnap',
                        reservations: reservations,
                        startTime: DateTime(now.year, now.month, now.day + 1),
                        endTime: DateTime(now.year, now.month, now.day + 2)),
                    SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              buildZoneOccupancyIndicators(
                serviceTemplates: serviceTemplates,
                zoneCounters: zoneCounters,
                parkingServiceType: 1,
              ),
              fullyBookedDateTimes.isNotEmpty
                  ? buildFullyBookedTimeList(
                      fullyBookedDateTimes: fullyBookedDateTimes)
                  : Container()
            ],
          ),
        ),
      ],
    );
  }
}
