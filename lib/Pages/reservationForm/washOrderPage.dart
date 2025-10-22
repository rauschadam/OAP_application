import 'package:airport_test/Pages/reservationForm/invoiceOptionPage.dart';
import 'package:airport_test/api_services/api_classes/car_wash_service.dart';
import 'package:airport_test/api_services/api_classes/reservation.dart';
import 'package:airport_test/api_services/api_classes/service_templates.dart';
import 'package:airport_test/api_services/api_classes/user_data.dart';
import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/formatters.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/car_wash_selection_card.dart';
import 'package:airport_test/constants/dialogs/my_date_picker_dialog.dart';
import 'package:airport_test/constants/widgets/my_icon_button.dart';
import 'package:airport_test/constants/widgets/my_radio_list_tile.dart';
import 'package:airport_test/constants/widgets/my_text_form_field.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WashOrderPage extends ConsumerStatefulWidget {
  const WashOrderPage({super.key});

  @override
  ConsumerState<WashOrderPage> createState() => WashOrderPageState();
}

class WashOrderPageState extends ConsumerState<WashOrderPage> {
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

  /// Érkezési / Távozási dátum
  DateTime? selectedWashDate;
  TimeOfDay? selectedWashTime;

  /// Mosási szolgáltatás
  CarWashService? selectedCarWashService;

  String selectedPayTypeId = PayTypes.first.payTypeId;

  /// Lekérdezett foglalások
  List<ValidReservation>? reservations;

  /// Teljes időpontos foglalt időpontok
  List<DateTime> fullyBookedDateTimes =
      []; // parkoló zóna ArticleId -> telített időpont

  /// A teljes fizetendő összeg
  int totalCost = 0;

  /// Foglalások lekérdezése és a Riverpod állapot inicializálása
  Future<void> fetchData() async {
    final api = ApiService();
    final reservationState = ref.read(reservationProvider);

    /// Érvényes foglalások lekérdezése (a foglalt időkhoz)
    final reservationData = await api.getValidReservations(context);

    if (reservationData == null) {
      debugPrint('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        reservations = reservationData;
        fullyBookedDateTimes = listFullyBookedDateTimes(reservations!);
      });
    }

    if (reservationState.bookingOption == BookingOption.washing) {
      // Ha csak mosás, lekérjük az ügyfél adatait
      final UserData? userData =
          await api.getUserData(context, reservationState.personId);

      if (userData != null) {
        setState(() {
          // A beviteli mezők kitöltése a felhasználói adatokkal
          nameController.text = userData.person_Name;
          phoneController.text = formatPhone(userData.phone);
          // A email már bekerült a Riverpodba a LoginPage-en
        });
      }
    }

    // Controllerek és állapot betöltése a Riverpodból (mindig)
    setState(() {
      // Controllerek (az utolsó állapotból)
      if (nameController.text.isEmpty) {
        // Ha nem töltöttük be a serverről
        nameController.text = reservationState.name;
      }
      if (phoneController.text.isEmpty) {
        // Ha nem töltöttük be a serverről
        phoneController.text =
            formatPhone(reservationState.phone.replaceFirst('+', ''));
      }
      licensePlateController.text = reservationState.licensePlate;
      descriptionController.text = reservationState.description;

      // Lokális állapotok
      selectedPayTypeId = reservationState.payTypeId.isNotEmpty
          ? reservationState.payTypeId
          : PayTypes.first.payTypeId;
      totalCost = reservationState.parkingCost;

      // Mosás szolgáltatás (ha volt már választva)
      if (reservationState.carWashArticleId != null &&
          CarWashServices.isNotEmpty) {
        selectedCarWashService = CarWashServices.firstWhere(
          (s) => s.article_Id == reservationState.carWashArticleId,
          orElse: () => CarWashServices.first,
        );
        CalculateTotalCost();
      }

      // Mosás időpontja (ha volt már választva)
      selectedWashDate = reservationState.washDateTime;
      selectedWashTime = selectedWashDate != null
          ? TimeOfDay(
              hour: selectedWashDate!.hour, minute: selectedWashDate!.minute)
          : null;
    });
  }

  /// Telített időpontok kiszámítása – mivel csak egy zóna van, nem bontjuk szét.
  List<DateTime> listFullyBookedDateTimes(List<dynamic> reservations) {
    final int capacity = ServiceTemplates.firstWhere(
          (t) => t.parkingServiceType == 2,
          // Ha nem találja, visszatérünk egy placeholderrel, ahol a capacity null.
          orElse: () => ServiceTemplate(
            parkingTemplateId: -1,
            parkingServiceName: '',
            parkingServiceType: 2,
            zoneCapacity: null, // Ez indítja a ?? 2-t, ha nem volt találat
            articleId: null,
            advanceReserveLimit: 0,
            reserveIntervalLimit: null,
          ),
        ).zoneCapacity ??
        2;

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

  /// Teljes összeg kalkulálása (Riverpod állapotból olvassa a parkolás árát).
  void CalculateTotalCost() {
    final reservationState = ref.read(reservationProvider);
    int baseCost = reservationState.bookingOption == BookingOption.both
        ? reservationState.parkingCost
        : 0;

    // Hozzáadjuk a mosás árát
    if (selectedCarWashService != null) {
      baseCost += selectedCarWashService!.price.toInt();
    }

    setState(() {
      totalCost = baseCost;
    });
  }

  /// Dátum választó pop-up dialog
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
          CalculateTotalCost();
        },
      ),
    ).then((_) {
      FocusScope.of(context).requestFocus(descriptionFocus);
    });
  }

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      if (selectedWashDate != null &&
          selectedWashTime != null &&
          selectedCarWashService != null) {
        final reservationState = ref.read(reservationProvider);

        // Kontakt és Rendszám adatok mentése, ha csak mosás (washing)
        if (reservationState.bookingOption == BookingOption.washing) {
          ref.read(reservationProvider.notifier).updateContactAndLicense(
                name: nameController.text,
                email: reservationState.email,
                phone: '+${phoneController.text}',
                licensePlate: licensePlateController.text,
              );
        }

        // Mosási adatok mentése a Riverpodba
        ref.read(reservationProvider.notifier).updateWash(
              carWashArticleId: selectedCarWashService!.article_Id,
              washDateTime: DateTime(
                  selectedWashDate!.year,
                  selectedWashDate!.month,
                  selectedWashDate!.day,
                  selectedWashTime!.hour,
                  selectedWashTime!.minute),
              payTypeId: selectedPayTypeId,
              description: descriptionController.text,
            );

        // Navigálás a következő oldalra
        Navigation(
          context: context,
          page: const InvoiceOptionPage(),
        ).push();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Válassz ki időpontot és mosást!')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(nameFocus);
    });

    // Adatok betöltése a Riverpod állapotból és a szerverről
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
    final bookingOption = ref.read(reservationProvider).bookingOption;
    if (bookingOption == BookingOption.both) return Container();
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
    final bookingOption = ref.read(reservationProvider).bookingOption;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              text: bookingOption == BookingOption.both
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
