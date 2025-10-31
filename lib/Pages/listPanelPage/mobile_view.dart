import 'package:airport_test/Pages/listPanelPage/listPanelPage.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/search_bar.dart';
import 'package:flutter/material.dart';

class MobileView extends StatelessWidget {
  final ListPanelPageState listPanelPageState;

  const MobileView({
    super.key,
    required this.listPanelPageState,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Kereső sáv
          SearchBarContainer(
            searchContainerKey: listPanelPageState.searchContainerKey,
            transparency: listPanelPageState.searchController.text.isNotEmpty ||
                listPanelPageState.showFilters,
            children: [
              listPanelPageState.detectClicks(
                listPanelPageState.buildSearchBar(),
              ),
              listPanelPageState.buildSearchFilters(),
            ],
          ),

          const SizedBox(height: AppPadding.small),

          // 2. Lista
          Expanded(
            child: listPanelPageState.buildMobileListView(),
          ),
        ],
      ),
    );
  }
}
