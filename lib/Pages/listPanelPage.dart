import 'dart:async';
import 'dart:convert';
import 'package:airport_test/api_services/api_classes/platform_setting.dart';
import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/api_classes/available_list_panel.dart';
import 'package:airport_test/constants/dialogs/reservation_options_dialog.dart';

import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/list_panel_grid.dart';
import 'package:airport_test/constants/widgets/shimmer_placeholder_template.dart';
import 'package:airport_test/constants/widgets/side_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // --- FOCUSNODEOK ---
  FocusNode keyboardFocus = FocusNode();
  FocusNode searchFocus = FocusNode();

  // --- KONTROLLEREK ---
  final SearchController searchController = SearchController();

  // --- KULCSOK ---
  /// A kereső és az azt körülvevő filterek kulcsa
  final GlobalKey searchContainerKey = GlobalKey();
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  /// Kulcs a ListPanelGrid eléréséhez az exportáláshoz / másoláshoz
  final GlobalKey<ListPanelGridState<dynamic>> gridKey =
      GlobalKey<ListPanelGridState<dynamic>>();

  /// A panel ID-jétől függő kulcs
  String get listPanelKey =>
      'list_panel_search_filters_${widget.listPanel.disrtibutedId}';

  // /// Frissítés timer
  // Timer? refreshTimer;

  /// Lista Panel mezőinek adatai
  List<PlatformSetting>? listPanelFields;

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

  /// Egyedi objectId-k a mezőkből
  final Set<int> availableObjectIds = {};

  /// Ellenőrzi, hogy van-e legalább egy aktív keresési filter
  bool get areAnyFiltersActive =>
      searchOptions.values.any((isActive) => isActive == true);

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

  /// A mentett keresési opciók betöltése
  Future<void> loadSearchOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedJson = prefs.getString(listPanelKey);

    if (savedJson != null) {
      try {
        final Map<String, dynamic> loadedMap =
            Map<String, dynamic>.from(jsonDecode(savedJson));

        // Csak a listPanelFields által ismert mezőket töltjük vissza
        final newSearchOptions = <String, bool>{};
        final currentKeys = searchOptions.keys.toSet();

        loadedMap.forEach((key, value) {
          if (currentKeys.contains(key) && value is bool) {
            newSearchOptions[key] = value;
          }
        });

        if (newSearchOptions.isNotEmpty) {
          setState(() {
            searchOptions
              ..clear()
              ..addAll(newSearchOptions);
          });
        }
        applySearchFilter();
      } catch (e) {
        debugPrint(
            'Hiba a keresési opciók betöltésekor (${widget.listPanel.disrtibutedId}): $e');
      }
    }
  }

  /// A jelenlegi keresési opciók mentése
  Future<void> saveSearchOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(searchOptions);
    await prefs.setString(listPanelKey, jsonString);
  }

  /// Adatok lekérdezése
  Future<void> fetchData() async {
    // Töröljük a régi ID-kat minden frissítéskor
    availableObjectIds.clear();

    final api = ApiService();
    final List<PlatformSetting>? fieldData = await api.fetchPlatformSettings(
      context: context,
      listPanelId: widget.listPanel.disrtibutedId,
      platformId: IsMobile ? 1 : 3,
      errorDialogTitle:
          "Lista Panel Platform Beállítások lekérdezése sikertelen!",
    );

    final List<dynamic>? panelData = await api.fetchListPanelData(
      context: context,
      listPanelId: widget.listPanel.disrtibutedId,
      errorDialogTitle: "Lista panel adatok lekérése sikertelen!",
    );

    if (panelData != null && fieldData != null) {
      // SearchOptions automatikus feltöltése a látható mezőkből
      final generatedSearchOptions = {
        for (var f in fieldData.where((f) => f.fieldVisible))
          f.listFieldName: false,
      };

      // Összegyűjtjük az egyedi, nem null objectId-kat
      for (var field in fieldData) {
        if (field.objectId != null) {
          availableObjectIds.add(field.objectId!);
        }
      }

      setState(() {
        listPanelData = panelData;
        listPanelFields = fieldData;
        searchOptions
          ..clear()
          ..addAll(generatedSearchOptions);
        loading = false;
      });

      // Betöltjük az elmentett opciókat és alkalmazzuk a szűrést
      await loadSearchOptions();
      applySearchFilter();
    } else {
      setState(() => loading = false);
    }
  }

  /// Keresési filterek alkalmazása
  void applySearchFilter() {
    if (listPanelData == null || listPanelFields == null) return;

    /// Keresett kifejezés
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

  // --- Műveleti gombok generálása ---
  List<Widget> _buildActionButtons() {
    List<Widget> buttons = [];

    // Csak akkor adjuk hozzá a gombokat, ha van kiválasztott sor
    if (selectedRow == null) {
      return [];
    }

    // --- 1200 ---
    if (availableObjectIds.contains(1200)) {
      buttons.add(
        IconButton(
          icon: Icon(Icons.car_rental_outlined, color: AppColors.primary),
          onPressed: () {
            // Ellenőrizzük, hogy a selectedRow tényleg Map-e
            if (selectedRow is Map<String, dynamic>) {
              try {
                // Megpróbáljuk létrehozni a ValidReservation objektumot a Map-ból
                final ValidReservation reservation = ValidReservation.fromJson(
                    selectedRow as Map<String, dynamic>);

                showReservationOptionsDialog(context, reservation,
                    onArrival: (licensePlate) =>
                        attemptRegisterArrival(licensePlate),
                    onLeave: (licensePlate) =>
                        attemptRegisterLeave(licensePlate),
                    onChangeLicense: (webParkingId, newLicensePlate) =>
                        attemptChangeLicensePlate(
                          webParkingId,
                          newLicensePlate,
                        ));
              } catch (e) {
                // Hibakezelés, ha a Map nem alakítható ValidReservation objektummá
                print("Hiba a ValidReservation létrehozásakor: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Hiba az adatok feldolgozásakor a művelethez.')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'A kiválasztott sor adatai nem megfelelő formátumúak.')),
              );
            }
          },
        ),
      );
    }

    return buttons;
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
  }

  @override
  void dispose() {
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
                                    padding:
                                        const EdgeInsets.all(AppPadding.large),
                                    child: loading
                                        ? ShimmerPlaceholderTemplate(
                                            width: double.infinity,
                                            height: double.infinity)
                                        : ListPanelGrid(
                                            key: gridKey,
                                            rows:
                                                filteredData ?? listPanelData!,
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
                                  right: AppPadding.medium,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
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
                                      copyGridButton(),
                                      // Térkitöltő, hogy a gombok jobbra kerüljenek
                                      const Spacer(),
                                      // Műveleti gombok
                                      // Betesszük őket egy Row-ba, ha több van
                                      Row(
                                        mainAxisSize: MainAxisSize
                                            .min, // Ne nyúljon el feleslegesen
                                        children: _buildActionButtons(),
                                      ),
                                    ],
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
          hintText:
              areAnyFiltersActive ? 'Keresés...' : 'Kapcsolj be filtereket',
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
    if (!showFilters || listPanelFields == null) return Container();

    // A keresési opciókat most már a listPanelFields listából generáljuk.
    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.small),
      child: SizedBox(
        width: 300,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Column(
              children: listPanelFields! // A mezőlistán iterálunk
                  .where((f) => f.fieldVisible)
                  .map((field) {
                // Megjelenítéshez a user-barát nevet használjuk
                final String displayName =
                    field.fieldCaption ?? field.listFieldName;
                final String listFieldName =
                    field.listFieldName; // A technikai kulcs

                // Lekérdezés a searchOptions-ből a listFieldName kulccsal
                final bool currentValue = searchOptions[listFieldName] ?? false;

                return CheckboxListTile(
                  title: Text(
                    displayName,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                    ),
                  ),
                  value: currentValue,
                  onChanged: (value) {
                    setState(() {
                      // Beállítás a listFieldName kulccsal
                      searchOptions[listFieldName] = value ?? false;
                    });
                    // Alkalmazd a szűrést azonnal az új beállításokkal
                    applySearchFilter();
                    saveSearchOptions();
                  },
                  dense: true,
                  activeColor: AppColors.primary,
                  checkColor: AppColors.background,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// Másolás gomb
  Widget copyGridButton() {
    if (loading || (filteredData ?? listPanelData)?.isEmpty == true) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(left: AppPadding.medium, top: 4),
      child: Tooltip(
        message: "Másolás vágólapra",
        child: IconButton(
          onPressed: () {
            gridKey.currentState?.copyDataToClipboard();
          },
          icon: const Icon(
            Icons.copy,
            color: AppColors.primary,
            size: 30,
          ),
        ),
      ),
    );
  }
}
