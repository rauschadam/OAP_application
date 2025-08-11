// // ignore_for_file: file_names, non_constant_identifier_names

// import 'package:airport_test/enums/parkingFormEnums.dart';
// import 'package:airport_test/api_Services/reservation.dart';
// import 'package:airport_test/api_Services/api_service.dart';
// import 'package:airport_test/api_Services/registration.dart';
// import 'package:airport_test/stepData.dart';
// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_datepicker/datepicker.dart';

// class ParkingFormWizard extends StatefulWidget {
//   const ParkingFormWizard({super.key});

//   @override
//   ParkingFormWizardState createState() => ParkingFormWizardState();
// }

// class ParkingFormWizardState extends State<ParkingFormWizard> {
//   /// Aktuális idő
//   DateTime now = DateTime.now();

//   /// Az űrlapon történő lépegetéshez szükséges, ez mondja meg hanyadik lépésnél járunk
//   int currentStep = 0;

//   // Az enumok / kiválasztható lehetőségek default értékei
//   BookingOption? selectedBookingOption = BookingOption.parking;
//   RegistrationOption? selectedRegistrationOption =
//       RegistrationOption.registered;
//   InvoiceOption? selectedInvoiceOption = InvoiceOption.no;
//   ParkingZoneOption? selectedParkingZoneOption = ParkingZoneOption.premium;
//   PaymentOption? selectedPaymentOption = PaymentOption.card;
//   WashOption? selectedWashOption = WashOption.basic;

//   /// Transzferrel szállított személyek száma
//   int selectedTransferCount = 1;

//   /// Kér-e VIP sofőrt
//   bool VIPDriverRequested = false;

//   /// Kér-e Bőrönd fóliázást
//   bool SuticaseWrappingRequested = false;

//   late DateTime? selectedArriveDate, selectedLeaveDate;
//   int? parkingDays;
//   late int selectedStartHour;
//   int selectedStartMinute = 0;

//   String? authToken;

//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   final nameController = TextEditingController();
//   final phoneController = TextEditingController();
//   final favoriteLicensePlateNumberController = TextEditingController();
//   final licensePlateController = TextEditingController();
//   final noteController = TextEditingController();
//   final descriptionController = TextEditingController();

//   // Mosás időpontja
//   late int selectedWashHour;
//   int selectedWashMinute = 0;
//   late DateTime? selectedWashDate;

//   DateTime? tempArriveDate, tempLeaveDate;

//   // Teljes időpont pontos foglalt időpontok
//   List<DateTime> fullyBookedDates = [
//     DateTime(2025, 8, 10, 8, 0),
//     DateTime(2025, 8, 15, 15, 30),
//     DateTime(2025, 9, 1, 18, 30),
//   ];

//   // Csak a blackout napok (dátumok)
//   List<DateTime> blackoutDays = [];

//   void GetCurrentDate() {
//     DateTime now = DateTime.now();

//     selectedStartHour = now.hour + 1;
//     selectedArriveDate =
//         DateTime(now.year, now.month, now.day, selectedStartHour, 0);
//     selectedLeaveDate = selectedArriveDate;
//     selectedWashDate = selectedArriveDate;
//   }

//   void updateBlackoutDays() {
//     if (tempArriveDate == null || tempLeaveDate == null) {
//       blackoutDays = [];
//       return;
//     }

//     // Az érkezési és távozási időpont az óra+perc alapján
//     DateTime startDateTime = DateTime(
//       tempArriveDate!.year,
//       tempArriveDate!.month,
//       tempArriveDate!.day,
//       selectedStartHour,
//       selectedStartMinute,
//     );

//     DateTime endDateTime = DateTime(
//       tempLeaveDate!.year,
//       tempLeaveDate!.month,
//       tempLeaveDate!.day,
//       selectedStartHour,
//       selectedStartMinute,
//     );

//     // Szűrjük, hogy a fullyBookedDates-ben lévő időpont beleessen az intervallumba
//     final filtered = fullyBookedDates.where((d) {
//       return !d.isBefore(startDateTime) && !d.isAfter(endDateTime);
//     });

//     // A blackoutDays csak a dátum (év, hónap, nap), idő nélkül
//     blackoutDays =
//         filtered.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList();
//   }

//   /// Dátum kiíratásának a formátuma
//   String format(DateTime? d) => d != null
//       ? "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} "
//           "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}"
//       : '–';

