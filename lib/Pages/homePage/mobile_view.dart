import 'package:airport_test/Pages/homePage/homePage.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/search_bar.dart';
import 'package:flutter/material.dart';

class MobileView extends StatelessWidget {
  // Fogadjuk a szülő State osztályát, hogy elérjük az állapotot és a metódusokat
  final HomePageState homePageState;

  const MobileView({
    super.key,
    required this.homePageState,
  });

  @override
  Widget build(BuildContext context) {
    // --- Létrehozzuk a listákat ---
    final Widget? pastTaskList = homePageState.buildTaskList(
      listTitle: 'Múlt',
      reservations: homePageState.reservations,
      endTime: homePageState.now.subtract(const Duration(hours: 3)),
    );

    final Widget? todayTaskList = homePageState.buildTaskList(
      listTitle: 'Ma',
      emptyText: "Nincs hivatalos teendő",
      reservations: homePageState.reservations,
      startTime: homePageState.now.subtract(const Duration(hours: 3)),
      endTime: homePageState.now.add(const Duration(days: 1)),
    );

    return homePageState.buildRefreshIndicator(
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Kereső sáv
              SearchBarContainer(
                searchContainerKey: homePageState.searchContainerKey,
                transparency: homePageState.searchController.text.isNotEmpty,
                children: [
                  homePageState.detectClicks(
                    MySearchBar(
                      searchController: homePageState.searchController,
                      searchFocus: homePageState.searchFocus,
                    ),
                  ),
                  homePageState.buildSearchResults(),
                ],
              ),
              SizedBox(height: AppPadding.medium),

              // 2. Telítettség jelzők (Parkolás)
              homePageState.buildZoneOccupancyIndicators(
                zoneCounters: homePageState.zoneCounters,
                parkingServiceType: 1,
              ),
              SizedBox(height: AppPadding.medium),

              // 3. Telítettség jelzők (Mosás)
              homePageState.buildZoneOccupancyIndicators(
                zoneCounters: homePageState.zoneCounters,
                parkingServiceType: 2,
              ),
              SizedBox(height: AppPadding.medium),

              // 4. Foglalás rögzítése gomb
              homePageState.newReservationButton(),
              SizedBox(height: AppPadding.medium),

              // 5. Mai teendők lista (mindig)
              SafeArea(
                bottom: pastTaskList == null,
                child: todayTaskList!, // Nem lesz null
              ),
              SizedBox(height: AppPadding.medium),

              // 6. Múltbeli teendők lista (feltételes)
              if (pastTaskList != null)
                SafeArea(
                  child: pastTaskList,
                ),

              // // 6. Telített időpontok lista
              // homePageState.buildFullyBookedTimeList(
              //     fullyBookedDateTimes: homePageState.fullyBookedDateTimes),
              // SizedBox(height: AppPadding.medium),
            ],
          ),
        ),
      ),
    );
  }
}
