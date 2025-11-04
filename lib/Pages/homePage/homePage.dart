import 'dart:async';
import 'package:airport_test/Pages/homePage/desktop_view.dart';
import 'package:airport_test/Pages/homePage/mobile_view.dart';
import 'package:airport_test/Pages/reservationForm/reservationOptionPage.dart';
import 'package:airport_test/api_services/api_classes/reservation.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/api_classes/service_templates.dart';
import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
import 'package:airport_test/constants/dialogs/reservation_options_dialog.dart';
import 'package:airport_test/constants/functions/reservation_state.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_icon_button.dart';
import 'package:airport_test/constants/widgets/reservation_list.dart';
import 'package:airport_test/constants/widgets/shimmer_placeholder_template.dart';
import 'package:airport_test/constants/widgets/side_drawer.dart';
import 'package:airport_test/constants/widgets/zone_occupancy_indicator.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  // --- FOCUSNODE ---
  FocusNode searchFocus = FocusNode();
  FocusNode keyboardFocus = FocusNode();

  // --- KONTROLLEREK ---
  final SearchController searchController = SearchController();

  // --- KULCSOK ---
  final GlobalKey searchContainerKey = GlobalKey();
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Timer? refreshTimer;
  late DateTime now = DateTime.now();
  List<ValidReservation>? reservations;
  List<ValidReservation>? searchResults;
  int? selectedSearchIndex;
  Map<String, int> zoneCounters = {};
  bool loading = true;
  Map<String, List<DateTime>> fullyBookedDateTimes = {};

  /// Adatok lekérdezése
  Future<void> fetchData() async {
    if (!mounted) return;
    final api = ApiService();
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

  /// Érkezése rögzítése
  Future<void> attemptRegisterArrival(String licensePlate) async {
    final api = ApiService();
    await api.logCustomerArrival(context, licensePlate);
    fetchData();
  }

  /// Távozás rögzítése
  Future<void> attemptRegisterLeave(String licensePlate) async {
    final api = ApiService();
    await api.logCustomerLeave(context, licensePlate);
    fetchData();
  }

  /// Rendszám változtatása
  Future<void> attemptChangeLicensePlate(
      int webParkingId, String newLicensePlate) async {
    final api = ApiService();
    await api.changeLicensePlate(context, webParkingId, newLicensePlate);
    fetchData();
  }

  Map<String, int> mapCurrentOccupancyByZones(List<dynamic> reservations) {
    zoneCounters = {};
    for (ValidReservation reservation in reservations) {
      if (reservation.parkingArticleId == null) continue;
      final parkingArticleId = reservation.parkingArticleId;
      final bool isParking = (reservation.state == 1 || reservation.state == 2);
      if (isParking) {
        zoneCounters[parkingArticleId!] =
            (zoneCounters[parkingArticleId] ?? 0) + 1;
      }
    }
    return zoneCounters;
  }

  Map<String, List<DateTime>> mapBookedDateTimesByZones(
      List<dynamic> reservations) {
    final Map<String, int> zoneCapacities = {};
    for (ServiceTemplate template in ServiceTemplates) {
      if (template.parkingServiceType != 1) continue;
      final String articleId = template.articleId!;
      final int capacity = template.zoneCapacity!;
      zoneCapacities[articleId] = capacity;
    }

    Map<String, Map<DateTime, int>> counters = {};

    for (ValidReservation reservation in reservations) {
      if (reservation.parkingArticleId == null ||
          reservation.arriveDate == null ||
          reservation.leaveDate == null) {
        continue;
      }
      final parkingArticleId = reservation.parkingArticleId;
      final arrive = reservation.arriveDate;
      final leave = reservation.leaveDate;
      counters.putIfAbsent(parkingArticleId!, () => {});

      DateTime current = DateTime(
        arrive!.year,
        arrive.month,
        arrive.day,
        arrive.hour,
        arrive.minute - (arrive.minute % 30),
      );

      while (current.isBefore(leave!)) {
        counters[parkingArticleId]![current] =
            (counters[parkingArticleId]![current] ?? 0) + 1;
        current = current.add(const Duration(minutes: 30));
      }
    }

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

  List<List<DateTime>> groupConsecutiveTimeSlots(List<DateTime> timeSlots) {
    if (timeSlots.isEmpty) return [];
    timeSlots.sort((a, b) => a.compareTo(b));
    List<List<DateTime>> groups = [];
    List<DateTime> currentGroup = [timeSlots.first];

    for (int i = 1; i < timeSlots.length; i++) {
      final currentTime = timeSlots[i];
      final previousTime = timeSlots[i - 1];
      if (currentTime.difference(previousTime) == Duration(minutes: 30)) {
        currentGroup.add(currentTime);
      } else {
        groups.add(List.from(currentGroup));
        currentGroup = [currentTime];
      }
    }
    groups.add(currentGroup);
    return groups;
  }

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

  Widget detectClicks(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {},
      child: child,
    );
  }

  Widget buildRefreshIndicator(Widget child) {
    return RefreshIndicator(
      key: refreshIndicatorKey,
      color: AppColors.primary,
      onRefresh: () async => fetchData(),
      child: child,
    );
  }

  // Foglalás Teljes Részletek
  void showFullDetails(ValidReservation tappedReservation) {
    showReservationDetails(
      context,
      tappedReservation,
      detailFields: ReservationFieldSettings,
      onArrival: attemptRegisterArrival,
      onLeave: attemptRegisterLeave,
      onChangeLicense: attemptChangeLicensePlate,
    );
    // A kereső bezárása, ha a felhasználó a találatok közül választott
    if (searchController.text.isNotEmpty) {
      searchController.clear();
      selectedSearchIndex = null;
    }
  }

  void onKeyEventHandler(KeyEvent event) async {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.f5) {
      refreshIndicatorKey.currentState?.show();
      return;
    }

    if (searchResults != null && searchResults!.isNotEmpty) {
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
  }

  Widget buildZoneOccupancyIndicators({
    required Map<String, int> zoneCounters,
    required int parkingServiceType,
  }) {
    if (loading) {
      // ShimmerPlaceholderTemplate
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
        padding: const EdgeInsets.symmetric(vertical: AppPadding.large),
        child: Column(
          children: [
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

  Widget buildFullyBookedTimeList(
      {required Map<String, List<DateTime>> fullyBookedDateTimes}) {
    if (loading) {
      // ShimmerPlaceholderTemplate
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

    String getZoneNameById(String articleName) {
      try {
        final template = ServiceTemplates.firstWhere(
          (t) => t.parkingServiceName.contains(articleName),
        );
        return template.parkingServiceName.split(' ').last;
      } catch (e) {
        return "Ismeretlen zóna";
      }
    }

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          color: AppColors.secondary),
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
                          child: ExpansionTile(
                            title: Text(
                              getZoneNameById(entry.key),
                            ),
                            children: [
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

  Widget? buildTaskList({
    required List<dynamic>? reservations,
    DateTime? startTime,
    required DateTime endTime,
    required String listTitle,
    bool fullDateFormat = false,
    String? emptyText,
    double? maxHeight,
  }) {
    if (loading) {
      return ShimmerPlaceholderTemplate(width: double.infinity, height: 155);
    }

    if (!loading && reservations == null) {
      return Center(child: Text('Nem találhatóak foglalások'));
    }

    // 1. Foglalások időbeli rendezése
    reservations!.sort((a, b) {
      if (a.arriveDate == null && b.arriveDate == null) return 0;
      if (a.arriveDate == null) return 1;
      if (b.arriveDate == null) return -1;
      return a.arriveDate!.compareTo(b.arriveDate!);
    });

    final List<ValidReservation> expectedReservations = [];

    final Set<String> processedLicensePlates = {};

    DateTime getActionTime(ValidReservation reservation) {
      final bool isArrivalAction =
          (reservation.state == 0 || reservation.state == 3);
      return isArrivalAction ? reservation.arriveDate! : reservation.leaveDate!;
    }

    String getActionType(ValidReservation reservation) {
      final bool isArrivalAction =
          (reservation.state == 0 || reservation.state == 3);
      return isArrivalAction ? 'Érkezés' : 'Távozás';
    }

    // 2. Foglalások átnézése (Idő, státusz)
    for (ValidReservation reservation in reservations) {
      // --- Duplikáció ellenőrzése ---
      final String licensePlate = reservation.licensePlate;
      if (processedLicensePlates.contains(licensePlate)) {
        continue;
      }
      if (reservation.arriveDate == null || reservation.leaveDate == null) {
        continue;
      }

      final arriveDate = reservation.arriveDate;
      final leaveDate = reservation.leaveDate;

      // Ha startTime null, csak az endTime-ot nézzük
      final bool isArriveToday =
          (startTime == null || arriveDate!.isAfter(startTime)) &&
              arriveDate!.isBefore(endTime);
      final bool isLeaveToday =
          (startTime == null || leaveDate!.isAfter(startTime)) &&
              leaveDate!.isBefore(endTime);

      if (
          // Ma érkezik
          (isArriveToday &&
                  (reservation.state == 0 || reservation.state == 3)) ||
              // Ma távozik
              (isLeaveToday &&
                  (reservation.state == 1 || reservation.state == 2))) {
        expectedReservations.add(reservation);
        processedLicensePlates.add(licensePlate);
      }
    }

    expectedReservations.sort((a, b) {
      final aActionTime = getActionTime(a);
      final bActionTime = getActionTime(b);
      return aActionTime.compareTo(bActionTime);
    });

    if (expectedReservations.isEmpty && emptyText == null) {
      return null;
    }

    return ReservationList(
      maxHeight: maxHeight,
      listTitle: listTitle,
      emptyText: emptyText,
      reservations: expectedReservations,
      columns: {
        if (!IsMobile) 'Név': 'Name',
        'Rendszám': 'LicensePlate',
        'Időpont': 'Time',
        'Típus': 'Type',
      },
      formatters: {
        'Time': (reservation) {
          if (fullDateFormat) {
            return DateFormat('yyyy.MM.dd HH:mm')
                .format(getActionTime(reservation));
          }
          return DateFormat('HH:mm').format(getActionTime(reservation));
        },
        'Type': (reservation) {
          return getActionType(reservation);
        },
      },
      onRowTap: (ValidReservation tappedReservation) {
        showReservationOptionsDialog(
          context,
          tappedReservation,
          onArrival: attemptRegisterArrival,
          onLeave: attemptRegisterLeave,
          onChangeLicense: attemptChangeLicensePlate,
        );
      },
      // MÁSODLAGOS MŰVELET (Hosszú nyomás / Jobb klikk) -> Teljes részletek
      onRowLongPress: IsMobile ? showFullDetails : null,
      onRowSecondaryTap: IsMobile ? null : showFullDetails,
    );
  }

  Widget buildSearchResults() {
    if (searchResults == null || searchResults!.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.small),
      child: SizedBox(
        width: 250,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 250),
          child: SingleChildScrollView(
            child: Column(
              children: searchResults!.asMap().entries.map((entry) {
                final index = entry.key;
                final selectedReservation = entry.value;
                final licensePlate = selectedReservation.licensePlate;
                final state = selectedReservation.state;
                final stateName = getStateName(state!);

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
                    },
                    onLongPress: IsMobile
                        ? () => showFullDetails(selectedReservation)
                        : null,
                    onSecondaryTap: IsMobile
                        ? null
                        : () => showFullDetails(selectedReservation),
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
          ref.read(reservationProvider.notifier).resetState();
          Navigation(context: context, page: const ReservationOptionPage())
              .push();
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
    return BasePage(
      pageTitle: "Fő oldal",
      drawer: const SideDrawer(currentTitle: "Fő oldal"),
      child: loading
          ? Center(child: CircularProgressIndicator())
          : IsMobile
              ? MobileView(homePageState: this)
              : DesktopView(homePageState: this),
    );
  }
}