//   @override
//   void initState() {
//     super.initState();
//     GetCurrentDate();
//   }

//   /// Beállítja az érkezés és távozás között eltelő napok számát
//   void UpdateParkingDays() {
//     parkingDays = selectedLeaveDate!.difference(selectedArriveDate!).inDays;
//   }

//   @override
//   Widget build(BuildContext context) {
//     /// Formon levő lépések
//     List<StepData> stepDataList = [
//       StepData(title: 'Foglalás Start 1', builder: buildStep1),
//       StepData(title: 'Regisztráció 2', builder: buildStep2),
//     ];

//     if (selectedRegistrationOption == RegistrationOption.registered) {
//       stepDataList.add(
//         StepData(
//           title: 'Bejelentkezés 2A',
//           builder: buildStep2A,
//           onNext: () async {
//             final api = ApiService();
//             final token = await api.loginUser('abc@valami.hu', 'asdasd');

//             if (token == null) {
//               print('Nem sikerült bejelentkezni');
//               return false; // ne lépjen tovább
//             } else {
//               print('Sikerült bejelentkezni');
//               setState(() {
//                 authToken = token;
//                 print(authToken);
//               });
//               return true; // mehet tovább
//             }
//           },
//         ),
//       );
//     } else if (selectedRegistrationOption == RegistrationOption.registerNow) {
//       stepDataList.add(
//         StepData(
//           title: 'Regisztráció 2B',
//           builder: buildStep2B,
//           onNext: () async {
//             // Beállítjuk a rendszámot
//             licensePlateController.text =
//                 favoriteLicensePlateNumberController.text;

//             // Regisztráljuk
//             final registration = Registration(
//                 name: nameController.text,
//                 password: passwordController.text,
//                 email: emailController.text,
//                 phone: phoneController.text,
//                 favoriteLicensePlateNumber:
//                     favoriteLicensePlateNumberController.text);

//             await ApiService().registerUser(registration);

//             // Bejelentkeztetjük
//             final api = ApiService();
//             final token = await api.loginUser('abc@valami.hu', 'asdasd');

//             if (token == null) {
//               print('Nem sikerült bejelentkezni');
//               return false; // ne lépjen tovább
//             } else {
//               setState(() {
//                 authToken = token;
//                 print(authToken);
//               });
//               return true; // mehet tovább
//             }
//           },
//         ),
//       );
//     }

//     if (selectedBookingOption == BookingOption.parking ||
//         selectedBookingOption == BookingOption.both) {
//       stepDataList.add(
//         StepData(title: 'Foglalás Parkoláshoz 3A', builder: buildStep3A),
//       );
//     }

//     if (selectedBookingOption == BookingOption.washing ||
//         selectedBookingOption == BookingOption.both) {
//       stepDataList.add(
//         StepData(title: 'Mosás részletei 3B', builder: buildStep3B),
//       );
//     }

//     stepDataList.add(
//       StepData(
//         title: 'Számlázás 4',
//         builder: buildStep4,
//         onNext: () async {
//           if (authToken == null) {
//             print('Nincs token, kérlek jelentkezz be újra.');
//             return false;
//           }

//           final reservation = Reservation(
//             parkingService: 1,
//             alreadyRegistered: true,
//             withoutRegistration: false,
//             name: nameController.text,
//             email: emailController.text,
//             phone: phoneController.text,
//             licensePlate: licensePlateController.text,
//             arriveDate: selectedArriveDate!,
//             leaveDate: selectedLeaveDate!,
//             parkingArticleId: "",
//             parkingArticleVolume: "1",
//             transferPersonCount: 3,
//             vip: VIPDriverRequested,
//             suitcaseWrappingCount: null,
//             carWashArticleId: "",
//             washDateTime: null,
//             payType: 1,
//             description: descriptionController.text,
//           );

//           await ApiService().submitReservation(reservation, authToken!);
//           return true; // ha van onNext értékelés
//         },
//       ),
//     );

//     // Biztos, ami biztos
//     if (currentStep >= stepDataList.length) {
//       currentStep = stepDataList.length - 1;
//     }

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue.shade200,
//         title: Text('Parkolási űrlap - ${stepDataList[currentStep].title}'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 600),
//             child: Column(
//               children: [
//                 Expanded(child: stepDataList[currentStep].builder()),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     if (currentStep > 0)
//                       ElevatedButton(
//                         onPressed: () {
//                           setState(() {
//                             currentStep--;
//                           });
//                         },
//                         child: const Text('Mégse'),
//                       )
//                     else
//                       const SizedBox(),
//                     ElevatedButton(
//                       onPressed: () async {
//                         final onNext = stepDataList[currentStep].onNext;

