import 'dart:async';
import 'package:airport_test/api_services/api_classes/available_list_panel.dart';
import 'package:airport_test/api_services/api_classes/list_panel_field.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/generic_data_grid.dart';
import 'package:airport_test/constants/widgets/shimmer_placeholder_template.dart';
import 'package:airport_test/constants/widgets/side_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GenericListPanelPage extends StatefulWidget {
  final AvailableListPanel listPanel;

  const GenericListPanelPage({
    super.key,
    required this.listPanel,
  });

  @override
  State<GenericListPanelPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<GenericListPanelPage> {
  final SearchController searchController = SearchController();
  FocusNode keyboardFocus = FocusNode();

  /// A kereső és az azt körülvevő filterek kulcsa
  final GlobalKey searchContainerKey = GlobalKey();
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  FocusNode searchFocus = FocusNode();

  /// Frissítés timer
  Timer? refreshTimer;

  /// Lista Panel mezőinek adatai
  List<ListPanelField>? listPanelFields;

  /// Lekérdezett lista panel adatok
  List<dynamic>? listPanelData;

  /// Keresési opciók (mi alapján keresünk)
  final Map<String, bool> searchOptions = {};

  /// Kereséssel szűrt sorok
  List<dynamic>? filteredData;

  /// Kiválasztott adatsor
  dynamic selectedRow;

  /// Szűrők mutatása
  bool showFilters = false;

  /// True -> Lekérdezések még folyamatban vannak
  bool loading = true;

  /// Adatok lekérdezése
  Future<void> fetchData() async {
    final api = ApiService();
    final List<ListPanelField>? fieldsData = await api.fetchListPanelFields(
      context: context,
      listPanelId: widget.listPanel.disrtibutedId,
      errorDialogTitle: "Lista Panel Mezők lekérdezése sikertelen!",
    );

    final List<dynamic>? panelData = await api.fetchListPanelData(
      context: context,
      listPanelId: widget.listPanel.disrtibutedId,
      errorDialogTitle: "Lista panel adatok lekérése sikertelen!",
    );

    if (panelData != null && fieldsData != null) {
      // SearchOptions automatikus feltöltése a látható mezőkből
      final generatedSearchOptions = {
        for (var f in fieldsData.where((f) => f.fieldVisible))
          f.fieldCaption ?? f.listFieldName: false,
      };

      setState(() {
        listPanelData = panelData;
        listPanelFields = fieldsData;
        searchOptions
          ..clear()
          ..addAll(generatedSearchOptions);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  void applySearchFilter() {
    if (listPanelData == null || listPanelFields == null) return;

    final String query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        filteredData = null;
      });
      return;
    }

    setState(() {
      filteredData = listPanelData!.where((row) {
        bool matches = false;

        for (final field in listPanelFields!) {
          // Csak azokban a mezőkben keresünk, ahol a user engedélyezte
          if (searchOptions[field.listFieldName] == true) {
            final value = row[field.listFieldName];

            if (value != null) {
              final valueString = value.toString().toLowerCase();
              if (valueString.contains(query)) {
                matches = true;
                break; // ha már talált egyezést, nem kell tovább keresni
              }
            }
          }
        }

        return matches;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();

    searchController.addListener(applySearchFilter);
    keyboardFocus.requestFocus();

    searchFocus.addListener(() {
      setState(() {
        showFilters = false;
      });
    });

    fetchData();

    refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
      fetchData();
      print('Frissítve');
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    searchController.removeListener(applySearchFilter);
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      pageTitle: widget.listPanel.listPanelName,
      drawer: SideDrawer(currentTitle: widget.listPanel.listPanelName),
      child: RefreshIndicator(
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
          },
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: loading
                    ? Center(child: CircularProgressIndicator())
                    : detectClicks(
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppPadding.large,
                              vertical: AppPadding.large),
                          child: Container(
                            color: AppColors.background,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        top: 50,
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                              AppPadding.large),
                                          child: loading
                                              ? ShimmerPlaceholderTemplate(
                                                  width: double.infinity,
                                                  height: double.infinity)
                                              : GenericDataGrid(
                                                  rows: filteredData ??
                                                      listPanelData!,
                                                  listPanelFields:
                                                      listPanelFields ?? [],
                                                  onRowSelected: (row) {
                                                    setState(() {
                                                      selectedRow = row;
                                                    });
                                                  },
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 3,
                                        left: AppPadding.medium,
                                        child: Container(
                                          key: searchContainerKey,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: showFilters
                                                  ? AppColors.primary
                                                  : Colors.transparent,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                                AppBorderRadius.large),
                                            color: showFilters
                                                ? Colors.white
                                                : Colors.transparent,
                                          ),
                                          padding:
                                              EdgeInsets.all(AppPadding.small),
                                          child: Column(
                                            children: [
                                              buildSearchBar(),
                                              buildSearchFilters(),
                                            ],
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
                      ),
              ),
              Expanded(child: Container())
            ],
          ),
        ),
      ),
    );
  }

  /// Figyeli mikor nyomunk a searchBar-on kívülre
  Widget detectClicks(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        if (showFilters) {
          final renderBox = searchContainerKey.currentContext
              ?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final position = renderBox.localToGlobal(Offset.zero);
            final rect = Rect.fromLTWH(
              position.dx,
              position.dy,
              renderBox.size.width,
              renderBox.size.height,
            );

            // ha NINCS benne a kattintás
            if (!rect.contains(details.globalPosition)) {
              setState(() {
                showFilters = false;
              });
            }
          }
        }
      },
      child: child,
    );
  }

  /// Kereső, mellyel a foglalások között tudunk keresni
  Widget buildSearchBar() {
    return SizedBox(
      width: 300,
      height: 35,
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: AppColors.background,
          ),
        ),
        child: SearchBar(
          focusNode: searchFocus,
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          backgroundColor: WidgetStateProperty.all(AppColors.primary),
          hintStyle: WidgetStateProperty.all<TextStyle>(
            TextStyle(
              color: AppColors.background.withAlpha(200),
              fontWeight: FontWeight.w600,
            ),
          ),
          textStyle: WidgetStateProperty.all<TextStyle>(
            TextStyle(
              color: AppColors.background,
              fontWeight: FontWeight.w600,
            ),
          ),
          controller: searchController,
          hintText: 'Keresés...',
          leading: Icon(
            Icons.search,
            size: 20,
            color: AppColors.background,
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
                      color: AppColors.background,
                    ),
                    constraints: BoxConstraints(),
                    onPressed: () {
                      searchController.clear();
                    },
                  ),
                VerticalDivider(
                  color: AppColors.background,
                  width: 8,
                  thickness: 1,
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      showFilters = !showFilters;
                    });
                  },
                  icon: Icon(
                    Icons.filter_list_rounded,
                    size: 20,
                    color: AppColors.background,
                  ),
                  constraints: BoxConstraints(),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// Szűrők a kereső alatt
  Widget buildSearchFilters() {
    if (!showFilters) return Container();

    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.small),
      child: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            children: searchOptions.entries.map((entry) {
              return CheckboxListTile(
                title: Text(
                  entry.key,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                  ),
                ),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    searchOptions[entry.key] = value ?? false;
                  });
                  // Alkalmazd a szűrést azonnal az új beállításokkal
                  applySearchFilter();
                },
                dense: true,
                activeColor: AppColors.primary,
                checkColor: AppColors.background,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
