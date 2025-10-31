import 'package:airport_test/Pages/homePage/homePage.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/search_bar.dart';
import 'package:flutter/material.dart';

class DesktopView extends StatelessWidget {
  // Fogadjuk a szülő State osztályát, hogy elérjük az állapotot és a metódusokat
  final HomePageState homePageState;

  const DesktopView({
    super.key,
    required this.homePageState,
  });

  @override
  Widget build(BuildContext context) {
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
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: AppPadding.small,
                                      bottom: AppPadding.medium),
                                  child: homePageState.newReservationButton(),
                                ),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: 350.0),
                                  child: homePageState.buildTodoList(
                                    listTitle: 'Ma',
                                    reservations: homePageState.reservations,
                                    startTime: homePageState.now,
                                    endTime: DateTime(
                                            homePageState.now.year,
                                            homePageState.now.month,
                                            homePageState.now.day)
                                        .add(const Duration(days: 1)),
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
