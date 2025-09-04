import 'package:airport_test/api_Services/api_service.dart';
import 'package:airport_test/constantWidgets.dart';
import 'package:airport_test/bookingForm/invoiceOptionPage.dart';
import 'package:airport_test/bookingForm/washOrderPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class ParkOrderPage extends StatefulWidget implements PageWithTitle {
  @override
  String get pageTitle => 'Parkolás foglalás';

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
  State<ParkOrderPage> createState() => ParkOrderPageState();
}

class ParkOrderPageState extends State<ParkOrderPage> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController licensePlateController;
  late final TextEditingController descriptionController;
  final ScrollController ParkOptionsScrollController = ScrollController();

  FocusNode nameFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode licensePlateFocus = FocusNode();
  FocusNode descriptionFocus = FocusNode();
  FocusNode datePickerFocus = FocusNode();
  FocusNode VIPFocus = FocusNode();
  FocusNode suitcaseWrappingFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();
  FocusNode transferFocus = FocusNode();

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

  /// Aktuális idő
  DateTime now = DateTime.now();

  // Az enumok / kiválasztható lehetőségek default értékei
  BookingOption selectedBookingOption = BookingOption.parking;
  PaymentOption selectedPaymentOption = PaymentOption.card;

  /// Parkolási zóna cikkszáma
  String? selectedParkingArticleId;

  /// Transzferrel szállított személyek száma
  int transferCount = 1;

  /// Kér-e VIP sofőrt
  bool VIPDriverRequested = false;

  /// Kér-e Bőrönd fóliázást
  bool suitcaseWrappingRequested = false;

  /// Fóliázásra váró bőröndök száma
  int suitcaseWrappingCount = 0;

  /// Érkezési / Távozási dátum
  DateTime? selectedArriveDate, selectedLeaveDate;

  /// Érkezés időpontja
  TimeOfDay? selectedArriveTime;

  /// Parkolással töltött napok száma
  int parkingDays = 0;

  /// A teljes fizetendő összeg
  int totalCost = 0;

  /// Kiválasztott parkolózóna napijegy ára
  /// EZT AUTOMATIKUSAN KÉNE
  int getCostForZone(String articleId) {
    switch (articleId) {
      case "1-95426": // Premium
        return 10000;
      case "1-95427": // Normal
        return 5000;
      case "1-95428": // Eco
        return 2000;
      default:
        return 0;
    }
  }

  /// Teljes összeg kalkulálása, az árakat később adatbázisból fogja előhívni.
  void CalculateTotalCost() {
    int baseCost = 0;

    // Hozzáadjuk a parkolás árát
    baseCost += getCostForZone(selectedParkingArticleId!) * parkingDays;

    // Hozzáadjuk a VIP sofőr árát, amennyiben igénylik
    if (VIPDriverRequested) {
      baseCost += 5000;
    }

    // Hozzáadjuk a bőrönd fóliázás árát, amennyiszer igénylik
    baseCost += suitcaseWrappingCount * 1000;

    setState(() {
      totalCost = baseCost;
    });
  }

  /// A DatePicker még le nem okézott, kiválasztott dátumai.
  /// Ezeken nézi meg hogy megfelelnek-e a feltételeknek,
  /// majd beállítja selectedArriveDate/selectedLeaveDate-nek
  DateTime? tempArriveDate, tempLeaveDate;
  TimeOfDay? tempArriveTime;

  //Teljes időpontos foglalt időpontok
  Map<String, List<DateTime>> fullyBookedDateTimes =
      {}; // parkoló zóna ArticleId -> telített időpont

  // parkoló zóna -> telített időpontok
  Map<String, List<DateTime>> mapBookedDateTimesByZones(
      List<dynamic> reservations, List<dynamic> serviceTemplates) {
    // Kiveszi a zónák kapacitását a Templates-ekből
    final Map<String, int> zoneCapacities = {}; // parkoló zóna -> kapacitás
    for (var template in serviceTemplates) {
      if (template['ParkingServiceType'] != 1) {
        continue; // Csak a parkolásokat nézze
      }
      final String articleId = template['ArticleId'];
      final int capacity = template['ZoneCapacity'] ?? 1;
      zoneCapacities[articleId] = capacity;
    }

    // időpont számláló zónánként
    Map<String, Map<DateTime, int>> counters =
        {}; // parkoló zóna -> (egy időpont hányszor szerepel)

    for (var reservation in reservations) {
      final parkingArticleId = reservation['ParkingArticleId'];

      final arrive = DateTime.parse(reservation['ArriveDate']);
      final leave = DateTime.parse(reservation['LeaveDate']);

      counters.putIfAbsent(parkingArticleId, () => {});

      DateTime current = DateTime(
        arrive.year,
        arrive.month,
        arrive.day,
        arrive.hour,
        arrive.minute - (arrive.minute % 30),
      );

      // végig iterál az érkezéstől a távozás időpontjáig, az időpont számlálót növeli 1-el
      while (current.isBefore(leave)) {
        counters[parkingArticleId]![current] =
            (counters[parkingArticleId]![current] ?? 0) + 1;
        current = current.add(const Duration(minutes: 30));
      }
    }

    /// Parkoló zóna -> telített időpontok
    Map<String, List<DateTime>> fullyBookedDateTimesByZone = {};

    counters.forEach((parkingArticleId, counter) {
      if (parkingArticleId != "") {
        final capacity = zoneCapacities[parkingArticleId];
        fullyBookedDateTimesByZone[parkingArticleId] = counter.entries
            .where((entry) => entry.value >= capacity!)
            .map((entry) => entry.key)
            .toList();
      }
    });

    return fullyBookedDateTimesByZone;
  }

  /// A parkolási napok számát frissíti.
  void UpdateParkingDays() {
    parkingDays = selectedLeaveDate!.difference(selectedArriveDate!).inDays;
    selectedParkingArticleId != null ? CalculateTotalCost() : null;
  }

  Map<String, bool> zoneAvailability = {};

  /// Zónánként ellenőrzi, hogy van-e tiltott időpont az intervallumban
  Map<String, bool> CheckZonesForAvailability() {
    if (tempArriveDate == null || tempLeaveDate == null) {
      return {};
    }

    /// Az érkezési és távozási időpont
    DateTime startDateTime = DateTime(
      selectedArriveDate!.year,
      selectedArriveDate!.month,
      selectedArriveDate!.day,
      selectedArriveTime!.hour,
      selectedArriveTime!.minute,
    );

    DateTime endDateTime = DateTime(
      selectedLeaveDate!.year,
      selectedLeaveDate!.month,
      selectedLeaveDate!.day,
      selectedArriveTime!.hour,
      selectedArriveTime!.minute,
    );

    fullyBookedDateTimes.forEach((parkingArticleId, zoneTimes) {
      final hasForbidden = zoneTimes.any((d) {
        return !d.isBefore(startDateTime) && !d.isAfter(endDateTime);
      });

      // Ha van tiltott időpont -> false, különben true
      zoneAvailability[parkingArticleId] = !hasForbidden;
    });

    return zoneAvailability;
  }

  /// Dátum kiíratásának a formátuma
  String format(DateTime? d) => d != null
      ? "${d.year}. ${d.month.toString().padLeft(2, '0')}. ${d.day.toString().padLeft(2, '0')}. "
          "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}"
      : '-';

  /// Parkoló zónák generálása ServiceTemplates-ek alapján.
  Widget buildParkingZoneSelector({
    required List<dynamic> serviceTemplates,
    required String? selectedParkingArticleId,
    required int parkingDays,
    required Function(String) onZoneSelected,
    required Map<String, bool> zoneAvailability,
  }) {
    final parkingZones =
        serviceTemplates.where((s) => s['ParkingServiceType'] == 1).toList();

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        ParkOptionsScrollController.jumpTo(
          ParkOptionsScrollController.position.pixels - details.delta.dx,
        );
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: ParkOptionsScrollController,
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: parkingZones.map((zone) {
            final String articleId = zone['ArticleId'];
            final isAvailable = zoneAvailability[articleId] ??
                true; // ha nincs benne, akkor true
            final nameParts = (zone['ParkingServiceName'] as String).split(' ');
            final title = nameParts.isNotEmpty
                ? nameParts.last
                : ''; // A név utolsó szava (Pl.:"Prémium")
            final subtitle = nameParts.length > 1
                ? nameParts.sublist(0, nameParts.length - 1).join(' ')
                : ''; // Minden ami előtte van (Pl.:"Fedett napi parkolójegy")
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: ParkingZoneSelectionCard(
                title: title,
                subtitle: subtitle,
                costPerDay: getCostForZone(articleId),
                parkingDays: parkingDays,
                selected: selectedParkingArticleId == articleId,
                onTap: () => onZoneSelected(articleId),
                available: isAvailable,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Időpont választó dialógus a parkolási intervallum kiválasztásához.
  void ShowDatePickerDialog() {
    tempArriveDate = selectedArriveDate;
    tempLeaveDate = selectedLeaveDate;

    List<TimeOfDay> availableSlots = [];

    /// Megadja, hogy melyik időpontos Expansion Tile-ban hovereljük az időpontot.
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

            /// Időpont választó kártyák widgetje
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
                                bool isSelected = tempArriveTime == time;
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
                                        tempArriveTime = time;
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
                      initialSelectedRange:
                          tempArriveDate != null && tempLeaveDate != null
                              ? PickerDateRange(tempArriveDate, tempLeaveDate)
                              : null,
                      selectionMode: DateRangePickerSelectionMode.range,
                      todayHighlightColor: BasePage.defaultColors.primary,
                      startRangeSelectionColor: BasePage.defaultColors.primary,
                      endRangeSelectionColor: BasePage.defaultColors.primary,
                      rangeSelectionColor: BasePage.defaultColors.secondary,
                      enablePastDates: false,
                      maxDate: DateTime.now().add(const Duration(days: 120)),
                      onSelectionChanged: (args) {
                        if (args.value is PickerDateRange) {
                          final start = args.value.startDate;
                          final end = args.value.endDate;

                          setStateDialog(() {
                            tempArriveDate = start;
                            tempLeaveDate = end;

                            if (tempArriveDate != null &&
                                tempLeaveDate != null) {
                              availableSlots = allSlots.where((time) {
                                // Múltbeli időpontokat kiszűrjük
                                if (tempArriveDate != null &&
                                    tempArriveDate!.year == today.year &&
                                    tempArriveDate!.month == today.month &&
                                    tempArriveDate!.day == today.day) {
                                  if (time.hour < currentTime.hour ||
                                      (time.hour == currentTime.hour &&
                                          time.minute <= currentTime.minute)) {
                                    return false;
                                  }
                                }

                                // Ellenőrizzük, hogy az adott időpont foglalt-e (érkezéshez)
                                bool isArriveFullyBookedEverywhere =
                                    fullyBookedDateTimes.values.any(
                                        (zoneTimes) => zoneTimes.any((d) =>
                                            d.year ==
                                                (tempArriveDate?.year ?? 0) &&
                                            d.month ==
                                                (tempArriveDate?.month ?? 0) &&
                                            d.day ==
                                                (tempArriveDate?.day ?? 0) &&
                                            d.hour == time.hour &&
                                            d.minute == time.minute));

                                // Ellenőrizzük, hogy az adott időpont foglalt-e (távozáshoz)
                                bool isLeaveFullyBookedEverywhere =
                                    fullyBookedDateTimes.values.any(
                                        (zoneTimes) => zoneTimes.any((d) =>
                                            d.year ==
                                                (tempLeaveDate?.year ?? 0) &&
                                            d.month ==
                                                (tempLeaveDate?.month ?? 0) &&
                                            d.day ==
                                                (tempLeaveDate?.day ?? 0) &&
                                            d.hour == time.hour &&
                                            d.minute == time.minute));

                                return !isArriveFullyBookedEverywhere &&
                                    !isLeaveFullyBookedEverywhere;
                              }).toList();
                            }
                          });
                        }
                      },
                    ),
                    // Amíg nincs kiválasztva dátum addig ne tudjunk időpontot választani
                    (tempArriveDate != null && tempLeaveDate != null)
                        // Ha nincs szabad időpont, akkor tudatjuk.
                        ? (availableSlots.isNotEmpty
                            ? buildTimeSlotPicker(availableSlots)
                            : Text('Ezen a napon nincs szabad időpont'))
                        : Text(
                            'Válasszon ki érkezési és távozási dátumot, az időpontok megtekintéséhez'),
                    const SizedBox(height: 10),
                    (tempArriveDate != null &&
                            tempLeaveDate != null &&
                            tempArriveTime != null)
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
                                if (tempArriveDate != null &&
                                    tempLeaveDate != null &&
                                    tempArriveTime != null) {
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

                                  final arriveDateTime = DateTime(
                                    tempArriveDate!.year,
                                    tempArriveDate!.month,
                                    tempArriveDate!.day,
                                    tempArriveTime!.hour,
                                    tempArriveTime!.minute,
                                  );

                                  final leaveDateTime = DateTime(
                                    tempLeaveDate!.year,
                                    tempLeaveDate!.month,
                                    tempLeaveDate!.day,
                                    tempArriveTime!.hour,
                                    tempArriveTime!.minute,
                                  );

                                  setState(() {
                                    selectedArriveDate = arriveDateTime;
                                    selectedLeaveDate = leaveDateTime;
                                    selectedArriveTime = tempArriveTime;
                                    CheckZonesForAvailability();
                                    UpdateParkingDays();
                                  });

                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text("Időpont kiválasztása"),
                            ),
                          )
                        : Container(),
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
    if (formKey.currentState!.validate() && selectedParkingArticleId != null) {
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
          transferPersonCount: transferCount,
          vip: VIPDriverRequested,
          descriptionController: descriptionController,
          bookingOption: widget.bookingOption,
          parkingArticleId: selectedParkingArticleId!,
          suitcaseWrappingCount: suitcaseWrappingCount,
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
          transferPersonCount: transferCount,
          vip: VIPDriverRequested,
          parkingCost: totalCost,
          suitcaseWrappingCount: suitcaseWrappingCount,
        );
      }
      if (selectedArriveDate != null && selectedLeaveDate != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BasePage(
              child: nextPage!,
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
        const SnackBar(content: Text('Sikertelen foglalás!')),
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
                hintText: 'Foglaló személy neve',
              ),
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
              const SizedBox(height: 10),
              Row(children: [
                MyIconButton(
                  icon: Icons.calendar_month_rounded,
                  labelText: "Válassz dátumot",
                  focusNode: datePickerFocus,
                  onPressed: () {
                    ShowDatePickerDialog();
                    //CalculateTotalCost();
                    FocusScope.of(context).requestFocus(transferFocus);
                  },
                ),
                const SizedBox(width: 50),
                Column(
                  children: [Text('Érkezés'), Text(format(selectedArriveDate))],
                ),
                const SizedBox(width: 50),
                Column(
                  children: [Text('Távozás'), Text(format(selectedLeaveDate))],
                ),
              ]),
              const SizedBox(height: 8),
              Text('Válassz parkoló zónát - $parkingDays napra',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              serviceTemplates == null
                  ? const Center(child: CircularProgressIndicator())
                  : buildParkingZoneSelector(
                      serviceTemplates: serviceTemplates!,
                      selectedParkingArticleId: selectedParkingArticleId,
                      parkingDays: parkingDays,
                      onZoneSelected: (articleId) {
                        setState(() {
                          selectedParkingArticleId = articleId;
                        });
                        CalculateTotalCost();
                      },
                      zoneAvailability: zoneAvailability),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Transzferre váró személyek száma'),
                  SizedBox(width: 15),
                  IconButton.filled(
                    onPressed: () {
                      setState(() {
                        if (transferCount > 0) {
                          transferCount--;
                        }
                      });
                      CalculateTotalCost();
                    },
                    icon: Icon(Icons.remove,
                        color: transferCount > 0
                            ? Colors.black
                            : Colors.grey.shade400,
                        size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      hoverColor: transferCount > 0
                          ? Colors.grey.shade400
                          : Colors.grey.shade300,
                      minimumSize: const Size(24, 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('$transferCount',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      setState(() {
                        if (transferCount < 7) {
                          transferCount++;
                        }
                      });
                      CalculateTotalCost();
                    },
                    icon: Icon(Icons.add,
                        color: transferCount < 7
                            ? Colors.black
                            : Colors.grey.shade400,
                        size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      hoverColor: transferCount < 7
                          ? Colors.grey.shade400
                          : Colors.grey.shade300,
                      minimumSize: const Size(24, 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  MyCheckBox(
                    value: VIPDriverRequested,
                    focusNode: VIPFocus,
                    onChanged: (value) {
                      setState(() {
                        VIPDriverRequested = value ?? false;
                      });
                      CalculateTotalCost();
                    },
                  ),
                  Text('VIP sofőr igénylése (Hozza viszi az autót a parkolóba)')
                ],
              ),
              Row(
                children: [
                  MyCheckBox(
                    value: suitcaseWrappingRequested,
                    focusNode: suitcaseWrappingFocus,
                    nextFocus: descriptionFocus,
                    onChanged: (value) {
                      setState(() {
                        suitcaseWrappingRequested = value ?? false;
                        if (suitcaseWrappingRequested) {
                          suitcaseWrappingCount = 1;
                        } else {
                          suitcaseWrappingCount = 0;
                        }
                      });
                      CalculateTotalCost();
                    },
                  ),
                  Text('Bőrönd fóliázás igénylése'),
                  suitcaseWrappingRequested
                      ? Row(
                          children: [
                            SizedBox(width: 15),
                            IconButton.filled(
                              onPressed: () {
                                setState(() {
                                  if (suitcaseWrappingCount > 0) {
                                    suitcaseWrappingCount--;
                                    if (suitcaseWrappingCount == 0) {
                                      suitcaseWrappingRequested = false;
                                    }
                                  }
                                });
                                CalculateTotalCost();
                              },
                              icon: Icon(Icons.remove,
                                  color: suitcaseWrappingCount > 0
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                  size: 16),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                hoverColor: suitcaseWrappingCount > 0
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade300,
                                minimumSize: const Size(24, 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('$suitcaseWrappingCount',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: () {
                                setState(() {
                                  if (suitcaseWrappingCount < 9) {
                                    suitcaseWrappingCount++;
                                  }
                                });
                                CalculateTotalCost();
                              },
                              icon: Icon(Icons.add,
                                  color: suitcaseWrappingCount < 9
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                  size: 16),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                hoverColor: suitcaseWrappingCount < 9
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade300,
                                minimumSize: const Size(24, 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        )
                      : Container()
                ],
              ),
              const SizedBox(height: 12),
              selectedBookingOption == BookingOption.parking
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    )
                  : Container(),
              SizedBox(height: 10),
              MyTextFormField(
                controller: descriptionController,
                focusNode: descriptionFocus,
                textInputAction: TextInputAction.next,
                nextFocus: nextPageButtonFocus,
                hintText: 'Megjegyzés a recepciónak',
              ),
              NextPageButton(
                focusNode: nextPageButtonFocus,
                onPressed: OnNextPageButtonPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
