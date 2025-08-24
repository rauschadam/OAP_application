// import 'package:airport_test/constantWidgets.dart';
// import 'package:airport_test/bookingForm/invoiceOptionPage.dart';
// import 'package:airport_test/enums/parkingFormEnums.dart';
// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_datepicker/datepicker.dart';

// class WashOrderPage extends StatefulWidget {
//   final String? authToken;
//   final BookingOption bookingOption;
//   final TextEditingController emailController;
//   final TextEditingController? nameController;
//   final TextEditingController? phoneController;
//   final TextEditingController? licensePlateController;
//   final TextEditingController? descriptionController;
//   final DateTime? arriveDate;
//   final DateTime? leaveDate;
//   final int? transferPersonCount;
//   final bool? vip;
//   const WashOrderPage({
//     super.key,
//     required this.authToken,
//     required this.bookingOption,
//     required this.emailController,
//     this.nameController,
//     this.phoneController,
//     this.licensePlateController,
//     this.descriptionController,
//     this.arriveDate,
//     this.leaveDate,
//     this.transferPersonCount,
//     this.vip,
//   });

//   @override
//   State<WashOrderPage> createState() => _WashOrderPageState();
// }

// class _WashOrderPageState extends State<WashOrderPage> {
//   final formKey = GlobalKey<FormState>();

//   // initState-ben átadjuk nekik az előző page-ben megadott adatokat
//   late final TextEditingController nameController;
//   late final TextEditingController phoneController;
//   late final TextEditingController licensePlateController;
//   late final TextEditingController descriptionController;

//   FocusNode nameFocus = FocusNode();
//   FocusNode phoneFocus = FocusNode();
//   FocusNode licensePlateFocus = FocusNode();
//   FocusNode datePickerFocus = FocusNode();
//   FocusNode descriptionFocus = FocusNode();
//   FocusNode nextPageButtonFocus = FocusNode();

//   // Default értékek
//   WashOption selectedWashOption = WashOption.basic;
//   PaymentOption selectedPaymentOption = PaymentOption.card;

//   /// Aktuális idő
//   DateTime now = DateTime.now();

//   /// Érkezési / Távozási dátum
//   late DateTime? selectedWashArriveDate, selectedWashLeaveDate;
//   late int selectedWashArriveHour;
//   int selectedWashArriveMinute = 0;

//   DateTime? tempWashArriveDate, tempWashLeaveDate;

//   //Teljes időpont pontos foglalt időpontok
//   List<DateTime> fullyBookedDates = [
//     DateTime(2025, 8, 10, 8, 0),
//     DateTime(2025, 8, 15, 15, 30),
//     DateTime(2025, 9, 1, 18, 30),
//   ];

//   // Csak a blackout napok (dátumok)
//   List<DateTime> blackoutDays = [];

//   int hoveredIndex = -1;

//   /// Lekéri az aktuális dátumot, és default beállítja a selectedWashArriveHour-t erre a dátumra.
//   void GetCurrentDate() {
//     DateTime now = DateTime.now();

//     selectedWashArriveHour = now.hour;

//     selectedWashArriveDate =
//         DateTime(now.year, now.month, now.day, selectedWashArriveHour, 0)
//             .add(const Duration(hours: 1));
//     selectedWashLeaveDate =
//         selectedWashArriveDate!.add(const Duration(minutes: 30));
//   }

//   /// Frissíti a telített foglalású napokat, ezekre már nem lehet foglalni.
//   void updateBlackoutDays() {
//     if (tempWashArriveDate == null) {
//       blackoutDays = [];
//       return;
//     }

//     //Az érkezési és távozási időpont az óra+perc alapján
//     DateTime startDateTime = DateTime(
//       tempWashArriveDate!.year,
//       tempWashArriveDate!.month,
//       tempWashArriveDate!.day,
//       selectedWashArriveHour,
//       selectedWashArriveMinute,
//     );

//     DateTime endDateTime = DateTime(
//       tempWashLeaveDate!.year,
//       tempWashLeaveDate!.month,
//       tempWashLeaveDate!.day,
//       selectedWashArriveHour,
//       selectedWashArriveMinute,
//     );

