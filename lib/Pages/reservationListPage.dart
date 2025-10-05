// import 'dart:async';

// import 'package:airport_test/Pages/reservationForm/reservationOptionPage.dart';
// import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
// import 'package:airport_test/api_services/api_service.dart';
// import 'package:airport_test/constants/widgets/base_page.dart';
// import 'package:airport_test/constants/widgets/my_icon_button.dart';
// import 'package:airport_test/constants/widgets/reservation_list.dart';
// import 'package:airport_test/constants/widgets/shimmer_placeholder_template.dart';
// import 'package:airport_test/constants/theme.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class ReservationListPage extends StatefulWidget with PageWithTitle {
//   @override
//   String get pageTitle => 'Foglalások';

//   @override
//   bool get haveMargins => false;

//   const ReservationListPage({super.key});

//   @override
//   State<ReservationListPage> createState() => _ReservationListPageState();
// }

// class _ReservationListPageState extends State<ReservationListPage> {
//   final SearchController searchController = SearchController();
//   final GlobalKey searchContainerKey = GlobalKey();

//   FocusNode searchFocus = FocusNode();

//   Timer? refreshTimer;
//   late DateTime now = DateTime.now();

//   List<ValidReservation>? reservations;
//   List<ValidReservation>? filteredReservations;
//   ValidReservation? selectedReservation;

//   bool showFilters = false;

//   /// True -> Lekérdezések még folyamatban vannak
//   bool loading = true;

//   /// Kereséi szűrők, a bekapcsolt oszlopokban kereshetünk
//   final Map<String, bool> searchOptions = {
//     'Név': true,
//     'Rendszám': true,
//     'Telefonszám': false,
//     'Email-cím': false,
//     'Parkoló zóna': false,
//     'Érkezés dátuma': false,
//     'Távozás dátuma': false,
//     'Mosás dátuma': false
//   };

//   /// Foglalások és szolgáltatások lekérdezése
//   Future<void> fetchData() async {
//     final api = ApiService();
//     // Foglalások lekérdezése
//     final List<ValidReservation>? reservationsData =
//         await api.getValidReservations(context);
//     //await api.getReservations(context, ReceptionistToken);

//     if (reservationsData != null) {
//       setState(() {
//         reservations = reservationsData;
//         loading = false;
//       });
//     }
//   }

//   void applySearchFilter() {
//     if (reservations == null) return;

//     final String query = searchController.text.toLowerCase();

//     if (query.isEmpty) {
//       setState(() {
//         filteredReservations = null;
//       });
//       return;
//     }

//     setState(() {
//       filteredReservations = reservations!.where((reservation) {
//         bool matches = false;

//         // Név alapján keresés
//         if (searchOptions['Név'] == true) {
//           final name = reservation.articleNameHUN.toLowerCase();
//           matches = matches || name.contains(query);
//         }

//         // Rendszám alapján keresés
//         if (searchOptions['Rendszám'] == true && !matches) {
//           final licensePlate = reservation.licensePlate.toLowerCase();
//           matches = matches || licensePlate.contains(query);
//         }

//         // // Telefonszám alapján keresés
//         // if (searchOptions['Telefonszám'] == true && !matches) {
//         //   final phone = reservation.phone.toLowerCase();
//         //   matches = matches || phone.contains(query);
//         // }

//         // // Email alapján keresés
//         // if (searchOptions['Email-cím'] == true && !matches) {
//         //   final email = reservation.email.toLowerCase();
//         //   matches = matches || email.contains(query);
//         // }

//         // Parkoló zóna alapján keresés
//         if (searchOptions['Parkoló zóna'] == true && !matches) {
//           final parkingZone = reservation.articleNameHUN.toLowerCase();
//           matches = matches || parkingZone.contains(query);
//         }

//         // Érkezés dátuma alapján keresés
//         if (searchOptions['Érkezés dátuma'] == true && !matches) {
//           final arriveDate = reservation.arriveDate.toString();
//           final formattedDate =
//               DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(arriveDate));
//           matches = matches || formattedDate.toLowerCase().contains(query);
//         }

//         // Távozás dátuma alapján keresés
//         if (searchOptions['Távozás dátuma'] == true && !matches) {
//           final leaveDate = reservation.leaveDate.toString();
//           final formattedDate =
//               DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(leaveDate));
//           matches = matches || formattedDate.toLowerCase().contains(query);
//         }

//         return matches;
//       }).toList();
//     });
//   }

//   @override
//   void initState() {
//     super.initState();

//     searchController.addListener(applySearchFilter);

//     searchFocus.addListener(() {
//       setState(() {
//         showFilters = false;
//       });
//     });

//     fetchData();

//     refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
//       fetchData();
//       setState(() {
//         now = DateTime.now();
//       });
//       print('Frissítve');
//     });
//   }

