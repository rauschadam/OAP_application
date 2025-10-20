import 'package:airport_test/Pages/reservationForm/invoiceOptionPage.dart';
import 'package:airport_test/api_services/api_classes/car_wash_service.dart';
import 'package:airport_test/api_services/api_classes/user_data.dart';
import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/formatters.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/car_wash_selection_card.dart';
import 'package:airport_test/constants/widgets/my_date_picker_dialog.dart';
import 'package:airport_test/constants/widgets/my_icon_button.dart';
import 'package:airport_test/constants/widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/widgets/my_text_form_field.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WashOrderPage extends StatefulWidget {
  final String authToken;
  final String personId;
  final String partnerId;
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
      required this.personId,
      required this.partnerId,
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

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController licensePlateController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
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
  CarWashService? selectedCarWashService;

  String selectedPayTypeId = PayTypes.first.payTypeId;

  /// Lekérdezett foglalások
  List<ValidReservation>? reservations;

  /// Teljes időpontos foglalt időpontok
  List<DateTime> fullyBookedDateTimes =
      []; // parkoló zóna ArticleId -> telített időpont

  /// A teljes fizetendő összeg
  int totalCost = 0;

  /// A megadott napon elérhető időpontok
  List<TimeOfDay> availableSlots = [];

  /// Foglalások lekérdezése
  Future<void> fetchData() async {
    final api = ApiService();

    /// Foglalások lekérdezése
    final reservationData = await api.getValidReservations(context);

    if (reservationData == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        reservations = reservationData;
        fullyBookedDateTimes = listFullyBookedDateTimes(reservations!);
      });
    }

    if (widget.bookingOption == BookingOption.washing) {
      // Felhasználói fiók lekérése
      final UserData? userData =
          await api.getUserData(context, widget.personId);
      if (userData != null) {
        setState(() {
          // A beviteli mezők kitöltése a felhasználói adatokkal
          nameController.text = userData.person_Name;
          phoneController.text = formatPhone(userData.phone);
          widget.emailController.text = userData.email;
        });
      }
    }
  }

  /// telített időpontok
  /// Telített időpontok kiszámítása – mivel csak egy zóna van, nem bontjuk szét.
  List<DateTime> listFullyBookedDateTimes(List<dynamic> reservations) {
    // Az egyetlen mosási zóna kapacitása (pl. 2 autó / időpont)
    const int capacity = 2;

    // Időpontok számlálója
    Map<DateTime, int> counters = {};

    for (ValidReservation reservation in reservations) {
      if (reservation.washDateTime == null) continue;
      final DateTime washDateTime = reservation.washDateTime!;

      // Félórás bontásban kezeljük az időpontokat
      DateTime current = DateTime(
        washDateTime.year,
        washDateTime.month,
        washDateTime.day,
        washDateTime.hour,
        washDateTime.minute - (washDateTime.minute % 30),
      );

      counters[current] = (counters[current] ?? 0) + 1;
    }

    // Azok az időpontok, ahol elértük a kapacitást
    return counters.entries
        .where((entry) => entry.value >= capacity)
        .map((entry) => entry.key)
        .toList();
  }

  /// Teljes összeg kalkulálása, az árakat később adatbázisból fogja előhívni.
  void CalculateTotalCost() {
    int baseCost =
        widget.bookingOption == BookingOption.both ? widget.parkingCost! : 0;

    // Hozzáadjuk a parkolás árát
    if (selectedCarWashService != null) {
      baseCost += selectedCarWashService!.price.toInt();
    }

    setState(() {
      totalCost = baseCost;
    });
  }

  /// Dátum választó pop-up dialog
  /// Időpont választó dialógus a parkolási intervallum kiválasztásához.
  void showDatePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => MyDatePickerDialog(
        initialWashDate: selectedWashDate,
        initialWashTime: selectedWashTime,
        fullyBookedDateTimes: fullyBookedDateTimes,
        onDateSelected: (washDate, washTime) {
          setState(() {
            selectedWashDate = washDate;
            selectedWashTime = washTime;
          });
        },
      ),
    ).then((_) {
      // A dialógus bezárása után fókusz átadása
      //FocusScope.of(context).requestFocus(transferFocus);
    });
  }

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      if (selectedWashDate != null && selectedWashTime != null) {
        Navigation(
            context: context,
            page: InvoiceOptionPage(
              authToken: widget.authToken,
              payTypeId: selectedPayTypeId,
              partnerId: widget.partnerId,
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
              carWashArticleId: selectedCarWashService!.article_Id,
              suitcaseWrappingCount: widget.suitcaseWrappingCount,
              parkingArticleId: widget.parkingArticleId,
              alreadyRegistered: widget.alreadyRegistered,
              withoutRegistration: widget.withoutRegistration,
            )).push();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Válassz ki időpontot!')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.bookingOption == BookingOption.both) {
      nameController = widget.nameController!;
      phoneController = widget.phoneController!;
      licensePlateController = widget.licensePlateController!;
      descriptionController = widget.descriptionController!;
    }

    totalCost = widget.parkingCost ?? 0;

    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(nameFocus);
    });

    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      pageTitle: "Mosás foglalás",
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
                buildCarWashSelector(),
                buildPaymentMethods(),
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
      ),
    );
  }

  Widget buildTextFormFields() {
    if (widget.bookingOption == BookingOption.both) return Container();
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
            hintText: 'Foglaló személy neve'),
        const SizedBox(height: 10),
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
      ],
    );
  }

  Widget buildDatePickerRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (selectedWashDate == null)
              Expanded(
                child: MyIconButton(
                  icon: Icons.calendar_month_rounded,
                  labelText: "Válassz dátumot",
                  focusNode: datePickerFocus,
                  onPressed: showDatePickerDialog,
                ),
              ),
            if (selectedWashDate != null)
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
                            Icon(Icons.local_car_wash,
                                color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              "Mosás: ${selectedWashDate != null ? DateFormat('yyyy.MM.dd HH:mm').format(selectedWashDate!) : "-"}",
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

  Widget buildCarWashSelector() {
    return Column(
      children: [
        const SizedBox(height: 12),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Válassza ki a kívánt programot'),
        ),
        CarWashServices.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : buildCarWashZoneSelector(
                selectedCarWashService: selectedCarWashService,
                onZoneSelected: (service) {
                  setState(() {
                    selectedCarWashService = service;
                  });
                  CalculateTotalCost();
                },
              ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Mosási szolgáltatások megjelenítése CarWashService alapján
  Widget buildCarWashZoneSelector({
    required CarWashService? selectedCarWashService,
    required Function(CarWashService) onZoneSelected,
  }) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        WashOptionsScrollController.jumpTo(
          WashOptionsScrollController.position.pixels - details.delta.dx,
        );
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: WashOptionsScrollController,
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: CarWashServices.map((service) {
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: CarWashSelectionCard(
                title: service.article_Name,
                washCost: service.price.toInt(),
                selected: selectedCarWashService == service,
                onTap: () => onZoneSelected(service),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildPaymentMethods() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
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
        ),
        Column(
          children: PayTypes.map((payType) {
            return MyRadioListTile<String>(
              title: payType.payTypeName,
              value: payType.payTypeId,
              groupValue: selectedPayTypeId,
              onChanged: (value) {
                setState(() {
                  selectedPayTypeId = value!;
                });
              },
              dense: true,
            );
          }).toList(),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
