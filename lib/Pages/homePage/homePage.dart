import 'dart:async';
import 'package:airport_test/Pages/homePage/desktopView.dart';
import 'package:airport_test/Pages/homePage/mobileView.dart';
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
      final parkingArticleId = reservation.parkingArticleId;
      final bool isParking = (reservation.state == 1 || reservation.state == 2);
      if (isParking) {
        zoneCounters[parkingArticleId] =
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

      while (current.isBefore(leave)) {
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

    final List<ValidReservation> expectedReservations = [];

    DateTime getEarliestTime(
        DateTime arrive, DateTime leave, DateTime startTime) {
      final bool isArriveInFuture = arrive.isAfter(startTime);
      return isArriveInFuture ? arrive : leave;
    }

    for (ValidReservation reservation in reservations!) {
      final arriveDate = reservation.arriveDate;
      final leaveDate = reservation.leaveDate;

      final bool isArriveToday =
          arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);
      final bool isLeaveToday =
          leaveDate.isAfter(startTime) && leaveDate.isBefore(endTime);

      if ((isArriveToday &&
              (reservation.state == 0 || reservation.state == 3)) ||
          (isLeaveToday &&
              (reservation.state == 1 || reservation.state == 2))) {
        expectedReservations.add(reservation);
      }
    }

    expectedReservations.sort((a, b) {
      final aEarliest = getEarliestTime(a.arriveDate, a.leaveDate, startTime);
      final bEarliest = getEarliestTime(b.arriveDate, b.leaveDate, startTime);
      return aEarliest.compareTo(bEarliest);
    });

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        color: AppColors.secondary,
      ),
      child: ReservationList(
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
            final isArriveToday =
                arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);
            return DateFormat('HH:mm')
                .format(isArriveToday ? arriveDate : reservation.leaveDate);
          },
          'Type': (reservation) {
            final arriveDate = reservation.arriveDate;
            final isArriveToday =
                arriveDate.isAfter(startTime) && arriveDate.isBefore(endTime);
            return isArriveToday ? 'Érkezés' : 'Távozás';
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
      ),
    );
  }

  Widget buildSearchResults() {
    if (searchResults == null || searchResults!.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.small),
      child: SizedBox(
        width: 300,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 300),
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