//     //Szűrjük, hogy a fullyBookedDates-ben lévő időpont beleessen az intervallumba
//     final filtered = fullyBookedDates.where((bookedDate) {
//       return !bookedDate.isBefore(startDateTime) &&
//           !bookedDate.isAfter(endDateTime);
//     });

//     //A blackoutDays csak a dátum (év, hónap, nap), idő nélkül
//     blackoutDays =
//         filtered.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList();
//   }

//   /// Dátum kiíratásának a formátuma
//   String format(DateTime? d) => d != null
//       ? "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} "
//           "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}"
//       : '–';

//   /// Az aktuálisan kiválasztott időpont (óra+perc) TimeOfDay típusként
//   // TimeOfDay get selectedWashArriveTime =>
//   //     TimeOfDay(hour: selectedWashArriveHour, minute: selectedWashArriveMinute);

//   /// Dátum választó pop-up dialog
//   void ShowDatePickerDialog() {
//     tempWashArriveDate = selectedWashArriveDate;
//     tempWashLeaveDate = selectedWashLeaveDate;

//     updateBlackoutDays();

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             // időpont választó kártyák widgetje
//             Widget buildTimeSlotPicker() {
//               final timeSlots = generateHalfHourTimeSlots();

//               return SizedBox(
//                 height: 200,
//                 child: GridView.builder(
//                   scrollDirection: Axis.vertical,
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 4,
//                     mainAxisSpacing: 8,
//                     crossAxisSpacing: 8,
//                     childAspectRatio: 2.5,
//                   ),
//                   itemCount: timeSlots.length,
//                   itemBuilder: (context, index) {
//                     final time = timeSlots[index];

//                     bool isBooked = fullyBookedDates.any((d) =>
//                         d.year == (tempWashArriveDate?.year ?? 0) &&
//                         d.month == (tempWashArriveDate?.month ?? 0) &&
//                         d.day == (tempWashArriveDate?.day ?? 0) &&
//                         d.hour == time.hour &&
//                         d.minute == time.minute);

//                     bool isSelected = selectedWashArriveHour == time.hour &&
//                         selectedWashArriveMinute == time.minute;

//                     bool isHovered = hoveredIndex == index;

//                     Color bgColor;
//                     if (isBooked) {
//                       bgColor = Colors.red[300]!;
//                     } else if (isSelected) {
//                       bgColor = Colors.deepPurple;
//                     } else if (isHovered) {
//                       bgColor = Colors.grey[400]!;
//                     } else {
//                       bgColor = Colors.grey[200]!;
//                     }

//                     return MouseRegion(
//                       onEnter: (_) {
//                         setStateDialog(() {
//                           hoveredIndex = index;
//                         });
//                       },
//                       onExit: (_) {
//                         setStateDialog(() {
//                           hoveredIndex = -1;
//                         });
//                       },
//                       cursor: isBooked
//                           ? SystemMouseCursors.basic
//                           : SystemMouseCursors.click,
//                       child: GestureDetector(
//                         onTap: isBooked
//                             ? null
//                             : () {
//                                 setStateDialog(() {
//                                   selectedWashArriveHour = time.hour;
//                                   selectedWashArriveMinute = time.minute;
//                                   updateBlackoutDays();
//                                 });
//                               },
//                         child: Card(
//                           color: bgColor,
//                           child: Center(
//                             child: Text(
//                               time.format(context),
//                               style: TextStyle(
//                                 color: isBooked || isSelected
//                                     ? Colors.white
//                                     : Colors.black,
//                                 fontWeight: isSelected
//                                     ? FontWeight.bold
//                                     : FontWeight.normal,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             }