//                         if (onNext != null) {
//                           final success = await onNext();
//                           if (!success) {
//                             return; // Ha sikertelen, ne lépjen tovább
//                           }
//                         }

//                         setState(() {
//                           if (currentStep < stepDataList.length - 1) {
//                             currentStep++;
//                           }
//                         });
//                       },
//                       child: Text(currentStep == stepDataList.length - 1
//                           ? 'Befejezés'
//                           : 'Tovább'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildStep1() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RadioListTile<BookingOption>(
//           title: const Text('Parkolni szeretnék'),
//           value: BookingOption.parking,
//           groupValue: selectedBookingOption,
//           onChanged: (BookingOption? value) {
//             setState(() {
//               selectedBookingOption = value;
//             });
//           },
//         ),
//         RadioListTile<BookingOption>(
//           title: const Text('Csak mosatni szeretnék'),
//           value: BookingOption.washing,
//           groupValue: selectedBookingOption,
//           onChanged: (BookingOption? value) {
//             setState(() {
//               selectedBookingOption = value;
//             });
//           },
//         ),
//         RadioListTile<BookingOption>(
//           title: const Text('Parkolni és mosatni is szeretnék'),
//           value: BookingOption.both,
//           groupValue: selectedBookingOption,
//           onChanged: (BookingOption? value) {
//             setState(() {
//               selectedBookingOption = value;
//             });
//           },
//         ),
//       ],
//     );
//   }

//   Widget buildStep2() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RadioListTile<RegistrationOption>(
//           title: const Text('Regisztrált partner vagyok'),
//           value: RegistrationOption.registered,
//           groupValue: selectedRegistrationOption,
//           onChanged: (RegistrationOption? value) {
//             setState(() {
//               selectedRegistrationOption = value;
//             });
//           },
//         ),
//         RadioListTile<RegistrationOption>(
//           title: const Text('Most szeretnék regisztrálni'),
//           value: RegistrationOption.registerNow,
//           groupValue: selectedRegistrationOption,
//           onChanged: (RegistrationOption? value) {
//             setState(() {
//               selectedRegistrationOption = value;
//             });
//           },
//         ),
//         RadioListTile<RegistrationOption>(
//           title: const Text('Regisztráció nélkül vásárolok'),
//           value: RegistrationOption.withoutRegistration,
//           groupValue: selectedRegistrationOption,
//           onChanged: (RegistrationOption? value) {
//             setState(() {
//               selectedRegistrationOption = value;
//             });
//           },
//         ),
//       ],
//     );
//   }

//   Widget buildStep2A() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         TextField(
//           controller: emailController,
//           decoration: const InputDecoration(labelText: 'Email cím'),
//         ),
//         TextField(
//           controller: passwordController,
//           decoration: InputDecoration(labelText: 'Jelszó'),
//         ),
//       ],
//     );
//   }

//   Widget buildStep2B() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         TextField(
//           controller: nameController,
//           decoration: const InputDecoration(labelText: 'Felhasználó név'),
//         ),
//         TextField(
//           controller: passwordController,
//           decoration: InputDecoration(labelText: 'Jelszó'),
//         ),
//         TextField(
//           controller: emailController,
//           decoration: const InputDecoration(labelText: 'Email cím'),
//         ),
//         TextField(
//           controller: phoneController,
//           decoration: InputDecoration(labelText: 'Telefonszám'),
//         ),
//         TextField(
//           controller: favoriteLicensePlateNumberController,
//           decoration: const InputDecoration(labelText: 'Kedvenc rendszám'),
//         ),
//       ],
//     );
//   }

