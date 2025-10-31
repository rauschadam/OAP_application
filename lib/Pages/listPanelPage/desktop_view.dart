import 'package:airport_test/Pages/listPanelPage/listPanelPage.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/list_panel_grid.dart';
import 'package:airport_test/constants/widgets/shimmer_placeholder_template.dart';
import 'package:flutter/material.dart';
import 'package:airport_test/constants/widgets/search_bar.dart';

class DesktopView extends StatelessWidget {
  final ListPanelPageState listPanelPageState;
  final Function(dynamic) onRowSelected;

  const DesktopView({
    super.key,
    required this.onRowSelected,
    required this.listPanelPageState,
  });

  @override
  Widget build(BuildContext context) {
    return listPanelPageState.detectClicks(
      Padding(
        padding: EdgeInsets.symmetric(
            horizontal: AppPadding.small, vertical: AppPadding.large),
        child: Stack(
          children: [
            // 1. TARTALOM: A GRID (vagy a placeholder)
            Positioned.fill(
              top: 50,
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.small),
                child: listPanelPageState.loading
                    ? ShimmerPlaceholderTemplate(
                        width: double.infinity, height: double.infinity)
                    : ListPanelGrid(
                        key: listPanelPageState.gridKey,
                        rows: listPanelPageState.filteredData ??
                            listPanelPageState.listPanelData!,
                        listPanelFields:
                            listPanelPageState.listPanelFields ?? [],
                        onRowSelected: (row) {
                          onRowSelected(row);
                        },
                      ),
              ),
            ),

            // 2. Kereső és Gombok
            Positioned(
              top: 3,
              left: AppPadding.medium,
              right: AppPadding.medium,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1.
                  SearchBarContainer(
                    searchContainerKey: listPanelPageState.searchContainerKey,
                    transparency: listPanelPageState.showFilters,
                    children: [
                      listPanelPageState.buildSearchBar(),
                      listPanelPageState.buildSearchFilters(),
                    ],
                  ),

                  // 2. Másolás
                  listPanelPageState.copyGridButton(),

                  const Spacer(),

                  // 3. Műveleti gombok (jobb szél)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: listPanelPageState.buildActionButtons(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
