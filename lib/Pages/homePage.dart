import 'dart:async';

import 'package:airport_test/Pages/reservationListPage.dart';
import 'package:airport_test/Pages/reservationForm/reservationOptionPage.dart';
import 'package:airport_test/api_Services/api_service.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_icon_button.dart';
import 'package:airport_test/constants/widgets/reservation_list.dart';
import 'package:airport_test/constants/widgets/search_bar.dart';
import 'package:airport_test/constants/widgets/shimmer_placeholder_template.dart';
import 'package:airport_test/constants/widgets/side_menu.dart';
import 'package:airport_test/constants/widgets/zone_occupancy_indicator.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/responsive.dart';
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
  FocusNode searchFocus = FocusNode();
  final SearchController searchController = SearchController();
  final GlobalKey searchContainerKey = GlobalKey();

  /// Automatikusan frissítjük az adatokat 1 percenként
  Timer? refreshTimer;

  /// Mostani idő (percenként frissül)
  late DateTime now = DateTime.now();

  /// Lekérdezett foglalások
  List<dynamic>? reservations;

  /// Keresésésnek megfelelő foglalások
  List<dynamic>? filteredReservations;

  /// Lekérdezett szolgáltatások
  List<dynamic>? serviceTemplates;

  /// parkoló zóna article id-> foglalt helyek száma
  Map<String, int> zoneCounters = {};

  /// Lekérdezések még folyamatban vannak
  bool loading = true;

  /// Foglalások és szolgáltatások lekérdezése
  Future<void> fetchData() async {
    final api = ApiService();
    // Foglalások lekérdezése
    final reservationsData = await api.getReservations(receptionistToken);
    // Szolgáltatások lekérdezése
    final servicesData = await api.getServiceTemplates(receptionistToken);

    if (reservationsData != null && servicesData != null) {
      setState(() {
        reservations = reservationsData;
        serviceTemplates = servicesData;
        zoneCounters =
            mapCurrentOccupancyByZones(reservations!, serviceTemplates!);
        fullyBookedDateTimes =
            mapBookedDateTimesByZones(reservations!, serviceTemplates!);
        loading = false;
      });
    }
  }

  /// Ügyfél érkeztetése
  Future<void> attemptRegisterArrival(String licensePlate) async {
    final api = ApiService();
    // Foglalások lekérdezése
    final customerArrivalData = await api.logCustomerArrival(licensePlate);

    if (customerArrivalData != null) {
      setState(() {});
    }
  }

  /// Ügyfél távoztatása
  Future<void> attemptRegisterLeave(String licensePlate) async {
    final api = ApiService();
    // Foglalások lekérdezése
    final customerArrivalData = await api.logCustomerLeave(licensePlate);

    if (customerArrivalData != null) {
      setState(() {});
    }
  }

  /// Foglalt időpontok
  Map<String, List<DateTime>> fullyBookedDateTimes =
      {}; // parkoló zóna ArticleId -> telített időpont

  /// Parkoló zóna -> telített időpontok
  Map<String, List<DateTime>> mapBookedDateTimesByZones(
      List<dynamic> reservations, List<dynamic> serviceTemplates) {
    final Map<String, int> zoneCapacities = {}; // parkoló zóna -> kapacitás
    // Kiveszi a zónák kapacitását a Templates-ekből
    for (var template in serviceTemplates) {
      if (template['ParkingServiceType'] != 1) {
        continue; // Csak a parkolásokat nézze (parkoló zónáknál a ParkingServiceType = 1)
      }
      final String articleId = template['ArticleId'];
      final int capacity = template['ZoneCapacity'] ?? 1;
      zoneCapacities[articleId] = capacity;
    }

    /// Parkoló zóna -> (Időpontok előfordulása)
    Map<String, Map<DateTime, int>> counters = {};

    /// Időpontok előfordulásának kiszámolása zónánként
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

      // végig iterál az érkezéstől a távozás időpontjáig, az adott időpont számlálótját növeli 1-el
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

  /// parkoló zóna -> jelenlegi foglalások száma
  Map<String, int> mapCurrentOccupancyByZones(
      List<dynamic> reservations, List<dynamic> serviceTemplates) {
    zoneCounters = {}; // kinullázzuk, hogy frissítéskor ne duplikálódjon

    /// mostani idő lekerekítve félórára
    final currentSlot = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute - (now.minute % 30),
    );

    // foglalásokból megkeressük, melyik vonatkozik a jelenre
    for (var reservation in reservations) {
      final parkingArticleId = reservation['ParkingArticleId'];
      if (parkingArticleId == null || parkingArticleId == "") continue;

      final arrive = DateTime.parse(reservation['ArriveDate']);
      final leave = DateTime.parse(reservation['LeaveDate']);

      if (!currentSlot.isBefore(arrive) && currentSlot.isBefore(leave)) {
        zoneCounters[parkingArticleId] =
            (zoneCounters[parkingArticleId] ?? 0) + 1;
      }
    }

    return zoneCounters;
  }

  /// A jelenlegi zóna foglaltságokat jeleníti meg
  Widget buildZoneOccupancyIndicators({
    required List<dynamic>? serviceTemplates,
    required Map<String, int> zoneCounters,
    required int parkingServiceType,
  }) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.only(
            top: AppPadding.medium,
            left: AppPadding.medium,
            right: AppPadding.medium),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            color: BasePage.defaultColors.secondary,
          ),
          child: ShimmerPlaceholderTemplate(
            width: double.infinity,
            height: 220,
          ),
        ),
      );
    }

    if (!loading && serviceTemplates == null) {
      return Center(child: Text('Nem találhatóak parkoló zónák'));
    }

    final parkingTemplates = serviceTemplates!
        .where((t) => t['ParkingServiceType'] == parkingServiceType)
        .toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        color: BasePage.defaultColors.secondary,
      ),
      width: double.infinity,
      child: Padding(
        /// Tartalom padding
        padding: const EdgeInsets.symmetric(vertical: AppPadding.large),
        child: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.only(bottom: AppPadding.medium),
            //   child: Text(
            //     'Jelenlegi Telítettség',
            //     style: TextStyle(
            //       fontSize: 18,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.black,
            //     ),
            //   ),
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var template in parkingTemplates)
                  ZoneOccupancyIndicator(
                    zoneName: template['ParkingServiceName'].split(' ').last,
                    occupied: zoneCounters[template['ArticleId']] ?? 0,
                    capacity: template['ZoneCapacity'],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Telített időpontok listáját jeleníti meg
  Widget buildFullyBookedTimeList(
      {required Map<String, List<DateTime>> fullyBookedDateTimes}) {
    if (loading) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          color: BasePage.defaultColors.secondary,
        ),
        child: ShimmerPlaceholderTemplate(
          width: double.infinity,
          height: 240,
        ),
      );
    }
    // Szűrjük ki az üres listákat
    final nonEmptyZoneTimes = fullyBookedDateTimes.values
        .where((zoneTimes) => zoneTimes.isNotEmpty)
        .toList();

    if (nonEmptyZoneTimes.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          color: BasePage.defaultColors.secondary,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Text("Nincsenek telített időpontok"),
        ),
      );
    }

    /// Segédfüggvény, a templates-ből meghatározza a zóna nevét ArticleId alapján
    String getZoneNameById(String articleId) {
      final template = serviceTemplates?.firstWhere(
        (t) => t['ArticleId'] == articleId,
        orElse: () => null,
      );
      return template != null
          ? template['ParkingServiceName'].split(' ').last
          : 'Egyéb';
    }

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          color: BasePage.defaultColors.secondary),
      // Tartalom padding
      padding: EdgeInsets.all(AppPadding.large),
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: double.infinity,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppPadding.medium),
            child: Text(
              'Telített időpontok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (var entry in fullyBookedDateTimes.entries)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                        ),
                        // Zóna név
                        child: ExpansionTile(
                          title: Text(
                            getZoneNameById(entry.key),
                          ),
                          children: [
                            // Dátumtartományok csoportosítása
                            ...groupConsecutiveTimeSlots(entry.value).map(
                              (range) => Padding(
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Segédfüggvény az egybefüggő időpontok csoportosításához.
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

  // TODO: Mosás időpontot, VIP sofőrt, transfer számot is megjeleníteni
  /// Egy adott intervallumra szóló foglalás lista, a recepciós feladatait célozza.
  /// Pl.: Autó érkeztetése, autó távoztatása
  Widget buildTodoList({
    required List<dynamic>? reservations,
    required DateTime startTime,
    required DateTime endTime,
    required String listTitle,
    double? maxHeight,
  }) {
    if (loading) {
      return ShimmerPlaceholderTemplate(
          width: double.infinity, height: maxHeight ?? double.infinity);
    }

    if (!loading && reservations == null) {
      return Center(child: Text('Nem találhatóak foglalások'));
    }

    /// Szűrés: csak az adott intervallumban érkező, távozó vagy mosást igénylő foglalások
    final List<dynamic> actualReservations = [];

    // Segédfüggvény: Megvizsgálja hogy az ArriveDate elmúlt-e már
    // ArriveDate nem múlt el -> ArriveDate lesz legközelebb
    // ArriveDate elmúlt -> LeaveDate lesz legközelebb
    DateTime getEarliestTime(
        DateTime arrive, DateTime leave, DateTime startTime) {
      final bool isArriveInFuture = arrive.isAfter(startTime);

      if (isArriveInFuture) {
        return arrive;
      } else {
        return leave;
      }
    }

    for (var reservation in reservations!) {
      final arriveDate = DateTime.parse(reservation['ArriveDate']);
      final leaveDate = DateTime.parse(reservation['LeaveDate']);

      // Csak azok a foglalások, amelyeknek arrive vagy leave date-je a jövőben, de még az intervallumon belül van
      final bool isArriveToday =
          arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);
      final bool isLeaveToday =
          leaveDate.isAfter(startTime) && leaveDate.isBefore(endTime);

      if (isArriveToday || isLeaveToday) {
        actualReservations.add(reservation);
      }
    }

    // Rendezés: a korábbi dátum (arrive vagy leave) szerint
    actualReservations.sort((a, b) {
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
    return ReservationList(
      maxHeight: maxHeight,
      listTitle: listTitle,
      emptyText: "Nem várható bejelentett ügyfél.",
      reservations: actualReservations,
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
    );
  }

  void applySearch() {
    if (reservations == null) return;

    final String query = searchController.text.toUpperCase();

    if (query.isEmpty) {
      setState(() {
        filteredReservations = null;
      });
      return;
    }

    final Set<String> seenPlates = {};
    setState(() {
      filteredReservations = reservations!.where((reservation) {
        final licensePlate = reservation['LicensePlate'].toString();
        final matches = licensePlate.contains(query);
        if (matches && !seenPlates.contains(licensePlate)) {
          seenPlates.add(licensePlate);
          return true;
        }
        return false;
      }).toList();
    });
  }

  Widget buildSearchBar() {
    return SizedBox(
      width: 300,
      height: 35,
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: BasePage.defaultColors.background,
          ),
        ),
        child: SearchBar(
          focusNode: searchFocus,
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          backgroundColor:
              WidgetStateProperty.all(BasePage.defaultColors.primary),
          hintStyle: WidgetStateProperty.all<TextStyle>(
            TextStyle(
              color: BasePage.defaultColors.background.withAlpha(200),
              fontWeight: FontWeight.w600,
            ),
          ),
          textStyle: WidgetStateProperty.all<TextStyle>(
            TextStyle(
              color: BasePage.defaultColors.background,
              fontWeight: FontWeight.w600,
            ),
          ),
          controller: searchController,
          hintText: 'Keresés...',
          leading: Icon(
            Icons.search,
            size: 20,
            color: BasePage.defaultColors.background,
          ),
          trailing: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: BasePage.defaultColors.background,
                    ),
                    constraints: BoxConstraints(),
                    onPressed: () {
                      searchController.clear();
                    },
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildSearchResults() {
    if (filteredReservations == null || filteredReservations!.isEmpty) {
      return SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.small),
      child: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            children: filteredReservations!.asMap().entries.map((entry) {
              final index = entry.key;
              final reservation = entry.value;
              final licensePlate =
                  reservation['LicensePlate']?.toString() ?? 'Ismeretlen';

              return Padding(
                padding: const EdgeInsets.only(left: AppPadding.small),
                child: InkWell(
                  onTap: () => showArrivalDepartureDialog(licensePlate),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.directions_car,
                                size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                licensePlate,
                                style: TextStyle(
                                  color: BasePage.defaultColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Divider csak akkor, ha nem az utolsó elem
                      if (index < filteredReservations!.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey[300],
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void showArrivalDepartureDialog(String licensePlate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Művelet kiválasztása'),
          content: Text(licensePlate),
          actions: [
            // Mégsem gomb
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Mégsem'),
            ),

            // Távoztatás gomb
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                searchController.clear();
                setState(() {
                  filteredReservations = null;
                });
                attemptRegisterLeave(licensePlate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Távoztatás'),
            ),

            // Érkeztetés gomb
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                searchController.clear();
                setState(() {
                  filteredReservations = null;
                });
                attemptRegisterArrival(licensePlate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Érkeztetés'),
            ),
          ],
        );
      },
    );
  }

  void GoToReservationPage() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BasePage(
          child: ReservationListPage(),
        ),
      ),
    );
  }

  /// Oldal Menü megjelenítése
  Widget buildSideMenu() {
    List<MenuItem> menuItems = [
      MenuItem(
          icon: Icons.list_alt_rounded,
          title: "Foglalások",
          onPressed: GoToReservationPage),
    ];
    return SideMenu(menuItems: menuItems);
  }

  Widget newReservationButton() {
    return Align(
      alignment: Alignment.bottomRight,
      child: MyIconButton(
        icon: Icons.add_rounded,
        labelText: "Foglalás rögzítése",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BasePage(
                child: ReservationOptionPage(),
              ),
            ),
          );
          dispose(); // Megszüntetjük a frissítést, mert különben a timer tovább fut
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    fetchData();

    searchController.addListener(applySearch);

    // percenként frissítjük a foglalásokat
    refreshTimer = Timer.periodic(Duration(minutes: 5), (_) {
      fetchData();
      setState(() {
        now = DateTime.now();
      });
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
    if (Responsive.isMobile(context)) {
      return mobileBuild();
    } else {
      return desktopBuild();
    }
  }

  Widget desktopBuild() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(right: AppPadding.medium),
            child: buildSideMenu(),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppPadding.medium),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SearchBarContainer(
                      searchContainerKey: searchContainerKey,
                      transparency: searchFocus.hasFocus &&
                          searchController.value.text.isNotEmpty,
                      children: [
                        buildSearchBar(),
                        buildSearchResults(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: AppPadding.small),
                        child: newReservationButton(),
                      ),
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: AppPadding.medium),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppBorderRadius.medium),
                                color: BasePage.defaultColors.secondary),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  constraints: BoxConstraints(maxHeight: 300),
                                  child: buildTodoList(
                                      listTitle: 'Ma',
                                      reservations: reservations,
                                      startTime: now,
                                      endTime:
                                          DateTime(now.year, now.month, now.day)
                                              .add(const Duration(days: 1))),
                                ),
                                Container(
                                  constraints: BoxConstraints(maxHeight: 300),
                                  child: buildTodoList(
                                      listTitle: 'Holnap',
                                      reservations: reservations,
                                      startTime:
                                          DateTime(now.year, now.month, now.day)
                                              .add(const Duration(days: 1)),
                                      endTime:
                                          DateTime(now.year, now.month, now.day)
                                              .add(const Duration(days: 2))),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(AppPadding.medium),
            child: Column(
              children: [
                buildZoneOccupancyIndicators(
                  serviceTemplates: serviceTemplates,
                  zoneCounters: zoneCounters,
                  parkingServiceType: 1,
                ),
                SizedBox(height: AppPadding.medium),
                Flexible(
                  child: buildFullyBookedTimeList(
                      fullyBookedDateTimes: fullyBookedDateTimes),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget mobileBuild() {
    return Padding(
      padding: EdgeInsetsGeometry.all(AppPadding.medium),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: buildZoneOccupancyIndicators(
                    serviceTemplates: serviceTemplates,
                    zoneCounters: zoneCounters,
                    parkingServiceType: 1),
              ),
            ],
          ),
          const Spacer(),
          newReservationButton()
        ],
      ),
    );
  }
}
