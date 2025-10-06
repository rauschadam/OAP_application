import 'package:airport_test/Pages/reservationForm/invoiceOptionPage.dart';
import 'package:airport_test/Pages/reservationForm/washOrderPage.dart';
import 'package:airport_test/api_services/api_classes/user_data.dart';
import 'package:airport_test/constants/functions/occupancy_colors.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/api_classes/parking_zone.dart';
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

  final String authToken;
  final String partnerId;
  final String personId;
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
      required this.personId,
      required this.partnerId,
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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController licensePlateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
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

  /// Érkezési / Távozási dátum
  DateTime? selectedArriveDate, selectedLeaveDate;

  /// Érkezés időpontja
  TimeOfDay? selectedArriveTime;

  /// A DatePicker még le nem okézott, ott kiválasztott dátumai.
  /// Ezeken nézi meg hogy megfelelnek-e a feltételeknek,
  /// majd beállítja selectedArriveDate/selectedLeaveDate/selectedArriveTime-nak
  DateTime? tempArriveDate, tempLeaveDate;
  TimeOfDay? tempArriveTime;

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

    // Felhasználói fiók lekérése
    final UserData? userData = await api.getUserData(context, widget.personId);

    if (userData != null) {
      setState(() {
        // A beviteli mezők kitöltése a felhasználói adatokkal
        nameController.text = userData.person_Name;
        phoneController.text = formatPhone(userData.phone);
      });
    }
  }

  String formatPhone(String? phoneText) {
    if (phoneText == null) return '';
    if (phoneText.startsWith('+')) {
      return phoneText.substring(1);
    } else {
      return phoneText;
    }
  }

  /// Parkoló zóna árak lekérdezése
  Future<void> fetchParkingPrices() async {
    if (selectedArriveDate == null ||
        selectedLeaveDate == null ||
        selectedArriveTime == null) {
      return;
    }
    final DateTime beginInterval = selectedArriveDate!.add(
      Duration(
        hours: selectedArriveTime!.hour,
        minutes: selectedArriveTime!.minute,
        seconds: 0,
      ),
    );
    final DateTime endInterval = selectedLeaveDate!.add(
      Duration(
        hours: selectedArriveTime!.hour,
        minutes: selectedArriveTime!.minute,
        seconds: 0,
      ),
    );
    final api = ApiService();
    // Parkoló zóna árak lekérdezése
    final parkingPriceData = await api.getParkingPrices(
        context,
        widget.authToken,
        beginInterval,
        endInterval,
        widget.partnerId,
        selectedPayTypeId);
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
    parkingDays = selectedLeaveDate!.difference(selectedArriveDate!).inDays;
    selectedParkingArticleId != null ? CalculateTotalCost() : null;
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
    showDialog(
      context: context,
      builder: (context) => MyDateRangePickerDialog(
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
            payTypeId: selectedPayTypeId,
            partnerId: widget.partnerId,
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
            personId: widget.personId,
            partnerId: widget.partnerId,
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

    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(nameFocus);
    });

    fetchData();
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
            if (selectedArriveDate == null && selectedLeaveDate == null)
              MyIconButton(
                icon: Icons.calendar_month_rounded,
                labelText: "Válassz dátumot",
                focusNode: datePickerFocus,
                onPressed: showDatePickerDialog,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.flight_takeoff_rounded,
                                color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              "Érkezés: ${selectedArriveDate != null ? DateFormat('yyyy.MM.dd HH:mm').format(selectedArriveDate!) : "-"}",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flight_land_rounded,
                                color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              "Távozás: ${selectedLeaveDate != null ? DateFormat('yyyy.MM.dd HH:mm').format(selectedLeaveDate!) : "-"}",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
            Text('Transzferre váró személyek száma'),
            SizedBox(width: IsMobile! ? 0 : 16),
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
            SizedBox(width: IsMobile! ? 0 : 8),
            Text('$transferCount',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: IsMobile! ? 0 : 8),
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
                      SizedBox(width: IsMobile! ? 0 : 16),
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
                      SizedBox(width: IsMobile! ? 0 : 8),
                      Text('$suitcaseWrappingCount',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: IsMobile! ? 0 : 8),
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
                children: PayTypes.map((payType) {
                  return MyRadioListTile<String>(
                    title: payType.payTypeName,
                    value: payType.payTypeId,
                    groupValue: selectedPayTypeId,
                    onChanged: (value) {
                      setState(() {
                        selectedPayTypeId = value!;
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