//             return Dialog(
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20)),
//               child: Container(
//                 width: 600,
//                 height: 600,
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     SfDateRangePicker(
//                       selectionMode: DateRangePickerSelectionMode.single,
//                       showNavigationArrow: true,
//                       enablePastDates: false,
//                       maxDate: DateTime.now().add(const Duration(days: 120)),
//                       monthCellStyle: DateRangePickerMonthCellStyle(
//                         blackoutDateTextStyle: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         blackoutDatesDecoration: BoxDecoration(
//                           color: Colors.red,
//                           border: Border.all(color: Colors.redAccent, width: 1),
//                           borderRadius: BorderRadius.circular(32),
//                         ),
//                       ),
//                       monthViewSettings: DateRangePickerMonthViewSettings(
//                           blackoutDates: blackoutDays),
//                       selectableDayPredicate: (date) {
//                         return !blackoutDays.contains(
//                             DateTime(date.year, date.month, date.day));
//                       },
//                       onSelectionChanged: (args) {
//                         if (args.value is DateTime) {
//                           setStateDialog(() {
//                             tempWashArriveDate = args.value;
//                             updateBlackoutDays();
//                           });
//                         }
//                       },
//                     ),
//                     const Text("Érkezési idő:",
//                         style: TextStyle(fontWeight: FontWeight.bold)),
//                     buildTimeSlotPicker(),
//                     const SizedBox(height: 10),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         ElevatedButton(
//                           onPressed: () {
//                             if (tempWashArriveDate != null) {
//                               final arriveDateTime = DateTime(
//                                 tempWashArriveDate!.year,
//                                 tempWashArriveDate!.month,
//                                 tempWashArriveDate!.day,
//                                 selectedWashArriveHour,
//                                 selectedWashArriveMinute,
//                               );

//                               bool containsBlackout = fullyBookedDates.any((b) {
//                                 return b.isAtSameMomentAs(arriveDateTime);
//                               });

//                               if (containsBlackout) {
//                                 ShowError("A kiválasztott időpont foglalt!");
//                                 return;
//                               }

//                               setState(() {
//                                 selectedWashArriveDate = arriveDateTime;
//                                 selectedWashLeaveDate = arriveDateTime
//                                     .add(const Duration(minutes: 30));
//                               });

//                               Navigator.of(context).pop();
//                             } else {
//                               ShowError("Kérlek válassz ki egy dátumot!");
//                             }
//                           },
//                           child: const Text("OK"),
//                         ),
//                       ],
//                     )
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   /// Hiba megjelenítő pop-up dialog
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

//   @override
//   void initState() {
//     super.initState();

//     // Beállítjuk az előző page-ről a TextFormField-ek controller-eit
//     nameController = widget.nameController ?? TextEditingController();
//     phoneController = widget.phoneController ?? TextEditingController();
//     licensePlateController =
//         widget.licensePlateController ?? TextEditingController();
//     descriptionController =
//         widget.descriptionController ?? TextEditingController();

//     // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       FocusScope.of(context).requestFocus(nameFocus);
//     });

//     GetCurrentDate();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           TextFormField(
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Adja meg felhasználó nevét';
//               }
//               return null;
//             },
//             controller: nameController,
//             focusNode: nameFocus,
//             textInputAction: TextInputAction.next,
//             onEditingComplete: () {
//               FocusScope.of(context).requestFocus(phoneFocus);
//             },
//             decoration:
//                 const InputDecoration(labelText: 'Foglaló személy neve'),
//           ),
//           TextFormField(
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Adja meg telefonszámát';
//               }
//               return null;
//             },
//             controller: phoneController,
//             focusNode: phoneFocus,
//             textInputAction: TextInputAction.next,
//             onEditingComplete: () {
//               FocusScope.of(context).requestFocus(licensePlateFocus);
//             },
//             decoration: const InputDecoration(labelText: 'Telefonszám'),
//           ),
//           TextFormField(
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Adja meg rendszámát';
//               }
//               return null;
//             },
//             controller: licensePlateController,
//             focusNode: licensePlateFocus,
//             textInputAction: TextInputAction.next,
//             onEditingComplete: () {
//               FocusScope.of(context).requestFocus(datePickerFocus);
//             },
//             decoration: const InputDecoration(labelText: 'Várható rendszám'),
//           ),
//           const SizedBox(height: 16),
//           Row(children: [
//             ElevatedButton(
//                 focusNode: datePickerFocus,
//                 onPressed: ShowDatePickerDialog,
//                 child: const Text("Válassz dátumot")),
//             const SizedBox(
//               width: 10,
//             ),
//             Column(
//               children: [
//                 Text("Érkezés: ${format(selectedWashArriveDate)}"),
//                 Text("Távozás: ${format(selectedWashLeaveDate)}"),
//               ],
//             ),
//           ]),
//           const SizedBox(height: 12),
//           const Text('Válassza ki a kívánt programot'),
//           MyRadioListTile<WashOption>(
//             title: 'Alapmosás',
//             subtitle: '10 000 Ft',
//             value: WashOption.basic,
//             groupValue: selectedWashOption,
//             onChanged: (WashOption? value) {
//               setState(() {
//                 selectedWashOption = value!;
//               });
//             },
//             dense: true,
//           ),
//           MyRadioListTile<WashOption>(
//             title: 'Mosás 2',
//             subtitle: '20 000 Ft',
//             value: WashOption.wash2,
//             groupValue: selectedWashOption,
//             onChanged: (WashOption? value) {
//               setState(() {
//                 selectedWashOption = value!;
//               });
//             },
//             dense: true,
//           ),
//           MyRadioListTile<WashOption>(
//             title: 'Mosás 3',
//             subtitle: '30 000 Ft',
//             value: WashOption.wash3,
//             groupValue: selectedWashOption,
//             onChanged: (WashOption? value) {
//               setState(() {
//                 selectedWashOption = value!;
//               });
//             },
//             dense: true,
//           ),
//           MyRadioListTile<WashOption>(
//             title: 'Mosás 4',
//             subtitle: '40 000 Ft',
//             value: WashOption.wash4,
//             groupValue: selectedWashOption,
//             onChanged: (WashOption? value) {
//               setState(() {
//                 selectedWashOption = value!;
//               });
//             },
//             dense: true,
//           ),
//           MyRadioListTile<WashOption>(
//             title: 'Szupermosás porszívóval',
//             subtitle: '50 000 Ft',
//             value: WashOption.superWash,
//             groupValue: selectedWashOption,
//             onChanged: (WashOption? value) {
//               setState(() {
//                 selectedWashOption = value!;
//               });
//             },
//             dense: true,
//           ),
//           const SizedBox(height: 10),
//           const Text('Fizetendő összeg: 33 000 Ft'),
//           MyRadioListTile<PaymentOption>(
//             title: 'Bankkártyával fizetek',
//             value: PaymentOption.card,
//             groupValue: selectedPaymentOption,
//             onChanged: (PaymentOption? value) {
//               setState(() {
//                 selectedPaymentOption = value!;
//               });
//             },
//             dense: true,
//           ),
//           MyRadioListTile<PaymentOption>(
//             title:
//                 'Átutalással fizetek még a parkolás megkezdése előtt 1 nappal',
//             value: PaymentOption.transfer,
//             groupValue: selectedPaymentOption,
//             onChanged: (PaymentOption? value) {
//               setState(() {
//                 selectedPaymentOption = value!;
//               });
//             },
//             dense: true,
//           ),
//           MyRadioListTile<PaymentOption>(
//             title: 'Qvik',
//             value: PaymentOption.qvik,
//             groupValue: selectedPaymentOption,
//             onChanged: (PaymentOption? value) {
//               setState(() {
//                 selectedPaymentOption = value!;
//               });
//             },
//             dense: true,
//           ),
//           TextFormField(
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Adja meg felhasználó nevét';
//               }
//               return null;
//             },
//             focusNode: descriptionFocus,
//             controller: descriptionController,
//             decoration: const InputDecoration(
//                 border: OutlineInputBorder(),
//                 labelText: 'Megjegyzés a recepciónak'),
//             onEditingComplete: () {
//               FocusScope.of(context).requestFocus(nextPageButtonFocus);
//             },
//           ),
//           NextPageButton(
//               focusNode: nextPageButtonFocus,
//               title: "Számlázás",
//               nextPage: InvoiceOptionPage(
//                 authToken: widget.authToken,
//                 nameController: nameController,
//                 emailController: widget.emailController,
//                 phoneController: phoneController,
//                 licensePlateController: licensePlateController,
//                 arriveDate: widget.arriveDate,
//                 leaveDate: widget.leaveDate,
//                 transferPersonCount: widget.transferPersonCount,
//                 washDateTime: selectedWashArriveDate,
//                 vip: widget.vip,
//                 descriptionController: descriptionController,
//                 bookingOption: widget.bookingOption,
//               ))
//         ],
//       ),
//     );
//   }
// }

// /// Félórás időpontok generálása az időpont választáshoz 0:00 - 23:30 között
// List<TimeOfDay> generateHalfHourTimeSlots() {
//   List<TimeOfDay> slots = [];
//   for (int hour = 0; hour <= 23; hour++) {
//     slots.add(TimeOfDay(hour: hour, minute: 0));
//     slots.add(TimeOfDay(hour: hour, minute: 30));
//   }
//   return slots;
// }

import 'package:airport_test/constantWidgets.dart';
import 'package:airport_test/bookingForm/invoiceOptionPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class WashOrderPage extends StatefulWidget {
  final String? authToken;
  final BookingOption bookingOption;
  final TextEditingController emailController;
  final TextEditingController? nameController;
  final TextEditingController? phoneController;
  final TextEditingController? licensePlateController;
  final TextEditingController? descriptionController;
  final DateTime? arriveDate;
  final DateTime? leaveDate;
  final int? transferPersonCount;
  final bool? vip;
  final int? parkingCost;
  const WashOrderPage(
      {super.key,
      required this.authToken,
      required this.bookingOption,
      required this.emailController,
      this.nameController,
      this.phoneController,
      this.licensePlateController,
      this.descriptionController,
      this.arriveDate,
      this.leaveDate,
      this.transferPersonCount,
      this.vip,
      this.parkingCost});

  @override
  State<WashOrderPage> createState() => WashOrderPageState();
}

