import 'package:airport_test/constantWidgets.dart';
import 'package:airport_test/bookingForm/invoiceOptionPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:airport_test/homePage.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class PerviewExample extends StatefulWidget {
  const PerviewExample({
    super.key,
  });

  @override
  State<PerviewExample> createState() => PerviewExampleState();
}

class PerviewExampleState extends State<PerviewExample> {
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

  /// Lekéri az aktuális dátumot, és default beállítja a selectedWashArriveHour-t erre a dátumra.
  void GetCurrentDate() {
    DateTime now = DateTime.now();

    selectedWashArriveHour = now.hour;

    selectedWashArriveDate =
        DateTime(now.year, now.month, now.day, selectedWashArriveHour, 0)
            .add(const Duration(hours: 1));
    selectedWashLeaveDate =
        selectedWashArriveDate!.add(const Duration(minutes: 30));
  }

  /// Frissíti a telített foglalású napokat, ezekre már nem lehet foglalni.
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
    final filtered = fullyBookedDates.where((bookedDate) {
      return !bookedDate.isBefore(startDateTime) &&
          !bookedDate.isAfter(endDateTime);
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
  // TimeOfDay get selectedWashArriveTime =>
  //     TimeOfDay(hour: selectedWashArriveHour, minute: selectedWashArriveMinute);

  /// Dátum választó pop-up dialog
  void ShowDatePickerDialog() {
    tempWashArriveDate = selectedWashArriveDate;
    tempWashLeaveDate = selectedWashLeaveDate;

    updateBlackoutDays();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // időpont választó kártyák widgetje
            Widget buildTimeSlotPicker() {
              final timeSlots = generateHalfHourTimeSlots();

              return SizedBox(
                height: 200,
                child: GridView.builder(
                  scrollDirection: Axis.vertical,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
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
                      todayHighlightColor: BasePage.defaultColors.primary,
                      selectionColor: BasePage.defaultColors.primary,
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

  @override
  void initState() {
    super.initState();

    // Beállítjuk az előző page-ről a TextFormField-ek controller-eit
    nameController = TextEditingController();
    phoneController = TextEditingController();
    licensePlateController = TextEditingController();
    descriptionController = TextEditingController();

    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(nameFocus);
    });

    GetCurrentDate();
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
                // ElevatedButton(
                //     focusNode: datePickerFocus,
                //     onPressed: ShowDatePickerDialog,
                //     child: const Text("Válassz dátumot")),
                // const SizedBox(
                //   width: 10,
                // ),

                const SizedBox(width: 50),
                Column(
                  children: [
                    Text('Érkezés'),
                    Text(format(selectedWashArriveDate))
                  ],
                ),
                const SizedBox(width: 50),
                Column(
                  children: [
                    Text('Távozás'),
                    Text(format(selectedWashLeaveDate))
                  ],
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
                          setState(() => selectedWashOption = WashOption.basic);
                        },
                      ),
                      WashOptionSelectionCard(
                        title: 'Mosás 2',
                        washCost: 20000,
                        selected: selectedWashOption == WashOption.wash2,
                        onTap: () {
                          setState(() => selectedWashOption = WashOption.wash2);
                        },
                      ),
                      WashOptionSelectionCard(
                        title: 'Mosás 3',
                        washCost: 30000,
                        selected: selectedWashOption == WashOption.wash3,
                        onTap: () {
                          setState(() => selectedWashOption = WashOption.wash3);
                        },
                      ),
                      WashOptionSelectionCard(
                        title: 'Mosás 4',
                        washCost: 40000,
                        selected: selectedWashOption == WashOption.wash4,
                        onTap: () {
                          setState(() => selectedWashOption = WashOption.wash4);
                        },
                      ),
                      WashOptionSelectionCard(
                        title: 'Szupermosás porszívóval',
                        washCost: 50000,
                        selected: selectedWashOption == WashOption.superWash,
                        onTap: () {
                          setState(
                              () => selectedWashOption = WashOption.superWash);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Fizetendő összeg: 33 000 Ft'),
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
              MyTextFormField(
                focusNode: descriptionFocus,
                controller: descriptionController,
                hintText: 'Megjegyzés a recepciónak',
                nextFocus: nextPageButtonFocus,
              ),
              NextPageButton(
                focusNode: nextPageButtonFocus,
                title: "Számlázás",
                nextPage: HomePage(),
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
