import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/Pages/reservationForm/invoiceOptionPage.dart';
import 'package:airport_test/Pages/reservationForm/washOrderPage.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_checkbox.dart';
import 'package:airport_test/constants/widgets/my_icon_button.dart';
import 'package:airport_test/constants/widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/widgets/my_date_range_picker_dialog.dart';
import 'package:airport_test/constants/widgets/my_text_form_field.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/widgets/parking_zone_selection_card.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ParkOrderPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Parkolás foglalás';

  final String? authToken;
  final BookingOption bookingOption;
  final bool alreadyRegistered;
  final bool withoutRegistration;
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
      this.licensePlateController,
      required this.alreadyRegistered,
      required this.withoutRegistration});

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

  /// Aktuális idő
  DateTime now = DateTime.now();

  // Az enumok / kiválasztható lehetőségek default értékei
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

  /// A DatePicker még le nem okézott, ott kiválasztott dátumai.
  /// Ezeken nézi meg hogy megfelelnek-e a feltételeknek,
  /// majd beállítja selectedArriveDate/selectedLeaveDate/selectedArriveDate-nek
  DateTime? tempArriveDate, tempLeaveDate;
  TimeOfDay? tempArriveTime;

  /// A megadott napon elérhető időpontok
  List<TimeOfDay> availableSlots = [];

  /// Parkolással töltött napok száma
  int parkingDays = 0;

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
    if (selectedParkingArticleId != null) {
      baseCost += getCostForZone(selectedParkingArticleId!) * parkingDays;
    }

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

      // Ha a kijelölt zóna foglalt lett, kinullázzuk
      if (parkingArticleId == selectedParkingArticleId &&
          !zoneAvailability[parkingArticleId]!) {
        selectedParkingArticleId = null;
      }
    });

    return zoneAvailability;
  }

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
        padding: EdgeInsets.all(AppPadding.small),
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
              padding: const EdgeInsets.all(AppPadding.extraSmall),
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
  void showDatePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => MyDateRangePickerDialog(
        initialArriveDate: selectedArriveDate,
        initialLeaveDate: selectedLeaveDate,
        initialArriveTime: selectedArriveTime,
        fullyBookedDateTimes: fullyBookedDateTimes,
        onDateSelected: (arriveDate, leaveDate, arriveTime) {
          setState(() {
            selectedArriveDate = arriveDate;
            selectedLeaveDate = leaveDate;
            selectedArriveTime = arriveTime;
            CheckZonesForAvailability();
            UpdateParkingDays();
          });
        },
      ),
    ).then((_) {
      // A dialógus bezárása után fókusz átadása
      FocusScope.of(context).requestFocus(transferFocus);
    });
  }

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      if (selectedParkingArticleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Válasszon parkoló zónát')),
        );
      } else {
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
            alreadyRegistered: widget.alreadyRegistered,
            withoutRegistration: widget.withoutRegistration,
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
            alreadyRegistered: widget.alreadyRegistered,
            withoutRegistration: widget.withoutRegistration,
            parkingArticleId: selectedParkingArticleId,
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
            const SnackBar(
                content: Text('Válassz ki Parkolási intervallumot!')),
          );
        }
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
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTextFormFields(),
              buildDatePickerRow(),
              buildParkZoneSelector(),
              buildCheckBoxes(),
              buildPaymentMethods(),
              MyTextFormField(
                controller: descriptionController,
                focusNode: descriptionFocus,
                textInputAction: TextInputAction.next,
                nextFocus: nextPageButtonFocus,
                hintText: 'Megjegyzés a recepciónak',
                onEditingComplete: OnNextPageButtonPressed,
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

  Widget buildTextFormFields() {
    final double sizedBoxHeight = 10;
    return Column(
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
        SizedBox(height: sizedBoxHeight),
        MyTextFormField(
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Adja meg telefonszámát';
            } else if (value.length < 10) {
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
        SizedBox(height: sizedBoxHeight),
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
        SizedBox(height: sizedBoxHeight),
      ],
    );
  }

  Widget buildDatePickerRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyIconButton(
              icon: Icons.calendar_month_rounded,
              labelText: "Válassz dátumot",
              focusNode: datePickerFocus,
              onPressed: showDatePickerDialog,
            ),
            if (!isMobileScreen!)
              MyIconButton(
                textColor: BasePage.defaultColors.primary,
                backgroundColor: BasePage.defaultColors.background,
                icon: Icons.flight_takeoff_rounded,
                labelText:
                    "Érkezés: ${selectedArriveDate != null ? DateFormat('yyyy.MM.dd HH:mm').format(selectedArriveDate!) : "-"}",
                onPressed: showDatePickerDialog,
              ),
            if (!isMobileScreen!)
              MyIconButton(
                textColor: BasePage.defaultColors.primary,
                backgroundColor: BasePage.defaultColors.background,
                icon: Icons.flight_land_rounded,
                labelText:
                    "Távozás: ${selectedLeaveDate != null ? DateFormat('yyyy.MM.dd HH:mm').format(selectedLeaveDate!) : "-"}",
                onPressed: showDatePickerDialog,
              ),
          ],
        ),
        // if (Responsive.isMobile(context)) SizedBox(height: AppPadding.medium),
        // if (Responsive.isMobile(context) &&
        //     selectedArriveDate != null &&
        //     selectedLeaveDate != null)
        //   Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       MyIconButton(
        //         textColor: BasePage.defaultColors.primary,
        //         backgroundColor: BasePage.defaultColors.background,
        //         icon: Icons.flight_takeoff_rounded,
        //         labelText:
        //             "Érkezés: ${selectedArriveDate != null ? DateFormat('yyyy.MM.dd HH:mm').format(selectedArriveDate!) : "-"}",
        //         onPressed: showDatePickerDialog,
        //       ),
        //       MyIconButton(
        //         textColor: BasePage.defaultColors.primary,
        //         backgroundColor: BasePage.defaultColors.background,
        //         icon: Icons.flight_land_rounded,
        //         labelText:
        //             "Távozás: ${selectedLeaveDate != null ? DateFormat('yyyy.MM.dd HH:mm').format(selectedLeaveDate!) : "-"}",
        //         onPressed: showDatePickerDialog,
        //       ),
        //     ],
        //   )
      ],
    );
  }

  Widget buildParkZoneSelector() {
    return Column(
      children: [
        const SizedBox(height: AppPadding.small),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Válassz parkoló zónát - $parkingDays napra',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
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
        const SizedBox(height: AppPadding.medium),
      ],
    );
  }

  Widget buildCheckBoxes() {
    final double iconBorderRadius = 4;
    return Column(
      children: [
        Row(
          children: [
            Text('Transzferre váró személyek száma'),
            SizedBox(width: isMobileScreen! ? 0 : 16),
            IconButton.filled(
              onPressed: () {
                setState(() {
                  if (transferCount > 1) {
                    transferCount--;
                  }
                });
                CalculateTotalCost();
              },
              icon: Icon(Icons.remove,
                  color:
                      transferCount > 1 ? Colors.black : Colors.grey.shade400,
                  size: 16),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                hoverColor: transferCount > 1
                    ? Colors.grey.shade400
                    : Colors.grey.shade300,
                minimumSize: const Size(24, 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(width: isMobileScreen! ? 0 : 8),
            Text('$transferCount',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: isMobileScreen! ? 0 : 8),
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
                  color:
                      transferCount < 7 ? Colors.black : Colors.grey.shade400,
                  size: 16),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                hoverColor: transferCount < 7
                    ? Colors.grey.shade400
                    : Colors.grey.shade300,
                minimumSize: const Size(24, 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(iconBorderRadius),
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
              //nextFocus: descriptionFocus,
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
                      SizedBox(width: isMobileScreen! ? 0 : 16),
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
                            borderRadius:
                                BorderRadius.circular(iconBorderRadius),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      SizedBox(width: isMobileScreen! ? 0 : 8),
                      Text('$suitcaseWrappingCount',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: isMobileScreen! ? 0 : 8),
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
                            borderRadius:
                                BorderRadius.circular(iconBorderRadius),
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
      ],
    );
  }

  Widget buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: widget.bookingOption == BookingOption.parking
                ? 'Fizetendő összeg: '
                : 'A parkolás ára: ',
            style: TextStyle(fontSize: 16),
            children: [
              TextSpan(
                text: '${NumberFormat('#,###', 'hu_HU').format(totalCost)} Ft',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        widget.bookingOption == BookingOption.parking
            ? Column(
                children: [
                  MyRadioListTile<PaymentOption>(
                    title: 'Bankkártya',
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
                    title: 'Átutalás',
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
      ],
    );
  }
}
