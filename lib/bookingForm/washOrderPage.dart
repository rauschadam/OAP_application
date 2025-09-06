import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/constant_widgets.dart';
import 'package:airport_test/bookingForm/invoiceOptionPage.dart';
import 'package:airport_test/constants/constant_functions.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class WashOrderPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Mosás foglalás';

  final String? authToken;
  final BookingOption bookingOption;
  final bool alreadyRegistered;
  final bool withoutRegistration;
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
  final int? suitcaseWrappingCount;
  final String? parkingArticleId;
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
      this.parkingCost,
      this.suitcaseWrappingCount,
      this.parkingArticleId,
      required this.alreadyRegistered,
      required this.withoutRegistration});

  @override
  State<WashOrderPage> createState() => WashOrderPageState();
}

class WashOrderPageState extends State<WashOrderPage> {
  final formKey = GlobalKey<FormState>();

  // initState-ben átadjuk nekik az előző page-en megadott adatokat
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

  /// Aktuális idő
  DateTime now = DateTime.now();

  /// Érkezési / Távozási dátum
  DateTime? selectedWashDate;
  TimeOfDay? selectedWashTime;

  /// Ideiglenes dátum a datePicker-ben, ellenőrzés -> selectedWashDate
  DateTime? tempWashDate;

  /// Ideiglenes időpont a datePicker-ben, ellenőrzés -> selectedWashTime
  TimeOfDay? tempWashTime;

  /// Parkolási zóna cikkszáma
  String? selectedCarWashArticleId;

  // Default értékek
  PaymentOption selectedPaymentOption = PaymentOption.card;

  /// Lekérdezett foglalások
  List<dynamic>? reservations;

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

  /// Lekérdezett szolgáltatások
  List<dynamic>? serviceTemplates;

