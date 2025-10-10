import 'dart:async';
import 'package:airport_test/Pages/reservationForm/reservationOptionPage.dart';
import 'package:airport_test/api_Services/api_service.dart';
import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
import 'package:airport_test/constants/functions/reservation_options_dialog.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_data_grid.dart';
import 'package:airport_test/constants/widgets/my_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ReservationListPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Foglalások';

  @override
  bool get haveMargins => false;

  const ReservationListPage({super.key});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  final SearchController searchController = SearchController();
  FocusNode keyboardFocus = FocusNode();

  /// A kereső és az azt körülvevő filterek kulcsa
  final GlobalKey searchContainerKey = GlobalKey();
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  FocusNode searchFocus = FocusNode();

  /// Frissítés timer
  Timer? refreshTimer;

  /// Érvényes foglalások
  List<ValidReservation>? reservations;

  /// Kereséssel szűrt foglalások
  List<ValidReservation>? filteredReservations;

  /// Kiválasztott foglalás
  ValidReservation? selectedReservation;

  /// Szűrők mutatása
  bool showFilters = false;

  /// True -> Lekérdezések még folyamatban vannak
  bool loading = true;

  /// Kereséi szűrők, a bekapcsolhatjuk, hogy melyik oszlopokban keresünk.
  final Map<String, bool> searchOptions = {
    'Név': true,
    'Rendszám': true,
    'Telefonszám': false,
    'Email-cím': false,
    'Parkoló zóna': false,
    'Érkezés dátuma': false,
    'Távozás dátuma': false,
    'Státusz': false,
    'Id': false,
  };

  /// Adatok lekérdezése
  Future<void> fetchData() async {
    final api = ApiService();
    final List<ValidReservation>? reservationsData =
        await api.getValidReservations(context);

    if (reservationsData != null) {
      setState(() {
        reservations = reservationsData;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  /// Ügyfél érkeztetése
  Future<void> attemptRegisterArrival(String licensePlate) async {
    final api = ApiService();
    await api.logCustomerArrival(context, licensePlate);
    fetchData();
  }

  /// Ügyfél távoztatása
  Future<void> attemptRegisterLeave(String licensePlate) async {
    final api = ApiService();
    await api.logCustomerLeave(context, licensePlate);
    fetchData();
  }

  /// Rendszám módosítása
  Future<void> attemptChangeLicensePlate(
      int webParkingId, String newLicensePlate) async {
    final api = ApiService();
    await api.changeLicensePlate(context, webParkingId, newLicensePlate);
    fetchData();
  }

  /// Keresés alkalmazása
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
          final name = reservation.partner_Sortname.toLowerCase();
          matches = matches || name.contains(query);
        }

        // Rendszám alapján keresés
        if (searchOptions['Rendszám'] == true && !matches) {
          final licensePlate = reservation.licensePlate.toLowerCase();
          matches = matches || licensePlate.contains(query);
        }

        // Telefonszám alapján keresés
        if (searchOptions['Telefonszám'] == true && !matches) {
          final phone = reservation.phone;
          matches = matches || phone.contains(query);
        }

        // Email alapján keresés
        if (searchOptions['Email-cím'] == true && !matches) {
          final email = reservation.email.toLowerCase();
          matches = matches || email.contains(query);
        }

        // Parkoló zóna alapján keresés
        if (searchOptions['Parkoló zóna'] == true && !matches) {
          final parkingZone = reservation.articleNameHUN.toLowerCase();
          matches = matches || parkingZone.contains(query);
        }

        // Státusz alapján keresés
        if (searchOptions['Státusz'] == true && !matches) {
          final parkingZone = reservation.state.toString().toLowerCase();
          matches = matches || parkingZone.contains(query);
        }

        // Id alapján keresés
        if (searchOptions['Id'] == true && !matches) {
          final parkingZone = reservation.webParkingId.toString().toLowerCase();
          matches = matches || parkingZone.contains(query);
        }

        // Érkezés dátuma alapján keresés
        if (searchOptions['Érkezés dátuma'] == true && !matches) {
          final arriveDate = reservation.arriveDate.toString();
          final formattedDate =
              DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(arriveDate));
          matches = matches || formattedDate.toLowerCase().contains(query);
        }

        // Távozás dátuma alapján keresés
        if (searchOptions['Távozás dátuma'] == true && !matches) {
          final leaveDate = reservation.leaveDate.toString();
          final formattedDate =
              DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(leaveDate));
          matches = matches || formattedDate.toLowerCase().contains(query);
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
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
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
        child: detectClicks(
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppPadding.large, vertical: AppPadding.large),
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
                            padding: const EdgeInsets.all(AppPadding.large),
                            child: MyDataGrid(
                              reservations:
                                  filteredReservations ?? reservations!,
                              onReservationSelected: (reservation) {
                                setState(() {
                                  selectedReservation = reservation;
                                });
                              },
                              onRightClick: (selectedReservation) =>
                                  showReservationOptionsDialog(
                                context,
                                selectedReservation,
                                onArrival: attemptRegisterArrival,
                                onLeave: attemptRegisterLeave,
                                onChangeLicense: attemptChangeLicensePlate,
                              ),
                              selectedReservation: selectedReservation,
                              showArriveDate: true,
                              showDescription: true,
                              showEmail: true,
                              showLeaveDate: true,
                              showLicense: true,
                              showName: true,
                              showPhone: true,
                              showState: true,
                              showZone: true,
                              showId: true,
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
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.large),
                              color: showFilters
                                  ? Colors.white
                                  : Colors.transparent,
                            ),
                            padding: EdgeInsets.all(AppPadding.small),
                            child: Column(
                              children: [
                                buildSearchBar(),
                                buildSearchFilters(),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: AppPadding.medium,
                          right: AppPadding.large,
                          child: MyIconButton(
                            icon: Icons.add_rounded,
                            labelText: "Foglalás rögzítése",
                            onPressed: () {
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
                ],
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