class WashOrderPageState extends State<WashOrderPage> {
  final formKey = GlobalKey<FormState>();

  // initState-ben átadjuk nekik az előző page-ben megadott adatokat
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController licensePlateController;
  late final TextEditingController descriptionController;
  final ScrollController WashOptionsScrollController = ScrollController();

  FocusNode nameFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode licensePlateFocus = FocusNode();
  FocusNode datePickerFocus = FocusNode();
  FocusNode descriptionFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();

  // Default értékek
  WashOption selectedWashOption = WashOption.basic;
  PaymentOption selectedPaymentOption = PaymentOption.card;

  /// A teljes fizetendő összeg
  late int totalCost;

  void CalculateTotalCost() {
    int baseCost = widget.parkingCost ?? 0;

    switch (selectedWashOption) {
      case WashOption.basic:
        baseCost = 10000;
        break;
      case WashOption.wash2:
        baseCost = 20000;
        break;
      case WashOption.wash3:
        baseCost = 30000;
        break;
      case WashOption.wash4:
        baseCost = 40000;
        break;
      case WashOption.superWash:
        baseCost = 50000;
        break;
    }

    setState(() {
      totalCost = baseCost;
    });
  }

  /// Aktuális idő
  DateTime now = DateTime.now();

  /// Érkezési / Távozási dátum
  DateTime? selectedWashDate;
  TimeOfDay? selectedWashTime;

