import 'dart:async';
import 'package:airport_test/Pages/reservationListPage.dart';
import 'package:airport_test/Pages/reservationForm/reservationOptionPage.dart';
import 'package:airport_test/api_Services/api_service.dart';
import 'package:airport_test/api_services/api_classes/service_templates.dart';
import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
import 'package:airport_test/constants/dialogs/reservation_options_dialog.dart';
import 'package:airport_test/constants/functions/reservation_state.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_icon_button.dart';
import 'package:airport_test/constants/widgets/reservation_list.dart';
import 'package:airport_test/constants/widgets/search_bar.dart';
import 'package:airport_test/constants/widgets/shimmer_placeholder_template.dart';
import 'package:airport_test/constants/widgets/side_menu.dart';
import 'package:airport_test/constants/widgets/zone_occupancy_indicator.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget with PageWithTitle {
  HomePage({super.key});

  @override
  String get pageTitle => 'Menü';

  @override
  bool get haveMargins => false;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FocusNode searchFocus = FocusNode();
  FocusNode keyboardFocus = FocusNode();
  final SearchController searchController = SearchController();
  final GlobalKey searchContainerKey = GlobalKey();
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  int selectedPageIndex = 0;

  /// Automatikusan frissítjük az adatokat 1 percenként
  Timer? refreshTimer;

  /// Mostani idő (percenként frissül)
  late DateTime now = DateTime.now();

  /// Lekérdezett foglalások
  List<ValidReservation>? reservations;
  //List<dynamic>? reservations;

  /// Keresésnek megfelelő rendszámok listája
  List<ValidReservation>? searchResults;

  /// Kereséshez kiválasztott index a searchResults listában
  int? selectedSearchIndex;

  /// parkoló zóna article id-> foglalt helyek száma
  Map<String, int> zoneCounters = {};

  /// True -> Lekérdezések még folyamatban vannak
  bool loading = true;

  /// Foglalások és szolgáltatások lekérdezése
  Future<void> fetchData() async {
    if (!mounted) return;
    final api = ApiService();
    // Foglalások lekérdezése
    final reservationsData = await api.getValidReservations(context);
    if (!mounted) return;

    if (reservationsData != null) {
      setState(() {
        reservations = reservationsData;
        zoneCounters = mapCurrentOccupancyByZones(reservations!);
        fullyBookedDateTimes = mapBookedDateTimesByZones(reservations!);
        loading = false;
      });
    }
  }

  /// Ügyfél érkeztetése
  Future<void> attemptRegisterArrival(String licensePlate) async {
    final api = ApiService();
    await api.logCustomerArrival(context, licensePlate);
    fetchData();
  }

  /// Ügyfél távoztatása
  Future<void> attemptRegisterLeave(String licensePlate) async {
    final api = ApiService();
    await api.logCustomerLeave(context, licensePlate);
    fetchData();
  }

  /// Rendszám módosítása
  Future<void> attemptChangeLicensePlate(
      int webParkingId, String newLicensePlate) async {
    final api = ApiService();
    await api.changeLicensePlate(context, webParkingId, newLicensePlate);
    fetchData();
  }

  /// Foglalt időpontok
  Map<String, List<DateTime>> fullyBookedDateTimes =
      {}; // parkoló zóna ArticleId -> telített időpont

  /// Parkoló zóna -> telített időpontok
  Map<String, List<DateTime>> mapBookedDateTimesByZones(
      List<dynamic> reservations) {
    final Map<String, int> zoneCapacities = {}; // parkoló zóna -> kapacitás
    // Kiveszi a zónák kapacitását a Templates-ekből
    for (ServiceTemplate template in ServiceTemplates) {
      if (template.parkingServiceType != 1) {
        continue; // Csak a parkolásokat nézze (parkoló zónáknál a ParkingServiceType = 1)
      }
      final String articleId = template.articleId!;
      final int capacity = template.zoneCapacity!;
      zoneCapacities[articleId] = capacity;
    }

    /// Parkoló zóna -> (Időpontok előfordulása)
    Map<String, Map<DateTime, int>> counters = {};

    /// Időpontok előfordulásának kiszámolása zónánként
    for (ValidReservation reservation in reservations) {
      final parkingArticleId = reservation.parkingArticleId;

      final arrive = reservation.arriveDate;
      final leave = reservation.leaveDate;

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
            .where((entry) => entry.value >= (capacity ?? 0))
            .map((entry) => entry.key)
            .toList();
      }
    });

    return fullyBookedDateTimesByZone;
  }

  /// parkoló zóna -> jelenlegi foglalások száma
  Map<String, int> mapCurrentOccupancyByZones(List<dynamic> reservations) {
    zoneCounters = {}; // kinullázzuk, hogy frissítéskor ne duplikálódjon

    // foglalásokból megkeressük, melyik vonatkozik a jelenre
    for (ValidReservation reservation in reservations) {
      final parkingArticleId = reservation.parkingArticleId;
      final bool isParking = (reservation.state == 1 || reservation.state == 2);

      if (isParking) {
        zoneCounters[parkingArticleId] =
            (zoneCounters[parkingArticleId] ?? 0) + 1;
      }
    }

    return zoneCounters;
  }

  /// A jelenlegi zóna foglaltságokat jeleníti meg
  Widget buildZoneOccupancyIndicators({
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
            color: AppColors.secondary,
          ),
          child: ShimmerPlaceholderTemplate(
            width: double.infinity,
            height: 220,
          ),
        ),
      );
    }

    if (ServiceTemplates.isEmpty) {
      return Center(child: Text('Nem találhatóak parkoló zónák'));
    }

    final parkingTemplates = ServiceTemplates.where(
        (t) => t.parkingServiceType == parkingServiceType).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        color: AppColors.secondary,
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
                    zoneName: template.parkingServiceName.split(' ').last,
                    occupied: zoneCounters[template.articleId] ?? 0,
                    capacity: template.zoneCapacity!,
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
      return Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            color: AppColors.secondary,
          ),
          child: ShimmerPlaceholderTemplate(
            width: double.infinity,
            height: 60,
          ),
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
          color: AppColors.secondary,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Text("Nincsenek telített időpontok"),
        ),
      );
    }

    /// Segédfüggvény, a templates-ből meghatározza a zóna nevét ArticleId alapján
    String getZoneNameById(String articleName) {
      final template = ServiceTemplates.firstWhere(
        (t) => t.parkingServiceName.contains(articleName),
      );
      return template.parkingServiceName.split(' ').last;
    }

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          color: AppColors.secondary),
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
                  if (entry.value.isNotEmpty)
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
      return ShimmerPlaceholderTemplate(width: double.infinity, height: 155);
    }

    if (!loading && reservations == null) {
      return Center(child: Text('Nem találhatóak foglalások'));
    }

    /// Szűrés: csak az adott intervallumban érkező, távozó vagy mosást igénylő foglalások
    final List<ValidReservation> expectedReservations = [];

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

    for (ValidReservation reservation in reservations!) {
      final arriveDate = reservation.arriveDate;
      final leaveDate = reservation.leaveDate;

      // Csak azok a foglalások, amelyeknek arrive vagy leave date-je a jövőben, de még az intervallumon belül van
      final bool isArriveToday =
          arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);
      final bool isLeaveToday =
          leaveDate.isAfter(startTime) && leaveDate.isBefore(endTime);

      /// HA ma van a foglalás és még nem érkezett meg
      if ((isArriveToday &&
              (reservation.state == 0 || reservation.state == 3)) ||

          // HA ma van a távozás, de még nem ment el
          (isLeaveToday &&
              (reservation.state == 1 || reservation.state == 2))) {
        expectedReservations.add(reservation);
      }
    }

    // Rendezés: a korábbi dátum (arrive vagy leave) szerint
    expectedReservations.sort((a, b) {
      final aArrive = a.arriveDate;
      final aLeave = a.leaveDate;
      final bArrive = b.arriveDate;
      final bLeave = b.leaveDate;

      // Mindkét foglalásnál megnézzük a korábbi mai időpontot
      final aEarliest = getEarliestTime(aArrive, aLeave, startTime);
      final bEarliest = getEarliestTime(bArrive, bLeave, startTime);

      return aEarliest.compareTo(bEarliest);
    });

    // return Center(
    //   child: MyDataGrid(
    //     reservations: expectedReservations,
    //     onRightClick: (selectedReservation) =>
    //         rightClickDialog(selectedReservation),
    //     showName: true,
    //     showLicense: true,
    //     showArriveDate: true,
    //     showLeaveDate: true,
    //   ),
    // );

    // Widget visszaadása
    return ReservationList(
      maxHeight: maxHeight,
      listTitle: listTitle,
      emptyText: "Nem várható bejelentett ügyfél.",
      reservations: expectedReservations,
      columns: {
        'Név': 'Name',
        'Rendszám': 'LicensePlate',
        'Időpont': 'Time',
        'Típus': 'Type',
      },
      formatters: {
        'Time': (reservation) {
          final arriveDate = reservation.arriveDate;
          final leaveDate = reservation.leaveDate;
          final isArriveToday =
              arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);

          if (isArriveToday) {
            return DateFormat('HH:mm').format(arriveDate);
          } else {
            return DateFormat('HH:mm').format(leaveDate);
          }
        },
        'Type': (reservation) {
          final arriveDate = reservation.arriveDate;
          final isArriveToday =
              arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);

          if (isArriveToday) {
            return 'Érkezés';
          } else {
            return 'Távozás';
          }
        },
      },
    );
  }

  /// Itt válogatjuk ki a keresésnek megfelelő rendszámokat
  void applySearch() {
    if (reservations == null) return;

    final String query = searchController.text.toUpperCase();

    if (query.isEmpty) {
      setState(() {
        searchResults = null;
      });
      return;
    }

    final Set<String> seenPlates = {};
    final List<ValidReservation> results = [];

    for (var reservation in reservations!) {
      final licensePlate = reservation.licensePlate.toUpperCase();
      final matches = licensePlate.contains(query);

      if (matches && !seenPlates.contains(licensePlate)) {
        seenPlates.add(licensePlate);
        results.add(reservation);
      }
    }

    setState(() {
      searchResults = results.isEmpty ? null : results;
    });
  }

  Widget buildSearchResults() {
    if (searchResults == null || searchResults!.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.small),
      child: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            children: searchResults!.asMap().entries.map((entry) {
              final index = entry.key;
              final selectedReservation = entry.value;
              final licensePlate = selectedReservation.licensePlate;
              final state = selectedReservation.state;
              final stateName = getStateName(state);

              return Container(
                color: (selectedSearchIndex == index)
                    ? AppColors.secondary
                    : Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showReservationOptionsDialog(
                      context,
                      selectedReservation,
                      onArrival: attemptRegisterArrival,
                      onLeave: attemptRegisterLeave,
                      onChangeLicense: attemptChangeLicensePlate,
                    );
                    searchController.clear();
                    //searchFocus.unfocus();
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppPadding.small),
                              child: const Icon(Icons.directions_car,
                                  size: 16, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                licensePlate,
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppPadding.small),
                              child: Text(
                                stateName,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Divider csak ha nem az utolsó elem
                      if (index < searchResults!.length - 1)
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
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    fetchData();

    searchController.addListener(applySearch);
    keyboardFocus.requestFocus();

    // percenként frissítjük a foglalásokat
    refreshTimer = Timer.periodic(Duration(minutes: 5), (_) {
      if (!mounted) return;
      fetchData();
      if (!mounted) return;
      setState(() {
        now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (IsMobile!) {
      return mobileBuild();
    } else {
      return desktopBuild();
    }
  }

  Widget desktopBuild() {
    return RefreshIndicator(
      key: refreshIndicatorKey,
      color: AppColors.primary,
      onRefresh: () async => fetchData(),
      child: KeyboardListener(
        focusNode: keyboardFocus,
        onKeyEvent: (event) async {
          if (event is! KeyDownEvent) return;

          // F5 -> frissítés
          if (event.logicalKey == LogicalKeyboardKey.f5) {
            refreshIndicatorKey.currentState?.show();
            return;
          }

          // Csak akkor, ha van találat
          if (searchResults != null && searchResults!.isNotEmpty) {
            // LE nyíl
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() {
                if (selectedSearchIndex == null) {
                  selectedSearchIndex = 0;
                } else {
                  selectedSearchIndex =
                      (selectedSearchIndex! + 1) % searchResults!.length;
                }
              });
              return;
            }

            // FEL nyíl
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() {
                if (selectedSearchIndex == null) {
                  selectedSearchIndex = searchResults!.length - 1;
                } else {
                  selectedSearchIndex =
                      (selectedSearchIndex! - 1 + searchResults!.length) %
                          searchResults!.length;
                }
              });
              return;
            }

            // ENTER -> kiválasztott megnyitása
            if (event.logicalKey == LogicalKeyboardKey.enter &&
                selectedSearchIndex != null) {
              final selectedReservation = searchResults![selectedSearchIndex!];
              await showReservationOptionsDialog(
                context,
                selectedReservation,
                onArrival: attemptRegisterArrival,
                onLeave: attemptRegisterLeave,
                onChangeLicense: attemptChangeLicensePlate,
              );
              setState(() {
                searchController.clear();
                selectedSearchIndex = null;
              });
              return;
            }
          }
        },
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: AppPadding.medium),
                child: SideMenu(
                  currentTitle: "Menü",
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding:
                                    EdgeInsets.only(bottom: AppPadding.small),
                                child: newReservationButton(),
                              ),
                              Flexible(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      bottom: AppPadding.medium),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.medium),
                                        color: AppColors.secondary),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          constraints:
                                              BoxConstraints(maxHeight: 300),
                                          child: buildTodoList(
                                              listTitle: 'Ma',
                                              reservations: reservations,
                                              startTime: now,
                                              endTime: DateTime(now.year,
                                                      now.month, now.day)
                                                  .add(
                                                      const Duration(days: 1))),
                                        ),
                                        // Container(
                                        //   constraints:
                                        //       BoxConstraints(maxHeight: 200),
                                        //   child: buildTodoList(
                                        //       listTitle: 'Holnap',
                                        //       reservations: reservations,
                                        //       startTime: DateTime(
                                        //               now.year, now.month, now.day)
                                        //           .add(const Duration(days: 1)),
                                        //       endTime: DateTime(
                                        //               now.year, now.month, now.day)
                                        //           .add(const Duration(days: 2))),
                                        // ),
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

                  // Search bar a középső oszlop tetején
                  Positioned(
                    top: AppPadding.medium,
                    left: AppPadding.medium,
                    child: SearchBarContainer(
                      searchContainerKey: searchContainerKey,
                      transparency: searchController.value.text.isNotEmpty,
                      children: [
                        MySearchBar(
                          searchController: searchController,
                          searchFocus: searchFocus,
                        ),
                        buildSearchResults(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(AppPadding.medium),
                child: Column(
                  children: [
                    buildZoneOccupancyIndicators(
                      zoneCounters: zoneCounters,
                      parkingServiceType: 1,
                    ),
                    SizedBox(height: AppPadding.medium),
                    Flexible(
                      child: buildFullyBookedTimeList(
                          fullyBookedDateTimes: fullyBookedDateTimes),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
                    zoneCounters: zoneCounters, parkingServiceType: 1),
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
