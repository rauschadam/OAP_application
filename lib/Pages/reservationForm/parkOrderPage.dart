import 'package:airport_test/Pages/reservationForm/invoiceOptionPage.dart';
import 'package:airport_test/Pages/reservationForm/washOrderPage.dart';
import 'package:airport_test/api_services/api_classes/reservation.dart';
import 'package:airport_test/api_services/api_classes/user_data.dart';
import 'package:airport_test/constants/formatters.dart';
import 'package:airport_test/constants/functions/occupancy_colors.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/api_classes/parking_zone.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_checkbox.dart';
import 'package:airport_test/constants/widgets/my_icon_button.dart';
import 'package:airport_test/constants/widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/dialogs/my_date_range_picker_dialog.dart';
import 'package:airport_test/constants/widgets/my_text_form_field.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/widgets/parking_zone_selection_card.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ParkOrderPage extends ConsumerStatefulWidget {
  const ParkOrderPage({super.key});

  @override
  ConsumerState<ParkOrderPage> createState() => ParkOrderPageState();
}

class ParkOrderPageState extends ConsumerState<ParkOrderPage> {
  final formKey = GlobalKey<FormState>();

  // --- KONTROLLEREK ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController licensePlateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final ScrollController ParkOptionsScrollController = ScrollController();

  // --- FOCUSNODE ---
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

  /// Kiválasztott fizetési mód Id-ja
  String selectedPayTypeId = PayTypes.first.payTypeId;

  /// Kiválasztott parkolási zóna cikkszáma
  String? selectedParkingArticleId;

  /// Transzferrel szállított személyek száma
  int transferCount = 1;

  /// Kér-e VIP sofőrt
  bool VIPDriverRequested = false;

  /// Kér-e Bőrönd fóliázást
  bool suitcaseWrappingRequested = false;

  /// Fóliázásra váró bőröndök száma
  int suitcaseWrappingCount = 0;

  /// Érkezési / Távozási dátum (óra perccel)
  DateTime? selectedArriveDate, selectedLeaveDate;

  /// Érkezés időpontja
  TimeOfDay? selectedArriveTime;

  /// A megadott napon elérhető időpontok
  List<TimeOfDay> availableSlots = [];

  /// Parkolással töltött napok száma
  int parkingDays = 0;

  /// Lekérdezett foglalások
  List<dynamic>? reservations;

  /// Parkoló zóna árak
  List<dynamic>? parkingPrices;

  /// Parkoló zónák
  List<ParkingZone> parkingZones = [];

  /// A teljes fizetendő összeg
  int totalCost = 0;

  /// Foglalások és szolgáltatások lekérdezése
  Future<void> fetchData() async {
    final api = ApiService();
    // Adatok olvasása a Riverpod állapotból
    final reservationState = ref.read(reservationProvider);
    final String personId = reservationState.personId;

    // Felhasználói adatok lekérése a `personId` alapján
    final UserData? userData = await api.getUserData(context, personId);

    if (userData != null) {
      setState(() {
        // Controllerek feltöltése
        nameController.text = userData.person_Name;
        phoneController.text = formatPhone(userData.phone);
        licensePlateController.text = reservationState.licensePlate;
        descriptionController.text = reservationState.description;
      });
    }

    // Állapot betöltése a Riverpodból
    setState(() {
      selectedArriveDate = reservationState.arriveDate;
      selectedLeaveDate = reservationState.leaveDate;
      selectedArriveTime = selectedArriveDate != null
          ? TimeOfDay(
              hour: selectedArriveDate!.hour,
              minute: selectedArriveDate!.minute)
          : null;
      selectedParkingArticleId = reservationState.parkingArticleId;
      transferCount = reservationState.transferPersonCount;
      VIPDriverRequested = reservationState.vip;
      suitcaseWrappingCount = reservationState.suitcaseWrappingCount;
      suitcaseWrappingRequested = suitcaseWrappingCount > 0;
      selectedPayTypeId = reservationState.payTypeId.isNotEmpty
          ? reservationState.payTypeId
          : PayTypes.first.payTypeId;

      if (selectedArriveDate != null && selectedLeaveDate != null) {
        UpdateParkingDays();
        fetchParkingPrices();
      }
    });
  }

  /// Parkoló zóna árak lekérdezése
  Future<void> fetchParkingPrices() async {
    if (selectedArriveDate == null ||
        selectedLeaveDate == null ||
        selectedArriveTime == null) {
      return;
    }
    final DateTime beginInterval = selectedArriveDate!;
    final DateTime endInterval = selectedLeaveDate!;

    final api = ApiService();
    final reservationState = ref.read(reservationProvider);
    // Parkoló zóna árak lekérdezése
    final parkingPriceData = await api.getParkingPrices(
      context,
      ReceptionistToken,
      beginInterval,
      endInterval,
      reservationState.partnerId,
      selectedPayTypeId,
    );
    if (parkingPriceData != null && ServiceTemplates.isNotEmpty) {
      setState(() {
        parkingPrices = parkingPriceData;
        parkingZones = mapParkingZones(parkingPriceData);
        checkIfZoneIsStillAvailable();
        CalculateTotalCost();
      });
    }
  }