//   Widget buildStep3A() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         TextField(
//           controller: nameController,
//           decoration: const InputDecoration(labelText: 'Foglaló személy neve'),
//         ),
//         TextField(
//           controller: phoneController,
//           decoration: InputDecoration(labelText: 'Telefonszám'),
//         ),
//         TextField(
//           controller: licensePlateController,
//           decoration: InputDecoration(labelText: 'Várható rendszám'),
//         ),
//         const SizedBox(height: 10),
//         Row(children: [
//           ElevatedButton(
//               onPressed: ShowDatePickerDialog,
//               child: const Text("Válassz dátumot")),
//           const SizedBox(
//             width: 50,
//           ),
//           Expanded(
//             flex: 2,
//             child: Text("Parkolási napok száma: $parkingDays"),
//           ),
//           const SizedBox(
//             width: 10,
//           ),
//           Column(
//             children: [
//               Text("Érkezés: ${format(selectedArriveDate)}"),
//               Text("Távozás: ${format(selectedLeaveDate)}"),
//             ],
//           ),
//         ]),
//         const SizedBox(height: 16),
//         const Text('Parkoló zóna választás'),
//         RadioListTile<ParkingZoneOption>(
//           title: const Text('Fedett (10 000 Ft/ nap)'),
//           value: ParkingZoneOption.premium,
//           groupValue: selectedParkingZoneOption,
//           onChanged: (ParkingZoneOption? value) {
//             setState(() {
//               selectedParkingZoneOption = value;
//             });
//           },
//           dense: true,
//         ),
//         RadioListTile<ParkingZoneOption>(
//           title: const Text('Nyitott térköves (5 000 Ft/ nap)'),
//           value: ParkingZoneOption.normal,
//           groupValue: selectedParkingZoneOption,
//           onChanged: (ParkingZoneOption? value) {
//             setState(() {
//               selectedParkingZoneOption = value;
//             });
//           },
//           dense: true,
//         ),
//         RadioListTile<ParkingZoneOption>(
//           title: const Text('Nyitott murvás (2 000 Ft/ nap)'),
//           value: ParkingZoneOption.eco,
//           groupValue: selectedParkingZoneOption,
//           onChanged: (ParkingZoneOption? value) {
//             setState(() {
//               selectedParkingZoneOption = value;
//             });
//           },
//           dense: true,
//         ),
//         const SizedBox(height: 16),
//         DropdownButtonFormField<int>(
//           value: selectedTransferCount,
//           decoration: const InputDecoration(
//             labelText: 'Transfer - max 7 személy',
//             contentPadding: EdgeInsets.only(bottom: 10),
//             isDense: true,
//           ),
//           onChanged: (value) {
//             setState(() {
//               selectedTransferCount = value!;
//             });
//           },
//           items: List.generate(7, (index) {
//             final number = index + 1;
//             return DropdownMenuItem(
//               value: number,
//               child: Text('$number személy'),
//             );
//           }),
//         ),
//         Row(
//           children: [
//             Checkbox(
//               value: VIPDriverRequested,
//               onChanged: (value) {
//                 setState(() {
//                   VIPDriverRequested = value!;
//                 });
//               },
//             ),
//             const Text(
//                 'VIP sofőr igénylése (Hozza viszi az autót a parkolóba)'),
//           ],
//         ),
//         Row(
//           children: [
//             Checkbox(
//               value: SuticaseWrappingRequested,
//               onChanged: (value) {
//                 setState(() {
//                   SuticaseWrappingRequested = value!;
//                 });
//               },
//             ),
//             const Text('Bőrönd fóliázás igénylése'),
//           ],
//         ),
//         const SizedBox(height: 12),
//         const Text('Fizetendő összeg: 33 000 Ft'),
//         RadioListTile<PaymentOption>(
//           title: const Text('Bankkártyával fizetek'),
//           value: PaymentOption.card,
//           groupValue: selectedPaymentOption,
//           onChanged: (PaymentOption? value) {
//             setState(() {
//               selectedPaymentOption = value;
//             });
//           },
//           dense: true,
//         ),
//         RadioListTile<PaymentOption>(
//           title: const Text(
//               'Átutalássaé fizetek még a parkolás megkezdése előtt 1 nappal'),
//           value: PaymentOption.transfer,
//           groupValue: selectedPaymentOption,
//           onChanged: (PaymentOption? value) {
//             setState(() {
//               selectedPaymentOption = value;
//             });
//           },
//           dense: true,
//         ),
//         RadioListTile<PaymentOption>(
//           title: const Text('Qvik'),
//           value: PaymentOption.qvik,
//           groupValue: selectedPaymentOption,
//           onChanged: (PaymentOption? value) {
//             setState(() {
//               selectedPaymentOption = value;
//             });
//           },
//           dense: true,
//         ),
//         TextField(
//           controller: descriptionController,
//           decoration: const InputDecoration(
//               border: OutlineInputBorder(),
//               labelText: 'Megjegyzés a recepciónak'),
//         ),
//       ],
//     );
//   }

