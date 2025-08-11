import 'package:airport_test/basePage.dart';
import 'package:airport_test/bookingForm/invoiceOptionPage.dart';
import 'package:airport_test/bookingForm/washOrderPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class ParkOrderPage extends StatefulWidget {
  final String? authToken;
  final BookingOption bookingOption;
  final TextEditingController emailController;
  final TextEditingController? nameController;
  final TextEditingController? phoneController;
  final TextEditingController? licensePlateController;
  const ParkOrderPage(
      {super.key,
      required this.authToken,
      required this.bookingOption,
      required this.emailController,
      this.nameController,
      this.phoneController,
      this.licensePlateController});

  @override
  State<ParkOrderPage> createState() => _ParkOrderPageState();
}

class _ParkOrderPageState extends State<ParkOrderPage> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController licensePlateController;
  late final TextEditingController descriptionController;

  FocusNode nameFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode licensePlateFocus = FocusNode();
  FocusNode descriptionFocus = FocusNode();
  FocusNode datePickerFocus = FocusNode();
  FocusNode VIPFocus = FocusNode();
  FocusNode suitcaseWrappingFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();
  FocusNode transferFocus = FocusNode();

  /// Aktuális idő
  DateTime now = DateTime.now();

  // Az enumok / kiválasztható lehetőségek default értékei
  BookingOption? selectedBookingOption = BookingOption.parking;
  ParkingZoneOption? selectedParkingZoneOption = ParkingZoneOption.premium;
  PaymentOption? selectedPaymentOption = PaymentOption.card;

  /// Transzferrel szállított személyek száma
  int selectedTransferCount = 1;

  /// Kér-e VIP sofőrt
  bool VIPDriverRequested = false;

  /// Kér-e Bőrönd fóliázást
  bool suitcaseWrappingRequested = false;

  /// Érkezési / Távozási dátum
  DateTime? selectedArriveDate, selectedLeaveDate;
  late int selectedArriveHour;
  int selectedArriveMinute = 0;

  /// Parkolással töltött napok száma
  int parkingDays = 0;

  DateTime? tempArriveDate, tempLeaveDate;

  //Teljes időpont pontos foglalt időpontok
  List<DateTime> fullyBookedDates = [
    DateTime(2025, 8, 10, 8, 0),
    DateTime(2025, 8, 15, 15, 30),
    DateTime(2025, 9, 1, 18, 30),
  ];

  // Csak a blackout napok (dátumok)
  List<DateTime> blackoutDays = [];

  void GetCurrentDate() {
    DateTime now = DateTime.now();

    /// Nem jó mert nem vált dátumot
    if (now.hour < 23) {
      selectedArriveHour = now.hour + 1;
    } else {
      selectedArriveHour = 0;
    }
  }

  void UpdateParkingDays() {
    parkingDays = selectedLeaveDate!.difference(selectedArriveDate!).inDays;
  }

  void updateBlackoutDays() {
    if (tempArriveDate == null || tempLeaveDate == null) {
      blackoutDays = [];
      return;
    }

    //Az érkezési és távozási időpont az óra+perc alapján
    DateTime startDateTime = DateTime(
      tempArriveDate!.year,
      tempArriveDate!.month,
      tempArriveDate!.day,
      selectedArriveHour,
      selectedArriveMinute,
    );

    DateTime endDateTime = DateTime(
      tempLeaveDate!.year,
      tempLeaveDate!.month,
      tempLeaveDate!.day,
      selectedArriveHour,
      selectedArriveMinute,
    );

    //Szűrjük, hogy a fullyBookedDates-ben lévő időpont beleessen az intervallumba
    final filtered = fullyBookedDates.where((d) {
      return !d.isBefore(startDateTime) && !d.isAfter(endDateTime);
    });

    //A blackoutDays csak a dátum (év, hónap, nap), idő nélkül
    blackoutDays =
        filtered.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList();
  }

  /// Dátum kiíratásának a formátuma
  String format(DateTime? d) => d != null
      ? "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} "
          "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}"
      : '–';

  void ShowDatePickerDialog() {
    tempArriveDate = selectedArriveDate;
    tempLeaveDate = selectedLeaveDate;

    // Alapból frissítjük a blackoutDays-et a már beállított temp értékek alapján
    updateBlackoutDays();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 500,
                height: 550,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SfDateRangePicker(
                      selectionMode: DateRangePickerSelectionMode.range,
                      enablePastDates: false,
                      maxDate: DateTime.now().add(const Duration(days: 120)),
                      monthCellStyle: DateRangePickerMonthCellStyle(
                        blackoutDateTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        blackoutDatesDecoration: BoxDecoration(
                          color: Colors.red,
                          border: Border.all(color: Colors.redAccent, width: 1),
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      monthViewSettings: DateRangePickerMonthViewSettings(
                          blackoutDates: blackoutDays),
                      selectableDayPredicate: (date) {
                        return !blackoutDays.contains(
                            DateTime(date.year, date.month, date.day));
                      },
                      initialSelectedRange:
                          tempArriveDate != null && tempLeaveDate != null
                              ? PickerDateRange(tempArriveDate, tempLeaveDate)
                              : null,
                      onSelectionChanged: (args) {
                        if (args.value is PickerDateRange) {
                          final start = args.value.startDate;
                          final end = args.value.endDate;

                          setStateDialog(() {
                            tempArriveDate = start;
                            tempLeaveDate = end;
                            updateBlackoutDays();
                          });

                          if (selectedLeaveDate != null) {
                            setState(() {
                              UpdateParkingDays();
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text("Érkezési idő:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton<int>(
                          value: selectedArriveHour,
                          items: List.generate(
                              24,
                              (i) => DropdownMenuItem(
                                    value: i,
                                    child: Text(i.toString().padLeft(2, '0')),
                                  )),
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedArriveHour = value!;
                              if (tempArriveDate != null) {
                                tempArriveDate = DateTime(
                                  tempArriveDate!.year,
                                  tempArriveDate!.month,
                                  tempArriveDate!.day,
                                );
                              }
                              if (tempLeaveDate != null) {
                                tempLeaveDate = DateTime(
                                  tempLeaveDate!.year,
                                  tempLeaveDate!.month,
                                  tempLeaveDate!.day,
                                );
                              }
                              updateBlackoutDays();
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        const Text(":"),
                        const SizedBox(width: 10),
                        DropdownButton<int>(
                          value: selectedArriveMinute,
                          items: [0, 30]
                              .map((minute) => DropdownMenuItem(
                                    value: minute,
                                    child:
                                        Text(minute.toString().padLeft(2, '0')),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedArriveMinute = value!;
                              updateBlackoutDays();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (tempArriveDate != null &&
                                tempLeaveDate != null) {
                              final diff = tempLeaveDate!
                                  .difference(tempArriveDate!)
                                  .inDays;
                              if (diff < 1) {
                                ShowError(
                                    "A választott tartománynak legalább 1 napnak kell lennie.");
                                return;
                              }
                              if (diff > 30) {
                                ShowError(
                                    "A választott tartomány legfeljebb 30 nap lehet.");
                                return;
                              }

                              bool containsBlackout = fullyBookedDates.any((b) {
                                final bDate = DateTime(
                                    b.year, b.month, b.day, b.hour, b.minute);
                                final startDateTime = DateTime(
                                  tempArriveDate!.year,
                                  tempArriveDate!.month,
                                  tempArriveDate!.day,
                                  selectedArriveHour,
                                  selectedArriveMinute,
                                );
                                final endDateTime = DateTime(
                                  tempLeaveDate!.year,
                                  tempLeaveDate!.month,
                                  tempLeaveDate!.day,
                                  selectedArriveHour,
                                  selectedArriveMinute,
                                );

                                return !bDate.isBefore(startDateTime) &&
                                    !bDate.isAfter(endDateTime);
                              });

                              if (containsBlackout) {
                                ShowError(
                                    "A kiválasztott tartomány tartalmaz foglalt napot!");
                                return;
                              }

                              setState(() {
                                selectedArriveDate = DateTime(
                                  tempArriveDate!.year,
                                  tempArriveDate!.month,
                                  tempArriveDate!.day,
                                  selectedArriveHour,
                                  selectedArriveMinute,
                                );

                                selectedLeaveDate = DateTime(
                                  tempLeaveDate!.year,
                                  tempLeaveDate!.month,
                                  tempLeaveDate!.day,
                                  selectedArriveHour,
                                  selectedArriveMinute,
                                );

                                parkingDays = diff;
                                UpdateParkingDays();
                              });
                              Navigator.of(context).pop();
                            } else {
                              ShowError(
                                  "Kérlek válassz ki egy dátumtartományt!");
                            }
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
      Widget? nextPage;
      if (widget.bookingOption == BookingOption.parking) {
        nextPage = InvoiceOptionPage(
          authToken: widget.authToken,
          nameController: nameController,
          emailController: widget.emailController,
          phoneController: phoneController,
          licensePlateController: licensePlateController,
          arriveDate: selectedArriveDate,
          leaveDate: selectedLeaveDate,
          transferPersonCount: selectedTransferCount,
          vip: VIPDriverRequested,
          descriptionController: descriptionController,
          bookingOption: widget.bookingOption,
        );
      } else if (widget.bookingOption == BookingOption.both) {
        nextPage = WashOrderPage(
          authToken: widget.authToken,
          bookingOption: widget.bookingOption,
          emailController: widget.emailController,
          licensePlateController: licensePlateController,
          nameController: nameController,
          phoneController: phoneController,
          descriptionController: descriptionController,
          arriveDate: selectedArriveDate,
          leaveDate: selectedLeaveDate,
          transferPersonCount: selectedTransferCount,
          vip: VIPDriverRequested,
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BasePage(
            title: widget.bookingOption == BookingOption.parking
                ? "Számlázás"
                : "Mosás foglalás",
            child: nextPage!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sikertelen Bejelentkezés!')),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    nameController = widget.nameController ?? TextEditingController();
    phoneController = widget.phoneController ?? TextEditingController();
    licensePlateController =
        widget.licensePlateController ?? TextEditingController();
    descriptionController = TextEditingController();

    GetCurrentDate();

    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(nameFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Adja meg felhasználó nevét';
              }
              return null;
            },
            controller: nameController,
            focusNode: nameFocus,
            textInputAction: TextInputAction.next,
            onEditingComplete: () {
              FocusScope.of(context).requestFocus(phoneFocus);
            },
            decoration:
                const InputDecoration(labelText: 'Foglaló személy neve'),
          ),
          TextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Adja meg telefonszámát';
              }
              return null;
            },
            controller: phoneController,
            focusNode: phoneFocus,
            textInputAction: TextInputAction.next,
            onEditingComplete: () {
              FocusScope.of(context).requestFocus(licensePlateFocus);
            },
            decoration: const InputDecoration(labelText: 'Telefonszám'),
          ),
          TextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Adja meg rendszámát';
              }
              return null;
            },
            controller: licensePlateController,
            focusNode: licensePlateFocus,
            textInputAction: TextInputAction.next,
            onEditingComplete: () {
              FocusScope.of(context).requestFocus(datePickerFocus);
            },
            decoration: const InputDecoration(labelText: 'Várható rendszám'),
          ),
          const SizedBox(height: 10),
          Row(children: [
            ElevatedButton(
                onPressed: () {
                  ShowDatePickerDialog();
                  FocusScope.of(context).requestFocus(transferFocus);
                },
                focusNode: datePickerFocus,
                child: const Text("Válassz dátumot")),
            const SizedBox(
              width: 50,
            ),
            Expanded(
              flex: 2,
              child: Text('Parkolási napok száma: $parkingDays'),
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              children: [
                Text("Érkezés: ${format(selectedArriveDate)}"),
                Text("Távozás: ${format(selectedLeaveDate)}"),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          const Text('Parkoló zóna választás'),
          RadioListTile<ParkingZoneOption>(
            title: const Text('Fedett (10 000 Ft/ nap)'),
            value: ParkingZoneOption.premium,
            groupValue: selectedParkingZoneOption,
            onChanged: (ParkingZoneOption? value) {
              setState(() {
                selectedParkingZoneOption = value;
              });
            },
            dense: true,
          ),
          RadioListTile<ParkingZoneOption>(
            title: const Text('Nyitott térköves (5 000 Ft/ nap)'),
            value: ParkingZoneOption.normal,
            groupValue: selectedParkingZoneOption,
            onChanged: (ParkingZoneOption? value) {
              setState(() {
                selectedParkingZoneOption = value;
              });
            },
            dense: true,
          ),
          RadioListTile<ParkingZoneOption>(
            title: const Text('Nyitott murvás (2 000 Ft/ nap)'),
            value: ParkingZoneOption.eco,
            groupValue: selectedParkingZoneOption,
            onChanged: (ParkingZoneOption? value) {
              setState(() {
                selectedParkingZoneOption = value;
              });
            },
            dense: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: selectedTransferCount,
            focusNode: transferFocus,
            onSaved: (value) {
              FocusScope.of(context).requestFocus(VIPFocus);
            },
            decoration: const InputDecoration(
              labelText: 'Transzfer - max 7 személy',
              contentPadding: EdgeInsets.only(bottom: 10),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                selectedTransferCount = value!;
              });
            },
            items: List.generate(7, (index) {
              final number = index + 1;
              return DropdownMenuItem(
                value: number,
                child: Text('$number személy'),
              );
            }),
          ),
          Row(
            children: [
              Checkbox(
                value: VIPDriverRequested,
                focusNode: VIPFocus,
                onChanged: (value) {
                  setState(() {
                    VIPDriverRequested = value!;
                  });
                },
              ),
              const Text(
                  'VIP sofőr igénylése (Hozza viszi az autót a parkolóba)'),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: suitcaseWrappingRequested,
                focusNode: suitcaseWrappingFocus,
                onChanged: (value) {
                  FocusScope.of(context).requestFocus(descriptionFocus);
                  setState(() {
                    suitcaseWrappingRequested = value!;
                  });
                },
              ),
              const Text('Bőrönd fóliázás igénylése'),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Fizetendő összeg: 33 000 Ft'),
          RadioListTile<PaymentOption>(
            title: const Text('Bankkártyával fizetek'),
            value: PaymentOption.card,
            groupValue: selectedPaymentOption,
            onChanged: (PaymentOption? value) {
              setState(() {
                selectedPaymentOption = value;
              });
            },
            dense: true,
          ),
          RadioListTile<PaymentOption>(
            title: const Text(
                'Átutalással fizetek még a parkolás megkezdése előtt 1 nappal'),
            value: PaymentOption.transfer,
            groupValue: selectedPaymentOption,
            onChanged: (PaymentOption? value) {
              setState(() {
                selectedPaymentOption = value;
              });
            },
            dense: true,
          ),
          RadioListTile<PaymentOption>(
            title: const Text('Qvik'),
            value: PaymentOption.qvik,
            groupValue: selectedPaymentOption,
            onChanged: (PaymentOption? value) {
              setState(() {
                selectedPaymentOption = value;
              });
            },
            dense: true,
          ),
          TextField(
            controller: descriptionController,
            focusNode: descriptionFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(nextPageButtonFocus);
            },
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Megjegyzés a recepciónak'),
          ),
          NextPageButton(
            title: widget.bookingOption == BookingOption.washing
                ? "Mosás foglalás"
                : "Parkolás foglalás",
            focusNode: nextPageButtonFocus,
            onPressed: OnNextPageButtonPressed,
          ),
        ],
      ),
    );
  }
}
