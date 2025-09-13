import 'dart:async';

import 'package:airport_test/Pages/reservationForm/reservationOptionPage.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/constant_widgets/my_icon_button.dart';
import 'package:airport_test/constants/constant_widgets/reservation_list.dart';
import 'package:airport_test/constants/constant_widgets/shimmer_placeholder_template.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationListPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Foglalások';

  @override
  bool get haveMargins => false;

  final String? authToken;
  const ReservationListPage({super.key, required this.authToken});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  final SearchController searchController = SearchController();

  /// Automatikusan frissítjük az adatokat 1 perecnként
  Timer? refreshTimer;

  /// Mostani idő (1 perceként frissül)
  late DateTime now = DateTime.now();

  /// Lekérdezett foglalások
  List<dynamic>? reservations;

  /// Keresés által szűrt foglalások
  List<dynamic>? filteredReservations;

  /// Kiválasztott foglalás
  dynamic selectedReservation;

  /// Lekérdezett szolgáltatások
  List<dynamic>? serviceTemplates;

  /// Keresési opciók
  final Map<String, bool> searchOptions = {
    'Név': true,
    'Rendszám': true,
    'Telefonszám': false,
    'Email-cím': false,
    'Érkezés dátuma': false,
    'Távozás dátuma': false,
  };

  /// Foglalások lekérdezése
  Future<void> fetchReservations() async {
    final api = ApiService();
    final data = await api.getReservations(widget.authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        reservations = data;
      });
      fetchServiceTemplates();
    }
  }

  /// Szolgáltatások lekérdezése
  Future<void> fetchServiceTemplates() async {
    final api = ApiService();
    final data = await api.getServiceTemplates(widget.authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        serviceTemplates = data;
      });
    }
  }

  /// Keresési szűrő alkalmazása
  void applySearchFilter() {
    if (reservations == null) return;

    final String query = searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredReservations = null;
      });
      return;
    }

    setState(() {
      filteredReservations = reservations!.where((reservation) {
        bool matches = false;

        // Név alapján keresés
        if (searchOptions['Név'] == true) {
          matches = matches ||
              (reservation['Name']?.toString().toLowerCase().contains(query) ==
                  true);
        }

        // Rendszám alapján keresés
        if (searchOptions['Rendszám'] == true) {
          matches = matches ||
              (reservation['LicensePlate']
                      ?.toString()
                      .toLowerCase()
                      .contains(query) ==
                  true);
        }

        // Érkezés dátuma alapján keresés
        if (searchOptions['Érkezés dátuma'] == true) {
          try {
            final arriveDate = DateFormat('yyyy.MM.dd HH:mm')
                .format(DateTime.parse(reservation['ArriveDate']));
            matches = matches || arriveDate.toLowerCase().contains(query);
          } catch (e) {
            // Dátum formázási hiba esetén hagyjuk figyelmen kívül
          }
        }

        // Távozás dátuma alapján keresés
        if (searchOptions['Távozás dátuma'] == true) {
          try {
            final leaveDate = DateFormat('yyyy.MM.dd HH:mm')
                .format(DateTime.parse(reservation['LeaveDate']));
            matches = matches || leaveDate.toLowerCase().contains(query);
          } catch (e) {
            // Dátum formázási hiba esetén hagyjuk figyelmen kívül
          }
        }

        return matches;
      }).toList();
    });
  }

  /// Keresési opciók megjelenítése dialógusban
  void showSearchOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                'Keresési beállítások',
                style: TextStyle(color: BasePage.defaultColors.text),
              ),
              backgroundColor: BasePage.defaultColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              content: SizedBox(
                width: 400,
                child: ListView(
                  shrinkWrap: true,
                  children: searchOptions.entries.map((entry) {
                    return CheckboxListTile(
                      title: Text(
                        entry.key,
                        style: TextStyle(color: BasePage.defaultColors.text),
                      ),
                      value: entry.value,
                      onChanged: (value) {
                        setStateDialog(() {
                          searchOptions[entry.key] = value ?? false;
                        });
                      },
                      activeColor: BasePage.defaultColors.primary,
                      checkColor: BasePage.defaultColors.background,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    applySearchFilter(); // újraszűrés a módosított beállításokkal
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(color: BasePage.defaultColors.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // Figyeljük a keresési mező változásait
    searchController.addListener(applySearchFilter);

    fetchReservations();

    // percenként frissítjük a foglalásokat
    refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
      fetchReservations();
      now = DateTime.now();
      print('Frissítve');
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    searchController.removeListener(applySearchFilter);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppPadding.xlarge, vertical: AppPadding.large),
      color: BasePage.defaultColors.background,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: buildReservationList(
                    reservations: filteredReservations ?? reservations,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: AppPadding.medium,
                  child: Row(
                    children: [
                      buildSearchBar(),
                      SizedBox(width: 10),
                      buildFilterButton(),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: AppPadding.medium,
                  child: MyIconButton(
                    icon: Icons.add_rounded,
                    labelText: "Foglalás rögzítése",
                    onPressed: () {
                      BasePage.defaultColors = AppColors.blue;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BasePage(
                            child: ReservationOptionPage(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          selectedReservation != null
              ? Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.medium),
                    child: ReservationInformation(
                        reservation: selectedReservation),
                  ),
                )
              : Container()
        ],
      ),
    );
  }

  /// Foglalások listája
  Widget buildReservationList({
    required List<dynamic>? reservations,
    double? maxHeight,
  }) {
    if (reservations == null) {
      return ShimmerPlaceholderTemplate(
          width: double.infinity, height: maxHeight ?? double.infinity);
    }

    // Kiszűrjük azokat a foglalásokat, amelyeknek az LeaveDate-je a múltban van. Tehát már nem lényeges
    final List<dynamic> upcomingReservations = [];

    for (var reservation in reservations) {
      final leaveDate = DateTime.parse(reservation['LeaveDate']);
      if (leaveDate.isAfter(now)) {
        upcomingReservations.add(reservation);
      }
    }

    // Rendezzük ArriveDate szerint.
    upcomingReservations.sort((a, b) => DateTime.parse(a['ArriveDate'])
        .compareTo(DateTime.parse(b['ArriveDate'])));

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          color: BasePage.defaultColors.secondary),
      child: ReservationList(
        selectedReservation: selectedReservation,
        onRowTap: (reservation) {
          setState(() {
            selectedReservation = reservation;
          });
        },
        maxHeight: maxHeight,
        listTitle: '',
        reservations: upcomingReservations,
        columns: {
          'Név': 'Name',
          'Rendszám': 'LicensePlate',
          'Érkezés dátuma': 'ArriveDate',
          'Távozás dátuma': 'LeaveDate'
        },
        formatters: {
          'ArriveDate': (reservation) => DateFormat('yyyy.MM.dd HH:mm')
              .format(DateTime.parse(reservation['ArriveDate'])),
          'LeaveDate': (reservation) => DateFormat('yyyy.MM.dd HH:mm')
              .format(DateTime.parse(reservation['LeaveDate'])),
        },
      ),
    );
  }

  /// Kiválasztott foglalás információi
  Widget ReservationInformation({required dynamic reservation}) {
    // Dátum formázó függvény
    String formatDate(String dateString) {
      try {
        final date = DateTime.parse(dateString);
        return DateFormat('yyyy.MM.dd HH:mm').format(date);
      } catch (e) {
        return dateString;
      }
    }

    // Speciális formázás bizonyos mezőkhöz
    String formatValue(String key, dynamic value) {
      if (value == null) return 'N/A';

      // Dátum mezők automatikus formázása
      if (key.toLowerCase().contains('date')) {
        return formatDate(value.toString());
      }

      // Lista típusú mezők formázása
      if (value is List) {
        if (value.isEmpty) return 'Nincsenek elemek';
        return value.map((item) => item.toString()).join(', ');
      }

      // Map típusú mezők formázása
      if (value is Map) {
        if (value.isEmpty) return 'Nincsenek elemek';
        return value.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', ');
      }

      return value.toString();
    }

    // Kulcsok formázása (névformázás)
    String formatKey(String key) {
      // Eltávolítjuk a speciális karaktereket és camelCase-t alakítunk szóközökké
      final formattedKey = key
          .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
          .trim();

      // Nagybetűvel kezdjük
      return formattedKey[0].toUpperCase() + formattedKey.substring(1);
    }

    return Container(
      decoration: BoxDecoration(
          color: BasePage.defaultColors.secondary,
          borderRadius: BorderRadius.circular(AppBorderRadius.large)),
      padding: EdgeInsets.all(AppPadding.large),
      width: double.infinity,
      child: ListView(
        children: [
          for (var entry in reservation.entries)
            Column(
              children: [
                ListTile(
                  title: Text(
                    formatKey(entry.key),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: BasePage.defaultColors.text),
                  ),
                  subtitle: Text(
                    formatValue(entry.key, entry.value),
                    style: TextStyle(color: BasePage.defaultColors.text),
                  ),
                ),
                Divider(height: 1),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return SizedBox(
      width: 300,
      height: 35,
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: BasePage.defaultColors.background,
          ),
        ),
        child: SearchBar(
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          backgroundColor:
              WidgetStateProperty.all(BasePage.defaultColors.primary),
          hintStyle: WidgetStateProperty.all<TextStyle>(
            TextStyle(
              color: BasePage.defaultColors.background.withAlpha(200),
              fontWeight: FontWeight.w600,
            ),
          ),
          textStyle: WidgetStateProperty.all<TextStyle>(
            TextStyle(
              color: BasePage.defaultColors.background,
              fontWeight: FontWeight.w600,
            ),
          ),
          controller: searchController,
          onChanged: (value) {
            // A szűrő automatikusan alkalmazódik a listener miatt
          },
          hintText: 'Keresés foglalások között...',
          leading: Icon(
            Icons.search,
            color: BasePage.defaultColors.background,
          ),
          trailing: [
            if (searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close,
                    size: 20, color: BasePage.defaultColors.background),
                onPressed: () {
                  searchController.clear();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Szűrő gomb
  Widget buildFilterButton() {
    return SizedBox(
      height: 35,
      child: ElevatedButton(
        onPressed: showSearchOptionsDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: BasePage.defaultColors.primary,
          foregroundColor: BasePage.defaultColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_list, size: 20),
            SizedBox(width: 4),
            Text('Szűrés'),
          ],
        ),
      ),
    );
  }
}
