// import 'package:airport_test/constantWidgets.dart';
// import 'package:airport_test/bookingForm/invoiceOptionPage.dart';
// import 'package:airport_test/bookingForm/washOrderPage.dart';
// import 'package:airport_test/enums/parkingFormEnums.dart';
// import 'package:airport_test/homePage.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:syncfusion_flutter_datepicker/datepicker.dart';

// class PerviewExample extends StatefulWidget {
//   const PerviewExample({
//     super.key,
//   });

//   @override
//   State<PerviewExample> createState() => PerviewExampleState();
// }

// class PerviewExampleState extends State<PerviewExample> {
//   final formKey = GlobalKey<FormState>();

//   late final TextEditingController nameController;
//   late final TextEditingController phoneController;
//   late final TextEditingController licensePlateController;
//   late final TextEditingController descriptionController;

//   FocusNode nameFocus = FocusNode();
//   FocusNode phoneFocus = FocusNode();
//   FocusNode licensePlateFocus = FocusNode();
//   FocusNode descriptionFocus = FocusNode();
//   FocusNode datePickerFocus = FocusNode();
//   FocusNode VIPFocus = FocusNode();
//   FocusNode suitcaseWrappingFocus = FocusNode();
//   FocusNode nextPageButtonFocus = FocusNode();
//   FocusNode transferFocus = FocusNode();

//   /// Aktuális idő
//   DateTime now = DateTime.now();

//   // Az enumok / kiválasztható lehetőségek default értékei
//   BookingOption selectedBookingOption = BookingOption.parking;
//   ParkingZoneOption selectedParkingZoneOption = ParkingZoneOption.eco;
//   PaymentOption selectedPaymentOption = PaymentOption.card;

//   /// Transzferrel szállított személyek száma
//   int transferCount = 1;

//   /// Kér-e VIP sofőrt
//   bool VIPDriverRequested = false;

//   /// Kér-e Bőrönd fóliázást
//   bool suitcaseWrappingRequested = false;

//   /// Fóliázásra váró bőröndök száma
//   int suitcasesToWrap = 0;

//   /// Érkezési / Távozási dátum
//   DateTime? selectedArriveDate, selectedLeaveDate;

//   /// Érkezés időpontja
//   TimeOfDay? selectedArriveTime;

//   /// Parkolással töltött napok száma
//   int parkingDays = 0;

//   /// A teljes fizetendő összeg
//   int totalCost = 0;

//   /// Teljes összeg kalkulálása, az árakat később adatbázisból fogja előhívni.
//   void CalculateTotalCost() {
//     int baseCost = 0;

//     switch (selectedParkingZoneOption) {
//       case ParkingZoneOption.eco:
//         baseCost = 2000 * parkingDays;
//         break;
//       case ParkingZoneOption.normal:
//         baseCost = 5000 * parkingDays;
//         break;
//       case ParkingZoneOption.premium:
//         baseCost = 10000 * parkingDays;
//         break;
//     }

//     if (VIPDriverRequested) {
//       baseCost += 5000;
//     }
//     baseCost += suitcasesToWrap * 1000;

//     setState(() {
//       totalCost = baseCost;
//     });
//   }

//   /// A DatePicker még le nem okézott, kiválasztott dátumai.
//   /// Ezeken nézi meg hogy megfelelnek-e a feltételeknek,
//   /// majd beállítja selectedArriveDate/selectedLeaveDate-nek
//   DateTime? tempArriveDate, tempLeaveDate;

//   //Teljes időpont pontos foglalt időpontok
//   List<DateTime> fullyBookedDateTimes = [
//     DateTime(2025, 8, 10, 8, 0),
//     DateTime(2025, 8, 15, 15, 30),
//     DateTime(2025, 9, 1, 18, 30),
//   ];

//   /// Azok a napok amelyek beleesnek a kiválasztott intervallumba,
//   /// de van benne olyan időpont, amikor már nincs hely az adott parkoló zónában.
//   List<DateTime> blackoutDays = [];

//   /// A parkolási napok számát frissíti.
//   void UpdateParkingDays() {
//     parkingDays = selectedLeaveDate!.difference(selectedArriveDate!).inDays;
//   }