//   Widget buildStep3B() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const TextField(
//           decoration: InputDecoration(labelText: 'Foglaló személy neve'),
//         ),
//         const TextField(
//           decoration: InputDecoration(labelText: 'Email cím'),
//         ),
//         const TextField(
//           decoration: InputDecoration(labelText: 'Telefonszám'),
//         ),
//         const TextField(
//           decoration: InputDecoration(labelText: 'Várható rendszám'),
//         ),
//         const SizedBox(height: 16),
//         const Text('Mosás időpontja'),
//         const SizedBox(height: 16),
//         const Text('Válassza ki a kívánt programot'),
//         RadioListTile<WashOption>(
//           title: const Text('Alapmosás - 10 000 Ft'),
//           value: WashOption.basic,
//           groupValue: selectedWashOption,
//           onChanged: (WashOption? value) {
//             setState(() {
//               selectedWashOption = value;
//             });
//           },
//           dense: true,
//         ),
//         RadioListTile<WashOption>(
//           title: const Text('Mosás 2 - 20 000 Ft'),
//           value: WashOption.wash2,
//           groupValue: selectedWashOption,
//           onChanged: (WashOption? value) {
//             setState(() {
//               selectedWashOption = value;
//             });
//           },
//           dense: true,
//         ),
//         RadioListTile<WashOption>(
//           title: const Text('Mosás 3 - 30 000 Ft'),
//           value: WashOption.wash3,
//           groupValue: selectedWashOption,
//           onChanged: (WashOption? value) {
//             setState(() {
//               selectedWashOption = value;
//             });
//           },
//           dense: true,
//         ),
//         RadioListTile<WashOption>(
//           title: const Text('Mosás 4 - 40 000 Ft'),
//           value: WashOption.wash4,
//           groupValue: selectedWashOption,
//           onChanged: (WashOption? value) {
//             setState(() {
//               selectedWashOption = value;
//             });
//           },
//           dense: true,
//         ),
//         RadioListTile<WashOption>(
//           title: const Text('Szupermosás porszívóval - 50 000 Ft'),
//           value: WashOption.superWash,
//           groupValue: selectedWashOption,
//           onChanged: (WashOption? value) {
//             setState(() {
//               selectedWashOption = value;
//             });
//           },
//           dense: true,
//         ),
//         const SizedBox(height: 12),
//         const Text('Fizetendő összeg: 33 000 Ft'),
//         RadioListTile<PaymentOption>(
//           title: const Text('Bankkártyával fizetek'),
//           value: PaymentOption.card,
//           groupValue: selectedPaymentOption,
//           onChanged: (PaymentOption? value) {
//             setState(() {
//               selectedPaymentOption = value;
//             });
//           },
//           dense: true,
//         ),
//         RadioListTile<PaymentOption>(
//           title: const Text(
//               'Átutalássaé fizetek még a parkolás megkezdése előtt 1 nappal'),
//           value: PaymentOption.transfer,
//           groupValue: selectedPaymentOption,
//           onChanged: (PaymentOption? value) {
//             setState(() {
//               selectedPaymentOption = value;
//             });
//           },
//           dense: true,
//         ),
//         RadioListTile<PaymentOption>(
//           title: const Text('Qvik'),
//           value: PaymentOption.qvik,
//           groupValue: selectedPaymentOption,
//           onChanged: (PaymentOption? value) {
//             setState(() {
//               selectedPaymentOption = value;
//             });
//           },
//           dense: true,
//         ),
//         const TextField(
//           decoration: InputDecoration(
//               border: OutlineInputBorder(),
//               labelText: 'Megjegyzés a recepciónak'),
//         ),
//       ],
//     );
//   }

//   Widget buildStep4() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RadioListTile<InvoiceOption>(
//           title: const Text('Nem kérek számlát'),
//           value: InvoiceOption.no,
//           groupValue: selectedInvoiceOption,
//           onChanged: (InvoiceOption? value) {
//             setState(() {
//               selectedInvoiceOption = value;
//             });
//           },
//         ),
//         RadioListTile<InvoiceOption>(
//           title: const Text('Kérek számlát'),
//           value: InvoiceOption.yes,
//           groupValue: selectedInvoiceOption,
//           onChanged: (InvoiceOption? value) {
//             setState(() {
//               selectedInvoiceOption = value;
//             });
//           },
//         ),
//       ],
//     );
//   }

