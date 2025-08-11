// ignore_for_file: file_names, non_constant_identifier_names

import 'package:airport_test/basePage.dart';
import 'package:airport_test/bookingForm/invoiceOptionPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class WashOrderPage extends StatefulWidget {
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
  const WashOrderPage({
    super.key,
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
  });

  @override
  State<WashOrderPage> createState() => _WashOrderPageState();
}

class _WashOrderPageState extends State<WashOrderPage> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController licensePlateController;
  late final TextEditingController descriptionController;

  FocusNode nameFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode licensePlateFocus = FocusNode();
  FocusNode datePickerFocus = FocusNode();
  FocusNode descriptionFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();

  WashOption? selectedWashOption = WashOption.basic;
  PaymentOption? selectedPaymentOption = PaymentOption.card;

  /// Aktuális idő
  DateTime now = DateTime.now();

  /// Érkezési / Távozási dátum
  late DateTime? selectedWashArriveDate, selectedWashLeaveDate;
  late int selectedWashArriveHour;
  int selectedWashArriveMinute = 0;

  DateTime? tempWashArriveDate, tempWashLeaveDate;

  //Teljes időpont pontos foglalt időpontok
  List<DateTime> fullyBookedDates = [
    DateTime(2025, 8, 10, 8, 0),
    DateTime(2025, 8, 15, 15, 30),
    DateTime(2025, 9, 1, 18, 30),
  ];

  // Csak a blackout napok (dátumok)
  List<DateTime> blackoutDays = [];

  int hoveredIndex = -1;

  void GetCurrentDate() {
    DateTime now = DateTime.now();

    /// Nem jó mert nem vált dátumot
    if (now.hour < 23) {
      selectedWashArriveHour = now.hour + 1;
    } else {
      selectedWashArriveHour = 0;
    }

    selectedWashArriveDate =
        DateTime(now.year, now.month, now.day, selectedWashArriveHour, 0);
    selectedWashLeaveDate =
        selectedWashArriveDate!.add(const Duration(minutes: 30));
  }

  void updateBlackoutDays() {
    if (tempWashArriveDate == null) {
      blackoutDays = [];
      return;
    }

    //Az érkezési és távozási időpont az óra+perc alapján
    DateTime startDateTime = DateTime(
      tempWashArriveDate!.year,
      tempWashArriveDate!.month,
      tempWashArriveDate!.day,
      selectedWashArriveHour,
      selectedWashArriveMinute,
    );

    DateTime endDateTime = DateTime(
      tempWashLeaveDate!.year,
      tempWashLeaveDate!.month,
      tempWashLeaveDate!.day,
      selectedWashArriveHour,
      selectedWashArriveMinute,
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

  /// Az aktuálisan kiválasztott időpont (óra+perc) TimeOfDay típusként
  TimeOfDay get selectedWashArriveTime =>
      TimeOfDay(hour: selectedWashArriveHour, minute: selectedWashArriveMinute);

  void ShowDatePickerDialog() {
    tempWashArriveDate = selectedWashArriveDate;
    tempWashLeaveDate = selectedWashLeaveDate;

    updateBlackoutDays();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // időpont választó kártyák widgetje, hogy setStateDialog használjon
            Widget buildTimeSlotPicker() {
              final timeSlots = generateHalfHourTimeSlots();

              return SizedBox(
                height: 200, // Több sor miatt megnövelve
                child: GridView.builder(
                  scrollDirection: Axis.vertical,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 kártya egy sorban
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: timeSlots.length,
                  itemBuilder: (context, index) {
                    final time = timeSlots[index];

                    bool isBooked = fullyBookedDates.any((d) =>
                        d.year == (tempWashArriveDate?.year ?? 0) &&
                        d.month == (tempWashArriveDate?.month ?? 0) &&
                        d.day == (tempWashArriveDate?.day ?? 0) &&
                        d.hour == time.hour &&
                        d.minute == time.minute);

                    bool isSelected = selectedWashArriveHour == time.hour &&
                        selectedWashArriveMinute == time.minute;

                    bool isHovered = hoveredIndex == index;

                    Color bgColor;
                    if (isBooked) {
                      bgColor = Colors.red[300]!;
                    } else if (isSelected) {
                      bgColor = Colors.deepPurple;
                    } else if (isHovered) {
                      bgColor = Colors.grey[400]!;
                    } else {
                      bgColor = Colors.grey[200]!;
                    }

                    return MouseRegion(
                      onEnter: (_) {
                        setStateDialog(() {
                          hoveredIndex = index;
                        });
                      },
                      onExit: (_) {
                        setStateDialog(() {
                          hoveredIndex = -1;
                        });
                      },
                      cursor: isBooked
                          ? SystemMouseCursors.basic
                          : SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: isBooked
                            ? null
                            : () {
                                setStateDialog(() {
                                  selectedWashArriveHour = time.hour;
                                  selectedWashArriveMinute = time.minute;
                                  updateBlackoutDays();
                                });
                              },
                        child: Card(
                          color: bgColor,
                          child: Center(
                            child: Text(
                              time.format(context),
                              style: TextStyle(
                                color: isBooked || isSelected
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
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 600,
                height: 600,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SfDateRangePicker(
                      selectionMode: DateRangePickerSelectionMode.single,
                      showNavigationArrow: true,
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
                      onSelectionChanged: (args) {
                        if (args.value is DateTime) {
                          setStateDialog(() {
                            tempWashArriveDate = args.value;
                            updateBlackoutDays();
                          });
                        }
                      },
                    ),
                    const Text("Érkezési idő:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    buildTimeSlotPicker(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (tempWashArriveDate != null) {
                              final arriveDateTime = DateTime(
                                tempWashArriveDate!.year,
                                tempWashArriveDate!.month,
                                tempWashArriveDate!.day,
                                selectedWashArriveHour,
                                selectedWashArriveMinute,
                              );

                              bool containsBlackout = fullyBookedDates.any((b) {
                                return b.isAtSameMomentAs(arriveDateTime);
                              });

                              if (containsBlackout) {
                                ShowError("A kiválasztott időpont foglalt!");
                                return;
                              }

                              setState(() {
                                selectedWashArriveDate = arriveDateTime;
                                selectedWashLeaveDate = arriveDateTime
                                    .add(const Duration(minutes: 30));
                              });

                              Navigator.of(context).pop();
                            } else {
                              ShowError("Kérlek válassz ki egy dátumot!");
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

  @override
  void initState() {
    super.initState();

    nameController = widget.nameController ?? TextEditingController();
    phoneController = widget.phoneController ?? TextEditingController();
    licensePlateController =
        widget.licensePlateController ?? TextEditingController();
    descriptionController =
        widget.descriptionController ?? TextEditingController();

    GetCurrentDate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          focusNode: nameFocus,
          decoration: const InputDecoration(labelText: 'Foglaló személy neve'),
        ),
        TextField(
          controller: phoneController,
          focusNode: phoneFocus,
          decoration: const InputDecoration(labelText: 'Telefonszám'),
        ),
        TextField(
          controller: licensePlateController,
          focusNode: licensePlateFocus,
          decoration: const InputDecoration(labelText: 'Várható rendszám'),
        ),
        const SizedBox(height: 16),
        Row(children: [
          ElevatedButton(
              focusNode: datePickerFocus,
              onPressed: ShowDatePickerDialog,
              child: const Text("Válassz dátumot")),
          const SizedBox(
            width: 10,
          ),
          Column(
            children: [
              Text("Érkezés: ${format(selectedWashArriveDate)}"),
              Text("Távozás: ${format(selectedWashLeaveDate)}"),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        const Text('Válassza ki a kívánt programot'),
        RadioListTile<WashOption>(
          title: const Text('Alapmosás - 10 000 Ft'),
          value: WashOption.basic,
          groupValue: selectedWashOption,
          onChanged: (WashOption? value) {
            setState(() {
              selectedWashOption = value;
            });
          },
          dense: true,
        ),
        RadioListTile<WashOption>(
          title: const Text('Mosás 2 - 20 000 Ft'),
          value: WashOption.wash2,
          groupValue: selectedWashOption,
          onChanged: (WashOption? value) {
            setState(() {
              selectedWashOption = value;
            });
          },
          dense: true,
        ),
        RadioListTile<WashOption>(
          title: const Text('Mosás 3 - 30 000 Ft'),
          value: WashOption.wash3,
          groupValue: selectedWashOption,
          onChanged: (WashOption? value) {
            setState(() {
              selectedWashOption = value;
            });
          },
          dense: true,
        ),
        RadioListTile<WashOption>(
          title: const Text('Mosás 4 - 40 000 Ft'),
          value: WashOption.wash4,
          groupValue: selectedWashOption,
          onChanged: (WashOption? value) {
            setState(() {
              selectedWashOption = value;
            });
          },
          dense: true,
        ),
        RadioListTile<WashOption>(
          title: const Text('Szupermosás porszívóval - 50 000 Ft'),
          value: WashOption.superWash,
          groupValue: selectedWashOption,
          onChanged: (WashOption? value) {
            setState(() {
              selectedWashOption = value;
            });
          },
          dense: true,
        ),
        const SizedBox(height: 10),
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
          focusNode: descriptionFocus,
          controller: descriptionController,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Megjegyzés a recepciónak'),
        ),
        NextPageButton(
            focusNode: nextPageButtonFocus,
            title: "Számlázás",
            nextPage: InvoiceOptionPage(
              nameController: nameController,
              emailController: widget.emailController,
              phoneController: phoneController,
              licensePlateController: licensePlateController,
              arriveDate: widget.arriveDate,
              leaveDate: widget.leaveDate,
              transferPersonCount: widget.transferPersonCount,
              washDateTime: selectedWashArriveDate,
              vip: widget.vip,
              descriptionController: descriptionController,
              bookingOption: widget.bookingOption,
            ))
      ],
    );
  }
}

// Félórás időpontok generálása 7:00 - 21:00 között
List<TimeOfDay> generateHalfHourTimeSlots() {
  List<TimeOfDay> slots = [];
  for (int hour = 0; hour <= 23; hour++) {
    slots.add(TimeOfDay(hour: hour, minute: 0));
    slots.add(TimeOfDay(hour: hour, minute: 30));
  }
  return slots;
}