  /// Ha a korábban kiválasztott parkolózóna már nincs benne a friss listában, akkor töröljük a kiválasztást
  void checkIfZoneIsStillAvailable() {
    // Ha a kiválasztott zóna betelt, töröljük a választást
    if (selectedParkingArticleId != null) {
      // Megnézzük, létezik-e még a listában
      final zoneExists = parkingZones.any(
        (z) => z.articleId == selectedParkingArticleId,
      );

      if (!zoneExists) {
        selectedParkingArticleId = null;
        return;
      }

      // Ha létezik, megnézzük, betelt-e
      final selectedZone = parkingZones.firstWhere(
        (z) => z.articleId == selectedParkingArticleId,
      );

      if (selectedZone.occupancy == "Nincs szabad hely") {
        selectedParkingArticleId = null;
      }
    }
  }

  /// Meghatározza a kiválasztott id alapján a parkolás árát egy napra
  int getCostForZone(String articleId) {
    try {
      final parkingZone =
          parkingZones.firstWhere((z) => z.articleId == articleId);
      return parkingZone.totalPrice.toInt();
    } catch (_) {
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

  /// A parkolási napok számát frissíti.
  void UpdateParkingDays() {
    if (selectedLeaveDate != null && selectedArriveDate != null) {
      parkingDays = selectedLeaveDate!.difference(selectedArriveDate!).inDays;
    } else {
      parkingDays = 0;
    }

    if (selectedParkingArticleId != null) {
      CalculateTotalCost();
    }
  }

  /// Parkoló zónák generálása ServiceTemplates-ek alapján.
  Widget buildParkingZoneSelector({
    required String? selectedParkingArticleId,
    required int parkingDays,
    required Function(String) onZoneSelected,
  }) {
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
          children: parkingZones.map((parkingZone) {
            final String articleId = parkingZone.articleId;
            final nameParts = (parkingZone.zone).split(' ');
            final title = nameParts.isNotEmpty ? nameParts.last : '';
            final subtitle = nameParts.length > 1
                ? nameParts.sublist(0, nameParts.length - 1).join(' ')
                : '';
            final String occupancy = parkingZone.occupancy;

            return Padding(
              padding: const EdgeInsets.all(AppPadding.extraSmall),
              child: ParkingZoneSelectionCard(
                title: title,
                subtitle: subtitle,
                costPerDay: parkingZone.totalPrice.toInt(),
                parkingDays: parkingDays,
                selected: selectedParkingArticleId == articleId,
                onTap: () => onZoneSelected(articleId),
                available: occupancy != "Nincs szabad hely",
                occupancyColor: getOccupancyColor(parkingZone),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Időpont választó dialógus a parkolási intervallum kiválasztásához.
  void showDatePickerDialog() {
    // 1. Létrehozzuk a widgetet, amit meg akarunk jeleníteni
    final datePickerWidget = MyDateRangePickerDialog(
      initialArriveDate: selectedArriveDate,
      initialLeaveDate: selectedLeaveDate,
      initialArriveTime: selectedArriveTime,
      onDateSelected: (arriveDate, leaveDate, arriveTime) {
        setState(() {
          selectedArriveDate = arriveDate;
          selectedLeaveDate = leaveDate;
          selectedArriveTime = arriveTime;
          UpdateParkingDays();
          fetchParkingPrices();
        });
      },
    );

    // 2. Megnézzük, hogy mobilon vagyunk-e
    if (IsMobile) {
      // MOBILON: showModalBottomSheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => datePickerWidget,
      ).then((_) {
        // A dialógus bezárása után fókusz átadása
        FocusScope.of(context).requestFocus(transferFocus);
      });
    } else {
      // ASZTALI GÉPEN: showDialog
      showDialog(
        context: context,
        builder: (context) => datePickerWidget,
      ).then((_) {
        // A dialógus bezárása után fókusz átadása
        FocusScope.of(context).requestFocus(transferFocus);
      });
    }
  }

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      if (selectedArriveDate == null || selectedLeaveDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Válassz ki Parkolási intervallumot!')),
        );
        return;
      }
      if (selectedParkingArticleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Válassz ki egy parkoló zónát!')),
        );
        return;
      }

      // 1. Kontakt és Rendszám adatok mentése
      ref.read(reservationProvider.notifier).updateContactAndLicense(
            name: nameController.text,
            email: ref.read(reservationProvider).email,
            phone: '+${phoneController.text}',
            licensePlate: licensePlateController.text,
          );

      // 2. Parkolás adatok mentése
      ref.read(reservationProvider.notifier).updateParking(
            arriveDate: selectedArriveDate!,
            leaveDate: selectedLeaveDate!,
            parkingArticleId: selectedParkingArticleId,
            transferPersonCount: transferCount,
            vip: VIPDriverRequested,
            suitcaseWrappingCount: suitcaseWrappingCount,
            parkingCost: totalCost,
            payTypeId: selectedPayTypeId,
            description: descriptionController.text,
          );

      // 3. Navigálás a következő oldalra a bookingOption alapján
      Widget? nextPage;
      final bookingOption = ref.read(reservationProvider).bookingOption;

      if (bookingOption == BookingOption.parking) {
        nextPage = const InvoiceOptionPage();
      } else if (bookingOption == BookingOption.both) {
        nextPage = const WashOrderPage();
      }

      if (nextPage != null) {
        Navigation(context: context, page: nextPage).push();
      } else {
        // Ez az ág elvileg sosem fut le, ha a bookingOption helyesen van kezelve
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hiba: Ismeretlen foglalási opció.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sikertelen foglalás! Ellenőrizd az adatokat.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(nameFocus);
    });

    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      pageTitle: "Parkolás foglalás",
      haveMargins: true,
      child: Form(
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
                Padding(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: SafeArea(
                    bottom: true,
                    top: false,
                    child: NextPageButton(
                      focusNode: nextPageButtonFocus,
                      onPressed: OnNextPageButtonPressed,
                    ),
                  ),
                ),
              ],
            ),
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
            if (selectedArriveDate == null && selectedLeaveDate == null)
              Expanded(
                child: MyIconButton(
                  icon: Icons.calendar_month_rounded,
                  labelText: "Válassz dátumot",
                  focusNode: datePickerFocus,
                  onPressed: showDatePickerDialog,
                ),
              ),
            if (selectedArriveDate != null && selectedLeaveDate != null)
              Expanded(
                child: InkWell(
                  onTap: showDatePickerDialog,
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  child: Container(
                    padding: const EdgeInsets.all(AppPadding.small),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.small),
                      border: Border.all(color: AppColors.primary, width: 1),
                    ),
                    // Row helyett Column, ha mobil
                    child: IsMobile
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Érkezés
                              buildDateInfo(
                                Icons.flight_takeoff_rounded,
                                "Érkezés",
                                selectedArriveDate,
                              ),
                              const SizedBox(height: 8),
                              // Távozás
                              buildDateInfo(
                                Icons.flight_land_rounded,
                                "Távozás",
                                selectedLeaveDate,
                              ),
                            ],
                          )
                        : Row(
                            // PC: Egymás mellett
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Érkezés
                              buildDateInfo(
                                Icons.flight_takeoff_rounded,
                                "Érkezés",
                                selectedArriveDate,
                              ),
                              // Távozás
                              buildDateInfo(
                                Icons.flight_land_rounded,
                                "Távozás",
                                selectedLeaveDate,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Segéd widget a dátum információk megjelenítéséhez
  Widget buildDateInfo(IconData icon, String label, DateTime? date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          // A dialógus DateTime-ot ad vissza, ami tartalmazza az időt is
          "$label: ${date != null ? DateFormat('yyyy.MM.dd HH:mm').format(date) : "-"}",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildParkZoneSelector() {
    if (selectedArriveDate == null ||
        selectedLeaveDate == null ||
        selectedArriveTime == null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "Válassz intervallumot a parkoló zónák megtekintéséhez.",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Ha az árak még töltődnek
    if (parkingZones.isEmpty && parkingPrices == null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Ha nincsenek zónák az adott időpontra
    if (parkingZones.isEmpty && parkingPrices != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "A választott időpontra nincs elérhető parkoló zóna.",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: AppPadding.small),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Válassz parkoló zónát - $parkingDays napra',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        buildParkingZoneSelector(
          selectedParkingArticleId: selectedParkingArticleId,
          parkingDays: parkingDays,
          onZoneSelected: (articleId) {
            setState(() {
              selectedParkingArticleId = articleId;
            });
            CalculateTotalCost();
          },
        ),
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
            Text('Transzfer személyek száma'),
            SizedBox(width: IsMobile ? 0 : 16),
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
            SizedBox(width: IsMobile ? 0 : 8),
            Text('$transferCount',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: IsMobile ? 0 : 8),
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
            Text('VIP sofőr igénylése')
          ],
        ),
        Row(
          children: [
            MyCheckBox(
              value: suitcaseWrappingRequested,
              focusNode: suitcaseWrappingFocus,
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
                      SizedBox(width: IsMobile ? 0 : 16),
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
                      SizedBox(width: IsMobile ? 0 : 8),
                      Text('$suitcaseWrappingCount',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: IsMobile ? 0 : 8),
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
    final bookingOption = ref.read(reservationProvider).bookingOption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: bookingOption == BookingOption.parking
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
        bookingOption == BookingOption.parking
            ? Column(
                children: PayTypes.map((payType) {
                  return MyRadioListTile<String>(
                    title: payType
                        .payTypeName, // payType. == 0 ? payType.payTypeName : "$payType.payTypeName - $payType.discount",
                    value: payType.payTypeId,
                    groupValue: selectedPayTypeId,
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedPayTypeId = value;
                        fetchParkingPrices();
                      });
                    },
                    dense: true,
                  );
                }).toList(),
              )
            : Container(),
        SizedBox(height: 10),
      ],
    );
  }
}