  DateTime? tempWashDate;

  //Teljes időpont pontos foglalt időpontok
  List<DateTime> fullyBookedDateTimes = [
    DateTime(2025, 8, 10, 8, 0),
    DateTime(2025, 8, 15, 15, 30),
    DateTime(2025, 9, 1, 18, 30),
  ];

  // Csak a blackout napok (dátumok)
  List<DateTime> blackoutDays = [];

  int hoveredIndex = -1;

  /// Frissíti a telített foglalású napokat, ezekre már nem lehet foglalni.
  void updateBlackoutDateTimes() {
    if (tempWashDate == null) {
      blackoutDays = [];
      return;
    }

    //A  mosási időpont az óra+perc alapján
    DateTime startDateTime = DateTime(
      tempWashDate!.year,
      tempWashDate!.month,
      tempWashDate!.day,
      selectedWashTime!.hour,
      selectedWashTime!.minute,
    );

    //Szűrjük, hogy a fullyBookedDates-ben lévő időpont beleessen az intervallumba
    final filtered = fullyBookedDateTimes.where((bookedDate) {
      return !bookedDate.isAtSameMomentAs(startDateTime);
    });

    //A blackoutDays csak a dátum (év, hónap, nap), idő nélkül
    blackoutDays =
        filtered.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList();
  }

