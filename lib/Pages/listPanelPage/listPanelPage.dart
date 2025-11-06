import 'dart:async';
import 'dart:convert';
import 'package:airport_test/api_services/api_classes/platform_setting.dart';
import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/api_classes/available_list_panel.dart';
import 'package:airport_test/constants/dialogs/reservation_options_dialog.dart';
import 'package:airport_test/constants/dialogs/upload_to_balance_dialog.dart';
import 'package:airport_test/constants/formatters.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/Pages/listPanelPage/desktop_view.dart';
import 'package:airport_test/Pages/listPanelPage/mobile_view.dart';
import 'package:airport_test/constants/widgets/list_panel_grid.dart';
import 'package:airport_test/constants/widgets/side_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListPanelPage extends StatefulWidget {
  final AvailableListPanel listPanel;

  const ListPanelPage({
    super.key,
    required this.listPanel,
  });

  @override
  State<ListPanelPage> createState() => ListPanelPageState();
}

class ListPanelPageState extends State<ListPanelPage> {
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
  final Map<int, String> availableObjectIds = {};

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
          availableObjectIds[field.objectId!] = field.listFieldName;
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

  /// Műveleti gombok (Érkeztetés, kiléptetés stb.)
  List<Widget> buildActionButtons() {
    List<Widget> buttons = [];

    // Csak akkor adjuk hozzá a gombokat, ha van kiválasztott sor
    if (selectedRow == null) {
      return [];
    }

    // --- 1 ---
    if (availableObjectIds.containsKey(1) && !IsMobile) {
      buttons.add(
        IconButton(
          icon: Icon(Icons.receipt, color: AppColors.primary),
          onPressed: () {
            if (selectedRow is Map<String, dynamic>) {
              final String? fieldName = availableObjectIds[1];
              if (fieldName != null) {
                final String? partnerId = selectedRow![fieldName];
                if (partnerId != null) {
                  uploadToBalanceDialog(context, partnerId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'A partner azonosító mező ($fieldName) értéke hiányzik.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('A 1-es objektumhoz nincs hozzárendelt mező.')),
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

    // --- 1200 ---
    // Módosítva: Mobilon ezek a gombok a bottom sheet-en belül jelennek meg
    if (availableObjectIds.containsKey(1200) && !IsMobile) {
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

  /// A gyermek widget (DesktopView) hívja meg, ha új sort választottak ki
  void handleRowSelected(dynamic row) {
    setState(() {
      selectedRow = row;
    });
  }

  String formatCell(dynamic rawValue, PlatformSetting? field) {
    if (field == null) return rawValue?.toString() ?? '-';

    final String dataType = field.formatString ?? '';

    // 1. Logika a 'bool' típusra
    if (dataType.toLowerCase() == 'bool') {
      bool? boolValue;
      if (rawValue is bool) {
        boolValue = rawValue;
      } else if (rawValue is int) {
        boolValue = rawValue == 1; // Támogatja a 0/1 értékeket
      } else if (rawValue is String) {
        boolValue =
            rawValue.toLowerCase() == 'true'; // Támogatja a "true" stringet
      }
      // Feltételezzük, hogy a formatters.dart-ban létezik ez a függvény
      return listPanelBoolFormatter(boolValue);
    }

    // 2. Logika a 'dateTime' típusra
    if (dataType.toLowerCase() == 'datetime') {
      if (rawValue == null || rawValue is! String || rawValue.isEmpty) {
        return '-';
      }
      try {
        // A JSON-ból érkező ISO 8601 stringet DateTime objektummá alakítjuk
        final DateTime parsedDate = DateTime.parse(rawValue);
        // Feltételezzük, hogy a formatters.dart-ban létezik ez a függvény
        return listPanelDateFormatter(parsedDate);
      } catch (e) {
        debugPrint('Dátum formázási hiba: $rawValue -> $e');
        return rawValue; // Hiba esetén a nyers string
      }
    }

    // 3. Alapértelmezett eset (minden más típus)
    return rawValue?.toString() ?? '-';
  }

  void showMobileDetailsSheet(dynamic rowData) {
    if (listPanelFields == null || rowData is! Map<String, dynamic>) return;

    final visibleFields =
        listPanelFields!.where((f) => f.fieldVisible).toList();

    // --- Akció gombok logikája (ide áthozva) ---
    ValidReservation? reservation;
    if (availableObjectIds.containsKey(1200)) {
      try {
        reservation = ValidReservation.fromJson(rowData);
      } catch (e) {
        print("Hiba a ValidReservation létrehozásakor (mobil sheet): $e");
        reservation = null;
      }
    }

    String? partnerId;
    if (availableObjectIds.containsKey(1)) {
      partnerId = rowData['Partner_Id'];
    }

    final List<Widget> actionButtons = [];
    if (reservation != null) {
      // Rendszám módosítása gomb
      actionButtons.add(
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // Bezárja a bottom sheet-et
            showChangeLicensePlateDialog(
              context,
              reservation!,
              (webParkingId, newLicensePlate) => attemptChangeLicensePlate(
                webParkingId,
                newLicensePlate,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 40), // Teljes szélesség
          ),
          child: const Text('Rendszám módosítása'),
        ),
      );
      actionButtons.add(const SizedBox(height: 8)); // Térköz

      // Kiléptetés gomb
      if (reservation.state == 1 || reservation.state == 2) {
        actionButtons.add(
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              attemptRegisterLeave(reservation!.licensePlate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 40), // Teljes szélesség
            ),
            child: const Text('Kiléptetés'),
          ),
        );
        actionButtons.add(const SizedBox(height: 8)); // Térköz
      }

      // Érkeztetés gomb
      if (reservation.state == 0) {
        actionButtons.add(
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              attemptRegisterArrival(reservation!.licensePlate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 40), // Teljes szélesség
            ),
            child: const Text('Érkeztetés'),
          ),
        );
        actionButtons.add(const SizedBox(height: 8)); // Térköz
      }
    }

    if (availableObjectIds.containsKey(1)) {
      actionButtons.add(
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            uploadToBalanceDialog(context, partnerId!);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 40), // Teljes szélesség
          ),
          child: const Text('Egyenleg feltöltés'),
        ),
      );
      actionButtons.add(const SizedBox(height: 8)); // Térköz
    }
    // --- Akció gombok logikája VÉGE ---

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppBorderRadius.large)),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppPadding.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 100,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Fejléc
                // Text(
                //   "Rekord Részletei",
                //   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                //         color: AppColors.text,
                //         fontWeight: FontWeight.bold,
                //       ),
                // ),
                // Divider(height: AppPadding.large),
                // Görgethető tartalom
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: visibleFields.map((field) {
                        final rawValue = rowData[field.listFieldName];
                        final formattedValue = formatCell(rawValue, field);
                        final caption =
                            field.fieldCaption ?? field.listFieldName;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppPadding.small),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Címke
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "$caption:",
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Érték
                              Expanded(
                                flex: 3,
                                child: Text(
                                  formattedValue,
                                  style: TextStyle(color: AppColors.text),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Bezárás gomb
                SizedBox(height: AppPadding.medium),
                // --- Akció gombok ---
                if (actionButtons.isNotEmpty) ...actionButtons,
                SafeArea(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.medium),
                      ),
                    ),
                    child: Text("Bezárás"),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Telefonon grid helyett lista formában mutatjuk az adatokat
  Widget buildMobileListView() {
    final data = filteredData ?? listPanelData!;
    if (listPanelFields == null) return Container();

    // Keressük meg az első látható mezőt, ez lesz a címe a listának
    final PlatformSetting? firstVisibleField =
        listPanelFields?.firstWhere((f) => f.fieldVisible);

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final row = data[index];
        String titleText = "Adat ${index + 1}"; // Alapértelmezett cím

        if (firstVisibleField != null && row is Map<String, dynamic>) {
          final rawValue = row[firstVisibleField.listFieldName];
          titleText = formatCell(rawValue, firstVisibleField);
        }

        return Card(
          elevation: 2.0,
          margin: EdgeInsets.symmetric(
              horizontal: AppPadding.small, vertical: AppPadding.small / 2),
          child: ListTile(
            title: Text(
              titleText,
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
            ),
            trailing: Icon(Icons.chevron_right, color: AppColors.primary),
            onTap: () {
              setState(() {
                // Beállítjuk a kiválasztott sort, hogy a műveleti gombok megjelenhessenek
                selectedRow = row;
              });
              // Megnyitjuk a részletező Bottom Sheet-et
              showMobileDetailsSheet(row);
            },
          ),
        );
      },
    );
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
              : (IsMobile
                  // Ha mobil, a MobileView-t hívjuk
                  ? MobileView(listPanelPageState: this)
                  // Ha desktop, a DesktopView-t hívjuk
                  : DesktopView(
                      listPanelPageState: this,
                      onRowSelected: handleRowSelected,
                    )),
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
      width: IsMobile ? double.infinity : 300,
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
        width: IsMobile ? double.infinity : 300,
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
    if (IsMobile ||
        loading ||
        (filteredData ?? listPanelData)?.isEmpty == true) {
      return Container();
    }
    return Padding(
      padding:
          const EdgeInsets.only(left: AppPadding.medium, top: AppPadding.small),
      child: Tooltip(
        message: "Másolás vágólapra",
        child: IconButton(
          onPressed: () {
            gridKey.currentState?.copyDataToClipboard();
          },
          icon: const Icon(
            Icons.copy,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