//   /// A foglalt napokat frissíti.
//   void updateBlackoutDays() {
//     if (tempArriveDate == null || tempLeaveDate == null) {
//       blackoutDays = [];
//       return;
//     }

//     /// Az érkezési és távozási időpont
//     DateTime startDateTime = DateTime(
//       tempArriveDate!.year,
//       tempArriveDate!.month,
//       tempArriveDate!.day,
//       selectedArriveTime!.hour,
//       selectedArriveTime!.minute,
//     );

//     DateTime endDateTime = DateTime(
//       tempLeaveDate!.year,
//       tempLeaveDate!.month,
//       tempLeaveDate!.day,
//       selectedArriveTime!.hour,
//       selectedArriveTime!.minute,
//     );

//     /// Megnézi, hogy bele a foglalt időpontok beleesnek-e a foglalni kívánt intervallumba.
//     final filtered = fullyBookedDateTimes.where((d) {
//       return !d.isBefore(startDateTime) && !d.isAfter(endDateTime);
//     });

//     /// A blackoutDays csak a dátum (év, hónap, nap), időpont nélkül
//     blackoutDays =
//         filtered.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList();
//   }

//   /// Dátum kiíratásának a formátuma
//   String format(DateTime? d) => d != null
//       ? "${d.year}. ${d.month.toString().padLeft(2, '0')}. ${d.day.toString().padLeft(2, '0')}. "
//           "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}"
//       : '-';

//   /// Időpont választó dialógus a parkolási intervallum kiválasztásához.
//   void ShowDatePickerDialog() {
//     tempArriveDate = selectedArriveDate;
//     tempLeaveDate = selectedLeaveDate;

//     // Alapból frissítjük a blackoutDays-et a már beállított temp értékek alapján
//     updateBlackoutDays();

//     /// Megadja, hogy melyik időpontos Expansion Tile-ban hovereljük az időpontot.
//     Map<String, int> hoveredIndexMap = {
//       "Hajnal": -1,
//       "Reggel": -1,
//       "Nap": -1,
//       "Este": -1,
//       "Éjszaka": -1,
//     };

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             final allSlots = generateHalfHourTimeSlots();
//             final today = DateTime.now();
//             final currentTime = TimeOfDay.fromDateTime(today);

//             final availableSlots = allSlots.where((time) {
//               if (tempArriveDate != null &&
//                   tempArriveDate!.year == today.year &&
//                   tempArriveDate!.month == today.month &&
//                   tempArriveDate!.day == today.day) {
//                 if (time.hour < currentTime.hour ||
//                     (time.hour == currentTime.hour &&
//                         time.minute <= currentTime.minute)) {
//                   return false;
//                 }
//               }

//               bool isBooked = fullyBookedDateTimes.any((d) =>
//                   d.year == (tempArriveDate?.year ?? 0) &&
//                   d.month == (tempArriveDate?.month ?? 0) &&
//                   d.day == (tempArriveDate?.day ?? 0) &&
//                   d.hour == time.hour &&
//                   d.minute == time.minute);

//               return !isBooked;
//             }).toList();

//             /// Időpont választó kártyák widgetje
//             Widget buildTimeSlotPicker(List<TimeOfDay> slots) {
//               Map<String, List<TimeOfDay>> groupedSlots = {
//                 "Hajnal": [],
//                 "Reggel": [],
//                 "Nappal": [],
//                 "Este": [],
//                 "Éjszaka": [],
//               };

//               for (var time in slots) {
//                 if (time.hour < 6) {
//                   groupedSlots["Hajnal"]!.add(time);
//                 } else if (time.hour >= 6 && time.hour < 12) {
//                   groupedSlots["Reggel"]!.add(time);
//                 } else if (time.hour >= 12 && time.hour < 18) {
//                   groupedSlots["Nappal"]!.add(time);
//                 } else if (time.hour >= 18 && time.hour < 22) {
//                   groupedSlots["Este"]!.add(time);
//                 } else {
//                   groupedSlots["Éjszaka"]!.add(time);
//                 }
//               }