//   @override
//   void dispose() {
//     refreshTimer?.cancel();
//     searchController.removeListener(applySearchFilter);
//     searchController.dispose();
//     searchFocus.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return detectClicks(
//       Padding(
//         padding: EdgeInsets.symmetric(
//             horizontal: AppPadding.large, vertical: AppPadding.large),
//         child: Container(
//           color: AppColors.background,
//           child: Row(
//             children: [
//               Expanded(
//                 flex: 3,
//                 child: Stack(
//                   children: [
//                     Positioned.fill(
//                       child: buildReservationList(
//                         reservations: filteredReservations ?? reservations,
//                       ),
//                     ),
//                     Positioned(
//                       top: 3,
//                       left: AppPadding.medium,
//                       child: Container(
//                         key: searchContainerKey,
//                         decoration: BoxDecoration(
//                           border: Border.all(
//                             color: showFilters
//                                 ? AppColors.primary
//                                 : Colors.transparent,
//                           ),
//                           borderRadius:
//                               BorderRadius.circular(AppBorderRadius.large),
//                           color:
//                               showFilters ? Colors.white : Colors.transparent,
//                         ),
//                         padding: EdgeInsets.all(AppPadding.small),
//                         child: Column(
//                           children: [
//                             buildSearchBar(),
//                             buildSearchFilters(),
//                           ],
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       top: 10,
//                       right: AppPadding.medium,
//                       child: MyIconButton(
//                         icon: Icons.add_rounded,
//                         labelText: "Foglalás rögzítése",
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const BasePage(
//                                 child: ReservationOptionPage(),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (selectedReservation != null)
//                 Expanded(
//                   flex: 1,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: AppPadding.medium),
//                     child: ReservationInformation(
//                         reservation: selectedReservation!),
//                   ),
//                 )
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Figyeli mikor nyomunk a searchBar-on kívülre
//   Widget detectClicks(Widget child) {
//     return GestureDetector(
//       behavior: HitTestBehavior.translucent,
//       onTapDown: (details) {
//         if (showFilters) {
//           final renderBox = searchContainerKey.currentContext
//               ?.findRenderObject() as RenderBox?;
//           if (renderBox != null) {
//             final position = renderBox.localToGlobal(Offset.zero);
//             final rect = Rect.fromLTWH(
//               position.dx,
//               position.dy,
//               renderBox.size.width,
//               renderBox.size.height,
//             );

//             // ha NINCS benne a kattintás
//             if (!rect.contains(details.globalPosition)) {
//               setState(() {
//                 showFilters = false;
//               });
//             }
//           }
//         }
//       },
//       child: child,
//     );
//   }

//   /// Aktív / Jövőbeli foglalási listák
//   Widget buildReservationList({
//     required List<dynamic>? reservations,
//     double? maxHeight,
//   }) {
//     if (loading) {
//       return Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(AppBorderRadius.medium),
//           color: AppColors.secondary,
//         ),
//         child: ShimmerPlaceholderTemplate(
//             width: double.infinity, height: maxHeight ?? double.infinity),
//       );
//     }

//     if (reservations == null) {
//       return Center(child: Text('Nem találhatóak foglalások'));
//     }

//     reservations.sort((a, b) {
//       try {
//         final dateA = DateTime.parse(a['ArriveDate'] ?? '');
//         final dateB = DateTime.parse(b['ArriveDate'] ?? '');
//         return dateA.compareTo(dateB);
//       } catch (e) {
//         return 0;
//       }
//     });

//     return Container(
//       decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(AppBorderRadius.medium),
//           color: AppColors.secondary),
//       child: ReservationList(
//           selectedReservation: selectedReservation,
//           onRowTap: (reservation) {
//             setState(() {
//               selectedReservation = reservation;
//             });
//           },
//           maxHeight: maxHeight,
//           listTitle: '',
//           reservations: reservations,
//           columns: {
//             'Név': 'Name',
//             'Rendszám': 'LicensePlate',
//             'Érkezés dátuma': 'ArriveDate',
//             'Távozás dátuma': 'LeaveDate',
//             'Parkoló Zóna': 'ParkingArticleId',
//           },
//           formatters: {
//             'ArriveDate': (reservation) =>
//                 reservationDateFormatter(reservation['ArriveDate']),
//             'LeaveDate': (reservation) =>
//                 reservationDateFormatter(reservation['LeaveDate']),
//           }),
//     );
//   }

//   Widget ReservationInformation({required ValidReservation reservation}) {
//     String formatDate(DateTime? date) {
//       if (date == null) return '-';
//       return DateFormat('yyyy.MM.dd HH:mm').format(date);
//     }

//     Widget buildInfoTile(String title, String value) {
//       return Column(
//         children: [
//           ListTile(
//             title: Text(
//               title,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.text,
//               ),
//             ),
//             subtitle: Text(value, style: TextStyle(color: AppColors.text)),
//           ),
//           Divider(height: 1),
//         ],
//       );
//     }

//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.secondary,
//         borderRadius: BorderRadius.circular(AppBorderRadius.medium),
//       ),
//       padding: EdgeInsets.all(AppPadding.large),
//       width: double.infinity,
//       child: ListView(
//         children: [
//           buildInfoTile('Partner ID', reservation.partnerId),
//           buildInfoTile('Név', reservation.partner_Sortname),
//           buildInfoTile('Rendszám', reservation.licensePlate),
//           buildInfoTile('Parkoló zóna', reservation.articleNameHUN),
//           buildInfoTile('Érkezés dátuma', formatDate(reservation.arriveDate)),
//           buildInfoTile('Távozás dátuma', formatDate(reservation.leaveDate)),
//           buildInfoTile('Papír ID', reservation.webParkingPaperId),
//           buildInfoTile('Papír szám', reservation.webParkingPaperNumber),
//           buildInfoTile('Papír típus', reservation.webParkingPaperTypeName),
//           if (reservation.webParkingAdvancePaperId != null)
//             buildInfoTile(
//                 'Előfoglalás ID', reservation.webParkingAdvancePaperId ?? '-'),
//           if (reservation.webParkingAdvancePaperNumber != null)
//             buildInfoTile('Előfoglalás szám',
//                 reservation.webParkingAdvancePaperNumber ?? '-'),
//           if (reservation.webParkingAdvancePaperTypeName != null)
//             buildInfoTile('Előfoglalás típus',
//                 reservation.webParkingAdvancePaperTypeName ?? '-'),
//         ],
//       ),
//     );
//   }

//   /// Segédfüggvény, ha a dátum null, vagy '0001-01-01' -> nem volt kiválasztva dátum -> '-' jelenítünk meg
//   String reservationDateFormatter(dynamic value) {
//     if (value == null ||
//         value.toString().isEmpty ||
//         value.toString().startsWith('0001-01-01')) {
//       return '-';
//     }
//     try {
//       return DateFormat('yyyy.MM.dd HH:mm')
//           .format(DateTime.parse(value.toString()));
//     } catch (e) {
//       return value.toString();
//     }
//   }

//   /// Kereső, mellyel a foglalások között tudunk keresni
//   Widget buildSearchBar() {
//     /// Valamiért az általánosított nem jól setState-l
//     // return MySearchBar(
//     //   searchController: searchController,
//     //   trailingWidgets: Row(
//     //     mainAxisSize: MainAxisSize.min,
//     //     children: [
//     //       VerticalDivider(
//     //         color: BasePage.defaultColors.background,
//     //         width: 8,
//     //         thickness: 1,
//     //       ),
//     //       IconButton(
//     //         onPressed: () {
//     //           setState(() {
//     //             showFilters = !showFilters;
//     //           });
//     //         },
//     //         icon: Icon(
//     //           Icons.filter_list_rounded,
//     //           size: 20,
//     //           color: BasePage.defaultColors.background,
//     //         ),
//     //         constraints: BoxConstraints(),
//     //       ),
//     //     ],
//     //   ),
//     // );
//     return SizedBox(
//       width: 300,
//       height: 35,
//       child: Theme(
//         data: Theme.of(context).copyWith(
//           textSelectionTheme: TextSelectionThemeData(
//             cursorColor: AppColors.background,
//           ),
//         ),
//         child: SearchBar(
//           focusNode: searchFocus,
//           shadowColor: WidgetStateProperty.all(Colors.transparent),
//           surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
//           backgroundColor: WidgetStateProperty.all(AppColors.primary),
//           hintStyle: WidgetStateProperty.all<TextStyle>(
//             TextStyle(
//               color: AppColors.background.withAlpha(200),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           textStyle: WidgetStateProperty.all<TextStyle>(
//             TextStyle(
//               color: AppColors.background,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           controller: searchController,
//           hintText: 'Keresés...',
//           leading: Icon(
//             Icons.search,
//             size: 20,
//             color: AppColors.background,
//           ),
//           trailing: [
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 if (searchController.text.isNotEmpty)
//                   IconButton(
//                     icon: Icon(
//                       Icons.close,
//                       size: 20,
//                       color: AppColors.background,
//                     ),
//                     constraints: BoxConstraints(),
//                     onPressed: () {
//                       searchController.clear();
//                     },
//                   ),
//                 VerticalDivider(
//                   color: AppColors.background,
//                   width: 8,
//                   thickness: 1,
//                 ),
//                 IconButton(
//                   onPressed: () {
//                     setState(() {
//                       showFilters = !showFilters;
//                     });
//                   },
//                   icon: Icon(
//                     Icons.filter_list_rounded,
//                     size: 20,
//                     color: AppColors.background,
//                   ),
//                   constraints: BoxConstraints(),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   /// Szűrők a kereső alatt
//   Widget buildSearchFilters() {
//     if (!showFilters) return Container();

//     return Padding(
//       padding: const EdgeInsets.only(top: AppPadding.small),
//       child: SizedBox(
//         width: 300,
//         child: SingleChildScrollView(
//           child: Column(
//             children: searchOptions.entries.map((entry) {
//               return CheckboxListTile(
//                 title: Text(
//                   entry.key,
//                   style: TextStyle(
//                     color: AppColors.text,
//                     fontSize: 13,
//                   ),
//                 ),
//                 value: entry.value,
//                 onChanged: (value) {
//                   setState(() {
//                     searchOptions[entry.key] = value ?? false;
//                   });
//                   // Alkalmazd a szűrést azonnal az új beállításokkal
//                   applySearchFilter();
//                 },
//                 dense: true,
//                 activeColor: AppColors.primary,
//                 checkColor: AppColors.background,
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }
