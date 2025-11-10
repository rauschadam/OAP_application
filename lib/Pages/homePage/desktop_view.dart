import 'package:airport_test/Pages/homePage/homePage.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/search_bar.dart';
import 'package:flutter/material.dart';

class DesktopView extends StatelessWidget {
  final HomePageState homePageState;

  const DesktopView({
    super.key,
    required this.homePageState,
  });

  @override
  Widget build(BuildContext context) {
    // --- Létrehozzuk a listákat ---
    final Widget? pastTaskList = homePageState.buildTaskList(
        listTitle: 'Múltbeli',
        reservations: homePageState.reservations,
        startTime: null,
        endTime: homePageState.now.subtract(const Duration(hours: 3)),
        maxHeight: 250.0,
        fullDateFormat: true);

    final Widget? todayTaskList = homePageState.buildTaskList(
      listTitle: 'Ma',
      emptyText: "Nincs hivatalos teendő",
      reservations: homePageState.reservations,
      startTime: homePageState.now.subtract(const Duration(hours: 3)),
      endTime: homePageState.now.add(const Duration(days: 1)),
      maxHeight: 350.0,
    );
    return homePageState.detectClicks(
      homePageState.buildRefreshIndicator(
        KeyboardListener(
          focusNode: homePageState.keyboardFocus,
          onKeyEvent: homePageState.onKeyEventHandler,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      child: Column(
                        // Fő oszlop
                        children: [
                          // Hely a keresőnek
                          SizedBox(height: 60),

                          // Ez a widget kitölti a rendelkezésre álló
                          // üres helyet, és lejjebb tolja a gombot és a listákat.
                          Spacer(),

                          // Gomb
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  top: AppPadding.small,
                                  bottom: AppPadding.medium),
                              child: homePageState.newReservationButton(),
                            ),
                          ),

                          // Listák
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // --- Múltbeli lista (feltételes) ---
                              if (pastTaskList != null)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                              0.3),
                                  child: pastTaskList,
                                ),
                              if (pastTaskList != null)
                                SizedBox(height: AppPadding.medium),

                              // --- Mai lista (mindig megjelenik) ---
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.4),
                                child: todayTaskList!,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search bar a középső oszlop tetején
                    Positioned(
                      top: AppPadding.medium,
                      left: AppPadding.medium,
                      child: SearchBarContainer(
                        searchContainerKey: homePageState.searchContainerKey,
                        transparency: homePageState
                            .searchController.value.text.isNotEmpty,
                        children: [
                          MySearchBar(
                            searchController: homePageState.searchController,
                            searchFocus: homePageState.searchFocus,
                          ),
                          homePageState.buildSearchResults(),
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
                      homePageState.buildZoneOccupancyIndicators(
                        zoneCounters: homePageState.zoneCounters,
                        parkingServiceType: 1,
                      ),
                      SizedBox(height: AppPadding.medium),
                      homePageState.buildZoneOccupancyIndicators(
                        zoneCounters: homePageState.zoneCounters,
                        parkingServiceType: 2,
                      ),
                      SizedBox(height: AppPadding.medium),
                      Flexible(
                        child: homePageState.buildFullyBookedTimeList(
                            fullyBookedDateTimes:
                                homePageState.fullyBookedDateTimes),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