//               return Expanded(
//                 child: SingleChildScrollView(
//                   scrollDirection: Axis.vertical,
//                   child: Column(
//                     children: groupedSlots.entries
//                         .where((entry) => entry.value.isNotEmpty)
//                         .map((entry) {
//                       return Theme(
//                         data: Theme.of(context).copyWith(
//                           dividerColor: Colors.transparent,
//                           splashColor: Colors.transparent,
//                           highlightColor: Colors.transparent,
//                           hoverColor: Colors.transparent,
//                         ),
//                         child: ExpansionTile(
//                           iconColor: Colors.grey.shade700,
//                           title: Text(entry.key,
//                               style: TextStyle(
//                                 color: Colors.grey.shade700,
//                               )),
//                           initiallyExpanded: true,
//                           children: [
//                             GridView.builder(
//                               shrinkWrap: true,
//                               physics: const NeverScrollableScrollPhysics(),
//                               gridDelegate:
//                                   const SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: 4,
//                                 mainAxisSpacing: 8,
//                                 crossAxisSpacing: 8,
//                                 childAspectRatio: 3,
//                               ),
//                               itemCount: entry.value.length,
//                               itemBuilder: (context, index) {
//                                 final time = entry.value[index];
//                                 bool isSelected = selectedArriveTime == time;
//                                 bool isHovered =
//                                     hoveredIndexMap[entry.key] == index;

//                                 Color cardColor;
//                                 if (isSelected) {
//                                   cardColor = BasePage
//                                       .defaultColors.primary; //Colors.black;
//                                 } else if (isHovered) {
//                                   cardColor = Colors.grey.shade400;
//                                 } else {
//                                   cardColor = Colors.grey.shade300;
//                                 }

//                                 return MouseRegion(
//                                   onEnter: (_) {
//                                     setStateDialog(() {
//                                       hoveredIndexMap[entry.key] = index;
//                                     });
//                                   },
//                                   onExit: (_) {
//                                     setStateDialog(() {
//                                       hoveredIndexMap[entry.key] = -1;
//                                     });
//                                   },
//                                   cursor: SystemMouseCursors.click,
//                                   child: GestureDetector(
//                                     onTap: () {
//                                       setStateDialog(() {
//                                         selectedArriveTime = time;
//                                         if (selectedArriveTime != null) {
//                                           updateBlackoutDays();
//                                         }
//                                       });
//                                     },
//                                     child: Card(
//                                       elevation: 0,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(20),
//                                       ),
//                                       color: cardColor,
//                                       child: Center(
//                                         child: Text(
//                                           time.format(context),
//                                           style: TextStyle(
//                                             color: isSelected
//                                                 ? Colors.white
//                                                 : Colors.black,
//                                             fontWeight: isSelected
//                                                 ? FontWeight.bold
//                                                 : FontWeight.normal,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               );
//             }

