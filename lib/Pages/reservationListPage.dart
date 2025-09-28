import 'dart:async';

import 'package:airport_test/Pages/reservationForm/reservationOptionPage.dart';
import 'package:airport_test/api_Services/api_service.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_icon_button.dart';
import 'package:airport_test/constants/widgets/reservation_list.dart';
import 'package:airport_test/constants/widgets/shimmer_placeholder_template.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
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
  final GlobalKey searchContainerKey = GlobalKey();

  FocusNode searchFocus = FocusNode();

  Timer? refreshTimer;
  late DateTime now = DateTime.now();

  List<dynamic>? reservations;
  List<dynamic>? filteredReservations;
  dynamic selectedReservation;
  List<dynamic>? serviceTemplates;

  bool showFilters = false;

  /// Kereséi szűrők, a bekapcsolt oszlopokban kereshetünk
  final Map<String, bool> searchOptions = {
    'Név': true,
    'Rendszám': true,
    'Telefonszám': false,
    'Email-cím': false,
    'Parkoló zóna': false,
    'Érkezés dátuma': false,
    'Távozás dátuma': false,
    'Mosás dátuma': false
  };

  /// Foglalások és szolgáltatások lekérdezése
  Future<void> fetchData() async {
    final api = ApiService();
    // Foglalások lekérdezése
    final reservationsData =
        await api.getReservations(context, receptionistToken);
    // Szolgáltatások lekérdezése
    final servicesData =
        await api.getServiceTemplates(context, receptionistToken);

    if (reservationsData != null && servicesData != null) {
      setState(() {
        reservations = reservationsData;
        serviceTemplates = servicesData;
      });
    }
  }

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
          final name = reservation['Name']?.toString().toLowerCase() ?? '';
          matches = matches || name.contains(query);
        }

        // Rendszám alapján keresés
        if (searchOptions['Rendszám'] == true && !matches) {
          final licensePlate =
              reservation['LicensePlate']?.toString().toLowerCase() ?? '';
          matches = matches || licensePlate.contains(query);
        }

        // Telefonszám alapján keresés
        if (searchOptions['Telefonszám'] == true && !matches) {
          final phone = reservation['Phone']?.toString().toLowerCase() ?? '';
          matches = matches || phone.contains(query);
        }

        // Email alapján keresés
        if (searchOptions['Email-cím'] == true && !matches) {
          final email = reservation['Email']?.toString().toLowerCase() ?? '';
          matches = matches || email.contains(query);
        }

        // Parkoló zóna alapján keresés
        if (searchOptions['Parkoló zóna'] == true && !matches) {
          final parkingZone =
              getZoneNameById(reservation['ParkingArticleId']).toLowerCase();
          matches = matches || parkingZone.contains(query);
        }

        // Érkezés dátuma alapján keresés
        if (searchOptions['Érkezés dátuma'] == true && !matches) {
          try {
            final arriveDate = reservation['ArriveDate']?.toString() ?? '';
            if (arriveDate.isNotEmpty && !arriveDate.startsWith('0001-01-01')) {
              final formattedDate = DateFormat('yyyy.MM.dd HH:mm')
                  .format(DateTime.parse(arriveDate));
              matches = matches || formattedDate.toLowerCase().contains(query);
            }
          } catch (e) {
            // Dátum formázási hiba esetén hagyjuk figyelmen kívül
          }
        }

        // Távozás dátuma alapján keresés
        if (searchOptions['Távozás dátuma'] == true && !matches) {
          try {
            final leaveDate = reservation['LeaveDate']?.toString() ?? '';
            if (leaveDate.isNotEmpty && !leaveDate.startsWith('0001-01-01')) {
              final formattedDate = DateFormat('yyyy.MM.dd HH:mm')
                  .format(DateTime.parse(leaveDate));
              matches = matches || formattedDate.toLowerCase().contains(query);
            }
          } catch (e) {
            // Dátum formázási hiba esetén hagyjuk figyelmen kívül
          }
        }

        // Mosás dátuma alapján keresés
        if (searchOptions['Mosás dátuma'] == true && !matches) {
          try {
            final carWashDate = reservation['WashDateTime']?.toString() ?? '';
            if (carWashDate.isNotEmpty &&
                !carWashDate.startsWith('0001-01-01')) {
              final formattedDate = DateFormat('yyyy.MM.dd HH:mm')
                  .format(DateTime.parse(carWashDate));
              matches = matches || formattedDate.toLowerCase().contains(query);
            }
          } catch (e) {
            // Dátum formázási hiba esetén hagyjuk figyelmen kívül
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

    searchFocus.addListener(() {
      setState(() {
        showFilters = false;
      });
    });

    fetchData();

    refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
      fetchData();
      setState(() {
        now = DateTime.now();
      });
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
    return detectClicks(
      Padding(
        padding: EdgeInsets.symmetric(
            horizontal: AppPadding.xlarge, vertical: AppPadding.large),
        child: Container(
          color: AppColors.background,
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
                          color:
                              showFilters ? Colors.white : Colors.transparent,
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
                      top: 10,
                      right: AppPadding.medium,
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
              if (selectedReservation != null)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.medium),
                    child: ReservationInformation(
                        reservation: selectedReservation),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

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

  Widget buildReservationList({
    required List<dynamic>? reservations,
    double? maxHeight,
  }) {
    if (reservations == null) {
      return ShimmerPlaceholderTemplate(
          width: double.infinity, height: maxHeight ?? double.infinity);
    }

    final List<dynamic> upcomingReservations =
        reservations.where((reservation) {
      try {
        final leaveDate = DateTime.parse(reservation['LeaveDate'] ?? '');
        return leaveDate.isAfter(now);
      } catch (e) {
        return false;
      }
    }).toList();

    upcomingReservations.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['ArriveDate'] ?? '');
        final dateB = DateTime.parse(b['ArriveDate'] ?? '');
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          color: AppColors.secondary),
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
            'Távozás dátuma': 'LeaveDate',
            'Parkoló Zóna': 'ParkingArticleId',
            'Mosás dátuma': 'WashDateTime',
          },
          formatters: {
            'ArriveDate': (reservation) =>
                reservationDateFormatter(reservation['ArriveDate']),
            'LeaveDate': (reservation) =>
                reservationDateFormatter(reservation['LeaveDate']),
            'WashDateTime': (reservation) =>
                reservationDateFormatter(reservation['WashDateTime']),
            'ParkingArticleId': (reservation) =>
                getZoneNameById(reservation['ParkingArticleId'])
          }),
    );
  }

  String reservationDateFormatter(dynamic value) {
    if (value == null ||
        value.toString().isEmpty ||
        value.toString().startsWith('0001-01-01')) {
      return '-';
    }
    try {
      return DateFormat('yyyy.MM.dd HH:mm')
          .format(DateTime.parse(value.toString()));
    } catch (e) {
      return value.toString();
    }
  }

  String getZoneNameById(String articleId) {
    final template = serviceTemplates?.firstWhere(
      (t) => t['ArticleId'] == articleId,
      orElse: () => null,
    );
    return template != null
        ? template['ParkingServiceName'].split(' ').last
        : 'Egyéb';
  }

  Widget ReservationInformation({required dynamic reservation}) {
    String formatDate(String dateString) {
      try {
        final date = DateTime.parse(dateString);
        return DateFormat('yyyy.MM.dd HH:mm').format(date);
      } catch (e) {
        return dateString;
      }
    }

    String formatValue(String key, dynamic value) {
      if (value == null) return 'N/A';

      if (key.toLowerCase().contains('date')) {
        return formatDate(value.toString());
      }

      if (key == 'ParkingArticleId') {
        return getZoneNameById(value);
      }

      if (value is List) {
        return value.isEmpty ? 'Nincsenek elemek' : value.join(', ');
      }

      if (value is Map) {
        return value.isEmpty
            ? 'Nincsenek elemek'
            : value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      }

      return value.toString();
    }

    String formatKey(String key) {
      final formattedKey = key
          .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
          .trim();

      // TODO: Be van égetve a parking id -> parking zone kivétel
      // lehetne adatbázisban magyar nevük a mezőknek, nem kéne formázni őket.
      if (formattedKey == "Parking Article Id") return "Parking Zone";
      return formattedKey[0].toUpperCase() + formattedKey.substring(1);
    }

    return Container(
      decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(AppBorderRadius.medium)),
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
                        fontWeight: FontWeight.bold, color: AppColors.text),
                  ),
                  subtitle: Text(
                    formatValue(entry.key, entry.value),
                    style: TextStyle(color: AppColors.text),
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
    // return MySearchBar(
    //   searchController: searchController,
    //   trailingWidgets: Row(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       VerticalDivider(
    //         color: BasePage.defaultColors.background,
    //         width: 8,
    //         thickness: 1,
    //       ),
    //       IconButton(
    //         onPressed: () {
    //           setState(() {
    //             showFilters = !showFilters;
    //           });
    //         },
    //         icon: Icon(
    //           Icons.filter_list_rounded,
    //           size: 20,
    //           color: BasePage.defaultColors.background,
    //         ),
    //         constraints: BoxConstraints(),
    //       ),
    //     ],
    //   ),
    // );
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