  /// Dátum kiíratásának a formátuma
  String format(DateTime? d) => d != null
      ? "${d.year}. ${d.month.toString().padLeft(2, '0')}. ${d.day.toString().padLeft(2, '0')}. "
          "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}"
      : '-';

  /// Dátum választó pop-up dialog
  void ShowDatePickerDialog() {
    tempWashDate = selectedWashDate;

    updateBlackoutDateTimes();

    Map<String, int> hoveredIndexMap = {
      "Hajnal": -1,
      "Reggel": -1,
      "Nap": -1,
      "Este": -1,
      "Éjszaka": -1,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final allSlots = generateHalfHourTimeSlots();
            final today = DateTime.now();
            final currentTime = TimeOfDay.fromDateTime(today);

            final availableSlots = allSlots.where((time) {
              if (tempWashDate != null &&
                  tempWashDate!.year == today.year &&
                  tempWashDate!.month == today.month &&
                  tempWashDate!.day == today.day) {
                if (time.hour < currentTime.hour ||
                    (time.hour == currentTime.hour &&
                        time.minute <= currentTime.minute)) {
                  return false;
                }
              }

              bool isBooked = fullyBookedDateTimes.any((d) =>
                  d.year == (tempWashDate?.year ?? 0) &&
                  d.month == (tempWashDate?.month ?? 0) &&
                  d.day == (tempWashDate?.day ?? 0) &&
                  d.hour == time.hour &&
                  d.minute == time.minute);

              return !isBooked;
            }).toList();

            // időpont választó kártyák widgetje
            Widget buildTimeSlotPicker(List<TimeOfDay> slots) {
              Map<String, List<TimeOfDay>> groupedSlots = {
                "Hajnal": [],
                "Reggel": [],
                "Nappal": [],
                "Este": [],
                "Éjszaka": [],
              };

              for (var time in slots) {
                if (time.hour < 6) {
                  groupedSlots["Hajnal"]!.add(time);
                } else if (time.hour >= 6 && time.hour < 12) {
                  groupedSlots["Reggel"]!.add(time);
                } else if (time.hour >= 12 && time.hour < 18) {
                  groupedSlots["Nappal"]!.add(time);
                } else if (time.hour >= 18 && time.hour < 22) {
                  groupedSlots["Este"]!.add(time);
                } else {
                  groupedSlots["Éjszaka"]!.add(time);
                }
              }

              return Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: groupedSlots.entries
                        .where((entry) => entry.value.isNotEmpty)
                        .map((entry) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          iconColor: Colors.grey.shade700,
                          title: Text(entry.key,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              )),
                          initiallyExpanded: true,
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 3,
                              ),
                              itemCount: entry.value.length,
                              itemBuilder: (context, index) {
                                final time = entry.value[index];
                                bool isSelected = selectedWashTime == time;
                                bool isHovered =
                                    hoveredIndexMap[entry.key] == index;

                                Color cardColor;
                                if (isSelected) {
                                  cardColor = BasePage.defaultColors.primary;
                                } else if (isHovered) {
                                  cardColor = Colors.grey.shade400;
                                } else {
                                  cardColor = Colors.grey.shade300;
                                }

                                return MouseRegion(
                                  onEnter: (_) {
                                    setStateDialog(() {
                                      hoveredIndexMap[entry.key] = index;
                                    });
                                  },
                                  onExit: (_) {
                                    setStateDialog(() {
                                      hoveredIndexMap[entry.key] = -1;
                                    });
                                  },
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      setStateDialog(() {
                                        selectedWashTime = time;
                                        if (selectedWashTime != null) {
                                          updateBlackoutDateTimes();
                                        }
                                      });
                                    },
                                    child: Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      color: cardColor,
                                      child: Center(
                                        child: Text(
                                          time.format(context),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 600,
                height: 800,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SfDateRangePicker(
                      initialDisplayDate: selectedWashDate,
                      initialSelectedDate: selectedWashDate,
                      selectionMode: DateRangePickerSelectionMode.single,
                      todayHighlightColor: BasePage.defaultColors.primary,
                      selectionColor: BasePage.defaultColors.primary,
                      showNavigationArrow: true,
                      enablePastDates: false,
                      maxDate: DateTime.now().add(const Duration(days: 120)),
                      onSelectionChanged: (args) {
                        if (args.value is DateTime) {
                          setStateDialog(() {
                            tempWashDate = args.value;
                            if (selectedWashTime != null) {
                              updateBlackoutDateTimes();
                            }
                          });
                        }
                      },
                    ),
                    buildTimeSlotPicker(availableSlots),
                    const SizedBox(height: 10),
                    (tempWashDate != null && selectedWashTime != null)
                        ? SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                      BasePage.defaultColors.primary),
                                  foregroundColor: WidgetStateProperty.all(
                                      BasePage.defaultColors.background)),
                              onPressed: () {
                                final arriveDateTime = DateTime(
                                  tempWashDate!.year,
                                  tempWashDate!.month,
                                  tempWashDate!.day,
                                  selectedWashTime!.hour,
                                  selectedWashTime!.minute,
                                );

                                setState(() {
                                  selectedWashDate = arriveDateTime;
                                });

                                Navigator.of(context).pop();
                              },
                              child: const Text("Időpont kiválasztása"),
                            ),
                          )
                        : Container()
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Hiba megjelenítő pop-up dialog
  void ShowError(String msg) => showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Hiba"),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      if (selectedWashDate != null && selectedWashTime != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BasePage(
              title: "Számlázás",
              child: InvoiceOptionPage(
                authToken: widget.authToken,
                nameController: nameController,
                emailController: widget.emailController,
                phoneController: phoneController,
                licensePlateController: licensePlateController,
                arriveDate: widget.arriveDate,
                leaveDate: widget.leaveDate,
                transferPersonCount: widget.transferPersonCount,
                washDateTime: DateTime(
                    selectedWashDate!.year,
                    selectedWashDate!.month,
                    selectedWashDate!.day,
                    selectedWashTime!.hour,
                    selectedWashTime!.minute),
                vip: widget.vip,
                descriptionController: descriptionController,
                bookingOption: widget.bookingOption,
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Válassz ki Parkolási intervallumot!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sikertelen Bejelentkezés!')),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    totalCost = widget.parkingCost ?? 0;

    // Beállítjuk az előző page-ről a TextFormField-ek controller-eit
    nameController = widget.nameController ?? TextEditingController();
    phoneController = widget.phoneController ?? TextEditingController();
    licensePlateController =
        widget.licensePlateController ?? TextEditingController();
    descriptionController =
        widget.descriptionController ?? TextEditingController();

    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(nameFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyTextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Adja meg felhasználó nevét';
                    }
                    return null;
                  },
                  controller: nameController,
                  focusNode: nameFocus,
                  textInputAction: TextInputAction.next,
                  nextFocus: phoneFocus,
                  hintText: 'Foglaló személy neve'),
              const SizedBox(height: 10),
              MyTextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Adja meg telefonszámát';
                    }
                    return null;
                  },
                  controller: phoneController,
                  focusNode: phoneFocus,
                  textInputAction: TextInputAction.next,
                  nextFocus: licensePlateFocus,
                  hintText: 'Telefonszám'),
              const SizedBox(height: 10),
              MyTextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Adja meg rendszámát';
                    }
                    return null;
                  },
                  controller: licensePlateController,
                  focusNode: licensePlateFocus,
                  textInputAction: TextInputAction.next,
                  nextFocus: datePickerFocus,
                  hintText: 'Várható rendszám'),
              const SizedBox(height: 16),
              Row(children: [
                MyIconButton(
                    icon: Icons.calendar_month_rounded,
                    labelText: 'Válassz dátumot',
                    onPressed: ShowDatePickerDialog),
                const SizedBox(width: 50),
                Column(
                  children: [Text('Érkezés'), Text(format(selectedWashDate))],
                ),
              ]),
              const SizedBox(height: 12),
              const Text('Válassza ki a kívánt programot'),
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  WashOptionsScrollController.jumpTo(
                    WashOptionsScrollController.position.pixels -
                        details.delta.dx,
                  );
                },
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: WashOptionsScrollController,
                  padding: EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      WashOptionSelectionCard(
                        title: 'Alapmosás',
                        washCost: 10000,
                        selected: selectedWashOption == WashOption.basic,
                        onTap: () {
                          setState(() {
                            selectedWashOption = WashOption.basic;
                          });
                          CalculateTotalCost();
                        },
                      ),
                      WashOptionSelectionCard(
                        title: 'Mosás 2',
                        washCost: 20000,
                        selected: selectedWashOption == WashOption.wash2,
                        onTap: () {
                          setState(() {
                            selectedWashOption = WashOption.wash2;
                          });
                          CalculateTotalCost();
                        },
                      ),
                      WashOptionSelectionCard(
                        title: 'Mosás 3',
                        washCost: 30000,
                        selected: selectedWashOption == WashOption.wash3,
                        onTap: () {
                          setState(() {
                            selectedWashOption = WashOption.wash3;
                          });
                          CalculateTotalCost();
                        },
                      ),
                      WashOptionSelectionCard(
                        title: 'Mosás 4',
                        washCost: 40000,
                        selected: selectedWashOption == WashOption.wash4,
                        onTap: () {
                          setState(() {
                            selectedWashOption = WashOption.wash4;
                          });
                          CalculateTotalCost();
                        },
                      ),
                      WashOptionSelectionCard(
                        title: 'Szupermosás porszívóval',
                        washCost: 50000,
                        selected: selectedWashOption == WashOption.superWash,
                        onTap: () {
                          setState(() {
                            selectedWashOption = WashOption.superWash;
                          });
                          CalculateTotalCost();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  text: 'Fizetendő összeg: ',
                  style: TextStyle(fontSize: 16),
                  children: [
                    TextSpan(
                      text:
                          '${NumberFormat('#,###', 'hu_HU').format(totalCost)} Ft',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              MyRadioListTile<PaymentOption>(
                title: 'Bankkártyával fizetek',
                value: PaymentOption.card,
                groupValue: selectedPaymentOption,
                onChanged: (PaymentOption? value) {
                  setState(() {
                    selectedPaymentOption = value!;
                  });
                },
                dense: true,
              ),
              MyRadioListTile<PaymentOption>(
                title:
                    'Átutalással fizetek még a parkolás megkezdése előtt 1 nappal',
                value: PaymentOption.transfer,
                groupValue: selectedPaymentOption,
                onChanged: (PaymentOption? value) {
                  setState(() {
                    selectedPaymentOption = value!;
                  });
                },
                dense: true,
              ),
              MyRadioListTile<PaymentOption>(
                title: 'Qvik',
                value: PaymentOption.qvik,
                groupValue: selectedPaymentOption,
                onChanged: (PaymentOption? value) {
                  setState(() {
                    selectedPaymentOption = value!;
                  });
                },
                dense: true,
              ),
              SizedBox(height: 10),
              MyTextFormField(
                focusNode: descriptionFocus,
                controller: descriptionController,
                hintText: 'Megjegyzés a recepciónak',
                nextFocus: nextPageButtonFocus,
              ),
              NextPageButton(
                focusNode: nextPageButtonFocus,
                title: "Számlázás",
                onPressed: OnNextPageButtonPressed,
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// Félórás időpontok generálása az időpont választáshoz 0:00 - 23:30 között
List<TimeOfDay> generateHalfHourTimeSlots() {
  List<TimeOfDay> slots = [];
  for (int hour = 0; hour <= 23; hour++) {
    slots.add(TimeOfDay(hour: hour, minute: 0));
    slots.add(TimeOfDay(hour: hour, minute: 30));
  }
  return slots;
}
