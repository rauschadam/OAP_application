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

              // 4. Mai teendők lista
              homePageState.buildTodoList(
                listTitle: 'Ma',
                reservations: homePageState.reservations,
                startTime: homePageState.now,
                endTime: DateTime(homePageState.now.year,
                        homePageState.now.month, homePageState.now.day)
                    .add(const Duration(days: 1)),
                maxHeight: 600.0,
              ),
              SizedBox(height: AppPadding.medium),

              // 5. Foglalás rögzítése gomb
              homePageState.newReservationButton(),
              SizedBox(height: AppPadding.medium),

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