//   void ShowDatePickerDialog() {
//     tempArriveDate = selectedArriveDate;
//     tempLeaveDate = selectedLeaveDate;
//     // Alapból frissítjük a blackoutDays-et a már beállított temp értékek alapján
//     updateBlackoutDays();

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return Dialog(
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20)),
//               child: Container(
//                 width: 500,
//                 height: 550,
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     SfDateRangePicker(
//                       selectionMode: DateRangePickerSelectionMode.range,
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
//                       initialSelectedRange:
//                           tempArriveDate != null && tempLeaveDate != null
//                               ? PickerDateRange(tempArriveDate, tempLeaveDate)
//                               : null,
//                       onSelectionChanged: (args) {
//                         if (args.value is PickerDateRange) {
//                           final start = args.value.startDate;
//                           final end = args.value.endDate;

//                           setStateDialog(() {
//                             tempArriveDate = start;
//                             tempLeaveDate = end;
//                             updateBlackoutDays();
//                           });

//                           setState(() {
//                             UpdateParkingDays();
//                           });
//                         }
//                       },
//                     ),
//                     const SizedBox(height: 20),
//                     const Text("Érkezési idő:",
//                         style: TextStyle(fontWeight: FontWeight.bold)),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         DropdownButton<int>(
//                           value: selectedStartHour,
//                           items: List.generate(
//                               24,
//                               (i) => DropdownMenuItem(
//                                     value: i,
//                                     child: Text(i.toString().padLeft(2, '0')),
//                                   )),
//                           onChanged: (value) {
//                             setStateDialog(() {
//                               selectedStartHour = value!;
//                               updateBlackoutDays();
//                             });
//                           },
//                         ),
//                         const SizedBox(width: 10),
//                         const Text(":"),
//                         const SizedBox(width: 10),
//                         DropdownButton<int>(
//                           value: selectedStartMinute,
//                           items: [0, 30]
//                               .map((minute) => DropdownMenuItem(
//                                     value: minute,
//                                     child:
//                                         Text(minute.toString().padLeft(2, '0')),
//                                   ))
//                               .toList(),
//                           onChanged: (value) {
//                             setStateDialog(() {
//                               selectedStartMinute = value!;
//                               updateBlackoutDays();
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         ElevatedButton(
//                           onPressed: () {
//                             if (tempArriveDate != null &&
//                                 tempLeaveDate != null) {
//                               final diff = tempLeaveDate!
//                                   .difference(tempArriveDate!)
//                                   .inDays;

//                               if (diff > 30) {
//                                 ShowError(
//                                     "A választott tartomány legfeljebb 30 nap lehet.");
//                                 return;
//                               }

//                               bool containsBlackout = fullyBookedDates.any((b) {
//                                 final bDate = DateTime(
//                                     b.year, b.month, b.day, b.hour, b.minute);
//                                 final startDateTime = DateTime(
//                                     tempArriveDate!.year,
//                                     tempArriveDate!.month,
//                                     tempArriveDate!.day,
//                                     selectedStartHour,
//                                     selectedStartMinute);
//                                 final endDateTime = DateTime(
//                                     tempLeaveDate!.year,
//                                     tempLeaveDate!.month,
//                                     tempLeaveDate!.day,
//                                     selectedStartHour,
//                                     selectedStartMinute);

//                                 return !bDate.isBefore(startDateTime) &&
//                                     !bDate.isAfter(endDateTime);
//                               });

//                               if (containsBlackout) {
//                                 ShowError(
//                                     "A kiválasztott tartomány tartalmaz foglalt napot!");
//                                 return;
//                               }

//                               setState(() {
//                                 selectedArriveDate = DateTime(
//                                   tempArriveDate!.year,
//                                   tempArriveDate!.month,
//                                   tempArriveDate!.day,
//                                   selectedStartHour,
//                                   selectedStartMinute,
//                                 );

//                                 selectedLeaveDate = DateTime(
//                                   tempLeaveDate!.year,
//                                   tempLeaveDate!.month,
//                                   tempLeaveDate!.day,
//                                   selectedStartHour,
//                                   selectedStartMinute,
//                                 );

//                                 parkingDays = diff;
//                                 UpdateParkingDays();
//                               });
//                               Navigator.of(context).pop();
//                             } else {
//                               ShowError(
//                                   "Kérlek válassz ki egy dátumtartományt!");
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
// }