  /// Szolgáltatások lekérdezése
  Future<void> fetchServiceTemplates() async {
    final api = ApiService();
    final data = await api.getServiceTemplates(widget.authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        serviceTemplates = data;
        fullyBookedDateTimes =
            mapBookedDateTimesByZones(reservations!, serviceTemplates!);
      });
    }
  }

  //Teljes időpontos foglalt időpontok
  Map<String, List<DateTime>> fullyBookedDateTimes =
      {}; // parkoló zóna ArticleId -> telített időpont

  // Mosó zóna -> telített időpontok
  Map<String, List<DateTime>> mapBookedDateTimesByZones(
      List<dynamic> reservations, List<dynamic> serviceTemplates) {
    // Kiveszi a zónák kapacitását a Templates-ekből
    final Map<String, int> zoneCapacities = {}; // parkoló zóna -> kapacitás
    for (var template in serviceTemplates) {
      if (template['ParkingServiceType'] != 2) {
        continue; // Csak a mosásokat nézze
      }
      final String articleId = template['ArticleId'];
      final int capacity = template['ZoneCapacity'] ?? 1;
      zoneCapacities[articleId] = capacity;
    }

    // időpont számláló zónánként
    Map<String, Map<DateTime, int>> counters =
        {}; // parkoló zóna -> (egy időpont hányszor szerepel)

    for (var reservation in reservations) {
      final carWashArticleId = reservation['CarWashArticleId'];

      if (carWashArticleId == null) continue;

      final washDateTime = DateTime.parse(reservation['WashDateTime']);

      counters.putIfAbsent(carWashArticleId, () => {});

      DateTime current = DateTime(
        washDateTime.year,
        washDateTime.month,
        washDateTime.day,
        washDateTime.hour,
        washDateTime.minute - (washDateTime.minute % 30),
      );

      // +1 foglalás az adott időpontra
      counters[carWashArticleId]![current] =
          (counters[carWashArticleId]![current] ?? 0) + 1;
    }

    /// Parkoló zóna -> telített időpontok
    Map<String, List<DateTime>> fullyBookedDateTimesByZone = {};

    counters.forEach((washingArticleId, counter) {
      if (washingArticleId != "") {
        final capacity = zoneCapacities[washingArticleId];
        fullyBookedDateTimesByZone[washingArticleId] = counter.entries
            .where((entry) => entry.value >= capacity!)
            .map((entry) => entry.key)
            .toList();
      }
    });

    return fullyBookedDateTimesByZone;
  }

  /// A teljes fizetendő összeg
  int totalCost = 0;

  /// Kiválasztott parkolózóna napijegy ára
  /// EZT AUTOMATIKUSAN KÉNE
  int getCostForZone(String articleId) {
    switch (articleId) {
      case "1-95431":
        return 2000;
      case "1-95432":
        return 4000;
      case "1-95433":
        return 6000;
      case "1-95434":
        return 8000;
      case "1-95435":
        return 10000;
      default:
        return 0;
    }
  }

  /// Teljes összeg kalkulálása, az árakat később adatbázisból fogja előhívni.
  void CalculateTotalCost() {
    int baseCost =
        widget.bookingOption == BookingOption.both ? widget.parkingCost! : 0;

    // Hozzáadjuk a parkolás árát
    if (selectedCarWashArticleId != null) {
      baseCost += getCostForZone(selectedCarWashArticleId!);
    }

    setState(() {
      totalCost = baseCost;
    });
  }

  Map<String, bool> zoneAvailability = {};

  /// Zónánként ellenőrzi, hogy van-e tiltott időpont az intervallumban
  Map<String, bool> CheckZonesForAvailability() {
    if (tempWashDate == null) {
      return {};
    }

    /// Az érkezési és távozási időpont
    DateTime washDateTime = DateTime(
      selectedWashDate!.year,
      selectedWashDate!.month,
      selectedWashDate!.day,
      selectedWashTime!.hour,
      selectedWashTime!.minute,
    );

    fullyBookedDateTimes.forEach((carWashArticleId, zoneTimes) {
      final hasForbidden = zoneTimes.any((d) {
        return d == washDateTime;
      });

      // Ha van tiltott időpont -> false, különben true
      zoneAvailability[carWashArticleId] = !hasForbidden;

      // Ha a kijelölt zóna foglalt lett, kinullázzuk
      if (carWashArticleId == selectedCarWashArticleId &&
          !zoneAvailability[carWashArticleId]!) {
        selectedCarWashArticleId = null;
      }
    });

    return zoneAvailability;
  }

  /// Dátum kiíratásának a formátuma
  String format(DateTime? d) => d != null
      ? "${d.year}. ${d.month.toString().padLeft(2, '0')}. ${d.day.toString().padLeft(2, '0')}. "
          "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}"
      : '-';

  /// Parkoló zónák generálása ServiceTemplates-ek alapján.
  Widget buildCarWashZoneSelector({
    required List<dynamic> serviceTemplates,
    required String? selectedCarWashArticleId,
    required Function(String) onZoneSelected,
    required Map<String, bool> zoneAvailability,
  }) {
    final washingZones = serviceTemplates
        .where((s) => s['ParkingServiceType'] == 2)
        .toList(); // Csak a mosás zónák

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        WashOptionsScrollController.jumpTo(
          WashOptionsScrollController.position.pixels - details.delta.dx,
        );
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: WashOptionsScrollController,
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: washingZones.map((zone) {
            final String articleId = zone['ArticleId'];
            final isAvailable = zoneAvailability[articleId] ??
                true; // ha nincs benne, akkor true
            final String title = zone['ParkingServiceName'];

            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: CarWashSelectionCard(
                title: title,
                washCost: getCostForZone(articleId),
                selected: selectedCarWashArticleId == articleId,
                onTap: () => onZoneSelected(articleId),
                available: isAvailable,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Dátum választó pop-up dialog
  void ShowDatePickerDialog() {
    tempWashDate = selectedWashDate;

    List<TimeOfDay> availableSlots = [];

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

                            availableSlots = allSlots.where((time) {
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

                              bool isBooked = fullyBookedDateTimes.values.any(
                                  (listOfDates) => listOfDates.any((d) =>
                                      d.year == (tempWashDate?.year ?? 0) &&
                                      d.month == (tempWashDate?.month ?? 0) &&
                                      d.day == (tempWashDate?.day ?? 0) &&
                                      d.hour == time.hour &&
                                      d.minute == time.minute));

                              return !isBooked;
                            }).toList();
                          });
                        }
                      },
                    ),
                    tempWashDate != null
                        ? buildTimeSlotPicker(availableSlots)
                        : Text(
                            'Válasszon ki mosási dátumot, az időpontok megtekintéséhez'),
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
                carWashArticleId: selectedCarWashArticleId,
                suitcaseWrappingCount: widget.suitcaseWrappingCount,
                parkingArticleId: widget.parkingArticleId,
                alreadyRegistered: widget.alreadyRegistered,
                withoutRegistration: widget.withoutRegistration,
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Válassz ki időpontot!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sikertelen foglalás!')),
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

    fetchReservations();
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
                  } else if (phoneController.text.length < 10) {
                    return 'Hibás telefonszám';
                  }
                  return null;
                },
                controller: phoneController,
                focusNode: phoneFocus,
                textInputAction: TextInputAction.next,
                nextFocus: licensePlateFocus,
                hintText: 'Telefonszám',
                selectedTextFormFieldType: MyTextFormFieldType.phone,
              ),
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
                hintText: 'Várható rendszám',
                selectedTextFormFieldType: MyTextFormFieldType.licensePlate,
              ),
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
              serviceTemplates == null
                  ? const Center(child: CircularProgressIndicator())
                  : buildCarWashZoneSelector(
                      serviceTemplates: serviceTemplates!,
                      selectedCarWashArticleId: selectedCarWashArticleId,
                      onZoneSelected: (articleId) {
                        setState(() {
                          selectedCarWashArticleId = articleId;
                        });
                        CalculateTotalCost();
                      },
                      zoneAvailability: zoneAvailability),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  text: widget.bookingOption == BookingOption.both
                      ? 'Teljes összeg: '
                      : 'Fizetendő összeg: ',
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
                onEditingComplete: OnNextPageButtonPressed,
              ),
              NextPageButton(
                focusNode: nextPageButtonFocus,
                onPressed: OnNextPageButtonPressed,
              )
            ],
          ),
        ),
      ),
    );
  }
}