//             return Dialog(
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20)),
//               child: Container(
//                 width: 600,
//                 height: 800,
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     SfDateRangePicker(
//                       initialSelectedRange:
//                           tempArriveDate != null && tempLeaveDate != null
//                               ? PickerDateRange(tempArriveDate, tempLeaveDate)
//                               : null,
//                       selectionMode: DateRangePickerSelectionMode.range,
//                       todayHighlightColor: BasePage.defaultColors.primary,
//                       startRangeSelectionColor: BasePage.defaultColors.primary,
//                       endRangeSelectionColor: BasePage.defaultColors.primary,
//                       rangeSelectionColor: BasePage.defaultColors.secondary,
//                       enablePastDates: false,
//                       maxDate: DateTime.now().add(const Duration(days: 120)),
//                       monthCellStyle: DateRangePickerMonthCellStyle(
//                         blackoutDateTextStyle: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         blackoutDatesDecoration: BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                           // border: Border.all(color: Colors.redAccent, width: 1),
//                           // borderRadius: BorderRadius.circular(32),
//                         ),
//                       ),
//                       monthViewSettings: DateRangePickerMonthViewSettings(
//                           blackoutDates: blackoutDays),
//                       selectableDayPredicate: (date) {
//                         return !blackoutDays.contains(
//                             DateTime(date.year, date.month, date.day));
//                       },
//                       onSelectionChanged: (args) {
//                         if (args.value is PickerDateRange) {
//                           final start = args.value.startDate;
//                           final end = args.value.endDate;

//                           setStateDialog(() {
//                             tempArriveDate = start;
//                             tempLeaveDate = end;
//                             if (selectedArriveTime != null) {
//                               updateBlackoutDays();
//                             }
//                           });

//                           if (selectedLeaveDate != null) {
//                             setState(() {
//                               UpdateParkingDays();
//                             });
//                           }
//                         }
//                       },
//                     ),
//                     buildTimeSlotPicker(availableSlots),
//                     const SizedBox(height: 10),
//                     (tempArriveDate != null &&
//                             tempLeaveDate != null &&
//                             selectedArriveTime != null)
//                         ? SizedBox(
//                             height: 50,
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               style: ButtonStyle(
//                                   backgroundColor: WidgetStateProperty.all(
//                                       BasePage
//                                           .defaultColors.primary //Colors.black
//                                       ),
//                                   foregroundColor: WidgetStateProperty.all(
//                                       BasePage.defaultColors.background
//                                       // BasePage.defaultColors.background
//                                       )),
//                               onPressed: () {
//                                 if (tempArriveDate != null &&
//                                     tempLeaveDate != null) {
//                                   final diff = tempLeaveDate!
//                                       .difference(tempArriveDate!)
//                                       .inDays;
//                                   if (diff < 1) {
//                                     ShowError(
//                                         "A választott tartománynak legalább 1 napnak kell lennie.");
//                                     return;
//                                   }
//                                   if (diff > 30) {
//                                     ShowError(
//                                         "A választott tartomány legfeljebb 30 nap lehet.");
//                                     return;
//                                   }

//                                   bool containsBlackout =
//                                       fullyBookedDateTimes.any((b) {
//                                     final bDate = DateTime(b.year, b.month,
//                                         b.day, b.hour, b.minute);
//                                     final startDateTime = DateTime(
//                                       tempArriveDate!.year,
//                                       tempArriveDate!.month,
//                                       tempArriveDate!.day,
//                                       selectedArriveTime!.hour,
//                                       selectedArriveTime!.minute,
//                                     );
//                                     final endDateTime = DateTime(
//                                       tempLeaveDate!.year,
//                                       tempLeaveDate!.month,
//                                       tempLeaveDate!.day,
//                                       selectedArriveTime!.hour,
//                                       selectedArriveTime!.minute,
//                                     );

//                                     return !bDate.isBefore(startDateTime) &&
//                                         !bDate.isAfter(endDateTime);
//                                   });

//                                   if (containsBlackout) {
//                                     ShowError(
//                                         "A kiválasztott tartomány tartalmaz foglalt napot!");
//                                     return;
//                                   }

//                                   final arriveDateTime = DateTime(
//                                     tempArriveDate!.year,
//                                     tempArriveDate!.month,
//                                     tempArriveDate!.day,
//                                     selectedArriveTime!.hour,
//                                     selectedArriveTime!.minute,
//                                   );

//                                   final leaveDateTime = DateTime(
//                                     tempLeaveDate!.year,
//                                     tempLeaveDate!.month,
//                                     tempLeaveDate!.day,
//                                     selectedArriveTime!.hour,
//                                     selectedArriveTime!.minute,
//                                   );

//                                   setState(() {
//                                     selectedArriveDate = arriveDateTime;
//                                     selectedLeaveDate = leaveDateTime;
//                                   });

//                                   Navigator.of(context).pop();
//                                 }
//                               },
//                               child: const Text("Időpont kiválasztása"),
//                             ),
//                           )
//                         : Container(),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   void ShowError(String msg) => showDialog(
//         context: context,
//         builder: (ctx) {
//           return AlertDialog(
//             title: const Text("Hiba"),
//             content: Text(msg),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(ctx).pop(),
//                 child: const Text("OK"),
//               ),
//             ],
//           );
//         },
//       );

//   void OnNextPageButtonPressed() async {
//     if (formKey.currentState!.validate()) {
//       Widget? nextPage;
//       // if (widget.bookingOption == BookingOption.parking) {
//       //   nextPage = InvoiceOptionPage(
//       //     authToken: widget.authToken,
//       //     nameController: nameController,
//       //     emailController: widget.emailController,
//       //     phoneController: phoneController,
//       //     licensePlateController: licensePlateController,
//       //     arriveDate: selectedArriveDate,
//       //     leaveDate: selectedLeaveDate,
//       //     transferPersonCount: transferCount,
//       //     vip: VIPDriverRequested,
//       //     descriptionController: descriptionController,
//       //     bookingOption: widget.bookingOption,
//       //   );
//       // } else if (widget.bookingOption == BookingOption.both) {
//       //   nextPage = WashOrderPage(
//       //     authToken: widget.authToken,
//       //     bookingOption: widget.bookingOption,
//       //     emailController: widget.emailController,
//       //     licensePlateController: licensePlateController,
//       //     nameController: nameController,
//       //     phoneController: phoneController,
//       //     descriptionController: descriptionController,
//       //     arriveDate: selectedArriveDate,
//       //     leaveDate: selectedLeaveDate,
//       //     transferPersonCount: transferCount,
//       //     vip: VIPDriverRequested,
//       //   );
//       // }
//       nextPage = HomePage();
//       if (selectedArriveDate != null && selectedLeaveDate != null) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => BasePage(
//               // title: widget.bookingOption == BookingOption.parking
//               //     ? "Számlázás"
//               //     : "Mosás foglalás",
//               title: "Menü",
//               child: nextPage!,
//             ),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Válassz ki Parkolási intervallumot!')),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Sikertelen Bejelentkezés!')),
//       );
//     } // ???
//   }

//   @override
//   void initState() {
//     super.initState();

//     // nameController = widget.nameController ?? TextEditingController();
//     // phoneController = widget.phoneController ?? TextEditingController();
//     // licensePlateController =
//     //     widget.licensePlateController ?? TextEditingController();
//     nameController = TextEditingController();
//     phoneController = TextEditingController();
//     licensePlateController = TextEditingController();
//     descriptionController = TextEditingController();

//     // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       FocusScope.of(context).requestFocus(nameFocus);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: formKey,
//       child: ScrollConfiguration(
//         behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               MyTextFormField(
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Adja meg felhasználó nevét';
//                   }
//                   return null;
//                 },
//                 controller: nameController,
//                 focusNode: nameFocus,
//                 textInputAction: TextInputAction.next,
//                 nextFocus: phoneFocus,
//                 hintText: 'Foglaló személy neve',
//               ),
//               const SizedBox(height: 10),
//               MyTextFormField(
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Adja meg telefonszámát';
//                   }
//                   return null;
//                 },
//                 controller: phoneController,
//                 focusNode: phoneFocus,
//                 textInputAction: TextInputAction.next,
//                 nextFocus: licensePlateFocus,
//                 hintText: 'Telefonszám',
//               ),
//               const SizedBox(height: 10),
//               MyTextFormField(
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Adja meg rendszámát';
//                   }
//                   return null;
//                 },
//                 controller: licensePlateController,
//                 focusNode: licensePlateFocus,
//                 textInputAction: TextInputAction.next,
//                 nextFocus: datePickerFocus,
//                 hintText: 'Várható rendszám',
//               ),
//               const SizedBox(height: 10),
//               Row(children: [
//                 MyIconButton(
//                   icon: Icons.calendar_month_rounded,
//                   labelText: "Válassz dátumot",
//                   focusNode: datePickerFocus,
//                   onPressed: () {
//                     ShowDatePickerDialog();
//                     CalculateTotalCost();
//                     FocusScope.of(context).requestFocus(transferFocus);
//                   },
//                 ),
//                 const SizedBox(width: 50),
//                 Column(
//                   children: [Text('Érkezés'), Text(format(selectedArriveDate))],
//                 ),
//                 const SizedBox(width: 50),
//                 Column(
//                   children: [Text('Távozás'), Text(format(selectedLeaveDate))],
//                 ),
//               ]),
//               const SizedBox(height: 8),
//               Text('Válassz parkoló zónát - $parkingDays napra',
//                   style: TextStyle(fontWeight: FontWeight.bold)),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(4.0),
//                     child: ParkingZoneSelectionCard(
//                       title: "Eco",
//                       subtitle: "Nyitott murvás",
//                       costPerDay: 2000,
//                       parkingDays: parkingDays,
//                       selected:
//                           selectedParkingZoneOption == ParkingZoneOption.eco,
//                       onTap: () {
//                         setState(() =>
//                             selectedParkingZoneOption = ParkingZoneOption.eco);
//                         CalculateTotalCost();
//                       },
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(4.0),
//                     child: ParkingZoneSelectionCard(
//                       title: "Normal",
//                       subtitle: "Nyitott térköves",
//                       costPerDay: 5000,
//                       parkingDays: parkingDays,
//                       selected:
//                           selectedParkingZoneOption == ParkingZoneOption.normal,
//                       onTap: () {
//                         setState(() => selectedParkingZoneOption =
//                             ParkingZoneOption.normal);
//                         CalculateTotalCost();
//                       },
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(4.0),
//                     child: ParkingZoneSelectionCard(
//                       title: "Premium",
//                       subtitle: "Fedett téköves",
//                       costPerDay: 10000,
//                       parkingDays: parkingDays,
//                       selected: selectedParkingZoneOption ==
//                           ParkingZoneOption.premium,
//                       onTap: () {
//                         setState(() => selectedParkingZoneOption =
//                             ParkingZoneOption.premium);
//                         CalculateTotalCost();
//                       },
//                     ),
//                   )
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   // MyCheckBox(
//                   //     value: transferRequested,
//                   //     focusNode: transferFocus,
//                   //     onChanged: (value) {
//                   //       setState(() {
//                   //         transferRequested = value;
//                   //       });
//                   //     }),
//                   Text('Transzferre váró személyek száma'),
//                   SizedBox(width: 15),
//                   IconButton.filled(
//                     onPressed: () {
//                       setState(() {
//                         if (transferCount > 0) {
//                           transferCount--;
//                         }
//                         CalculateTotalCost();
//                       });
//                     },
//                     icon: Icon(Icons.remove,
//                         color: transferCount > 0
//                             ? Colors.black
//                             : Colors.grey.shade400,
//                         size: 16),
//                     style: IconButton.styleFrom(
//                       backgroundColor: Colors.grey.shade300,
//                       hoverColor: transferCount > 0
//                           ? Colors.grey.shade400
//                           : Colors.grey.shade300,
//                       minimumSize: const Size(24, 24),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       padding: EdgeInsets.zero,
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Text('$transferCount',
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                   SizedBox(width: 8),
//                   IconButton.filled(
//                     onPressed: () {
//                       setState(() {
//                         if (transferCount < 7) {
//                           transferCount++;
//                         }
//                         CalculateTotalCost();
//                       });
//                     },
//                     icon: Icon(Icons.add,
//                         color: transferCount < 7
//                             ? Colors.black
//                             : Colors.grey.shade400,
//                         size: 16),
//                     style: IconButton.styleFrom(
//                       backgroundColor: Colors.grey.shade300,
//                       hoverColor: transferCount < 7
//                           ? Colors.grey.shade400
//                           : Colors.grey.shade300,
//                       minimumSize: const Size(24, 24),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       padding: EdgeInsets.zero,
//                     ),
//                   ),
//                 ],
//               ),
//               Row(
//                 children: [
//                   MyCheckBox(
//                     value: VIPDriverRequested,
//                     focusNode: VIPFocus,
//                     onChanged: (value) {
//                       setState(() {
//                         VIPDriverRequested = value ?? false;
//                         CalculateTotalCost();
//                       });
//                     },
//                   ),
//                   Text('VIP sofőr igénylése (Hozza viszi az autót a parkolóba)')
//                 ],
//               ),
//               Row(
//                 children: [
//                   MyCheckBox(
//                     value: suitcaseWrappingRequested,
//                     focusNode: suitcaseWrappingFocus,
//                     nextFocus: descriptionFocus,
//                     onChanged: (value) {
//                       setState(() {
//                         suitcaseWrappingRequested = value ?? false;
//                         if (suitcaseWrappingRequested) {
//                           suitcasesToWrap = 1;
//                         } else {
//                           suitcasesToWrap = 0;
//                         }

//                         CalculateTotalCost();
//                       });
//                     },
//                   ),
//                   Text('Bőrönd fóliázás igénylése'),
//                   suitcaseWrappingRequested
//                       ? Row(
//                           children: [
//                             SizedBox(width: 15),
//                             IconButton.filled(
//                               onPressed: () {
//                                 setState(() {
//                                   if (suitcasesToWrap > 0) {
//                                     suitcasesToWrap--;
//                                     if (suitcasesToWrap == 0) {
//                                       suitcaseWrappingRequested = false;
//                                     }

//                                     CalculateTotalCost();
//                                   }
//                                 });
//                               },
//                               icon: Icon(Icons.remove,
//                                   color: suitcasesToWrap > 0
//                                       ? Colors.black
//                                       : Colors.grey.shade400,
//                                   size: 16),
//                               style: IconButton.styleFrom(
//                                 backgroundColor: Colors.grey.shade300,
//                                 hoverColor: suitcasesToWrap > 0
//                                     ? Colors.grey.shade400
//                                     : Colors.grey.shade300,
//                                 minimumSize: const Size(24, 24),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 padding: EdgeInsets.zero,
//                               ),
//                             ),
//                             SizedBox(width: 8),
//                             Text('$suitcasesToWrap',
//                                 style: TextStyle(fontWeight: FontWeight.bold)),
//                             SizedBox(width: 8),
//                             IconButton.filled(
//                               onPressed: () {
//                                 setState(() {
//                                   if (suitcasesToWrap < 9) {
//                                     suitcasesToWrap++;
//                                   }
//                                   CalculateTotalCost();
//                                 });
//                               },
//                               icon: Icon(Icons.add,
//                                   color: suitcasesToWrap < 9
//                                       ? Colors.black
//                                       : Colors.grey.shade400,
//                                   size: 16),
//                               style: IconButton.styleFrom(
//                                 backgroundColor: Colors.grey.shade300,
//                                 hoverColor: suitcasesToWrap < 9
//                                     ? Colors.grey.shade400
//                                     : Colors.grey.shade300,
//                                 minimumSize: const Size(24, 24),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 padding: EdgeInsets.zero,
//                               ),
//                             ),
//                           ],
//                         )
//                       : Container()
//                 ],
//               ),
//               const SizedBox(height: 12),
//               selectedBookingOption == BookingOption.parking
//                   ? Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text.rich(
//                           TextSpan(
//                             text: 'Fizetendő összeg: ',
//                             style: TextStyle(fontSize: 16),
//                             children: [
//                               TextSpan(
//                                 text:
//                                     '${NumberFormat('#,###', 'hu_HU').format(totalCost)} Ft',
//                                 style: TextStyle(fontWeight: FontWeight.bold),
//                               ),
//                             ],
//                           ),
//                         ),
//                         MyRadioListTile<PaymentOption>(
//                           title: 'Bankkártyával fizetek',
//                           value: PaymentOption.card,
//                           groupValue: selectedPaymentOption,
//                           onChanged: (PaymentOption? value) {
//                             setState(() {
//                               selectedPaymentOption = value!;
//                             });
//                           },
//                           dense: true,
//                         ),
//                         MyRadioListTile<PaymentOption>(
//                           title:
//                               'Átutalással fizetek még a parkolás megkezdése előtt 1 nappal',
//                           value: PaymentOption.transfer,
//                           groupValue: selectedPaymentOption,
//                           onChanged: (PaymentOption? value) {
//                             setState(() {
//                               selectedPaymentOption = value!;
//                             });
//                           },
//                           dense: true,
//                         ),
//                         MyRadioListTile<PaymentOption>(
//                           title: 'Qvik',
//                           value: PaymentOption.qvik,
//                           groupValue: selectedPaymentOption,
//                           onChanged: (PaymentOption? value) {
//                             setState(() {
//                               selectedPaymentOption = value!;
//                             });
//                           },
//                           dense: true,
//                         ),
//                       ],
//                     )
//                   : Container(),
//               SizedBox(height: 10),
//               MyTextFormField(
//                 controller: descriptionController,
//                 focusNode: descriptionFocus,
//                 textInputAction: TextInputAction.next,
//                 nextFocus: nextPageButtonFocus,
//                 hintText: 'Megjegyzés a recepciónak',
//               ),
//               NextPageButton(
//                 title: "Parkolás foglalás",
//                 focusNode: nextPageButtonFocus,
//                 onPressed: OnNextPageButtonPressed,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
