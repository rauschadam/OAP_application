import 'package:airport_test/Pages/reservationForm/invoiceOptionPage.dart';
import 'package:airport_test/api_services/api_service.dart';
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

  /// Lekérdezett szolgáltatások
  List<dynamic>? serviceTemplates;

  /// Teljes időpontos foglalt időpontok
  List<DateTime> fullyBookedDateTimes =
      []; // parkoló zóna ArticleId -> telített időpont

  /// A teljes fizetendő összeg
  int totalCost = 0;

  /// A megadott napon elérhető időpontok
  List<TimeOfDay> availableSlots = [];

  /// Foglalások lekérdezése
  Future<void> fetchReservations() async {
    final api = ApiService();
    final data = await api.getReservations(context, widget.authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        reservations = data;
      });
      fetchServiceTemplates();
    }
  }

  /// Szolgáltatások lekérdezése
  Future<void> fetchServiceTemplates() async {
    final api = ApiService();
    final data = await api.getServiceTemplates(context, widget.authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        serviceTemplates = data;
        fullyBookedDateTimes =
            listFullyBookedDateTimes(reservations!, serviceTemplates!);
      });
    }
  }

  /// telített időpontok
  List<DateTime> listFullyBookedDateTimes(
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
    Map<String, Map<DateTime, int>> counters = {};

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

    // Összes foglalt időpont (ha bármelyik zóna tele van)
    Set<DateTime> fullyBookedDateTimes = {};

    counters.forEach((washingArticleId, counter) {
      if (washingArticleId != "") {
        final capacity = zoneCapacities[washingArticleId];
        // Ha egy zóna tele van, az az időpont foglalt mindenkinek
        counter.entries
            .where((entry) => entry.value >= capacity!)
            .forEach((entry) {
          fullyBookedDateTimes.add(entry.key);
        });
      }
    });

    return fullyBookedDateTimes.toList();
  }

  /// Kiválasztott parkolózóna napijegy ára
  /// TODO: jelenleg bevannak égetve az árak
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
    );
  }

  Widget buildTextFormFields() {
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
    return Row(
      children: [
        MyIconButton(
            icon: Icons.calendar_month_rounded,
            labelText: 'Válassz dátumot',
            onPressed: showDatePickerDialog),
        const SizedBox(width: 50),
        Column(
          children: [
            Text('Érkezés'),
            Text(selectedWashDate != null
                ? DateFormat('yyyy.MM.dd HH:mm').format(selectedWashDate!)
                : "-")
          ],
        ),
      ],
    );
  }

  Widget buildCarWashSelector() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Align(
            alignment: Alignment.centerLeft,
            child: const Text('Válassza ki a kívánt programot')),
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
              ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Parkoló zónák generálása ServiceTemplates-ek alapján.
  Widget buildCarWashZoneSelector({
    required List<dynamic> serviceTemplates,
    required String? selectedCarWashArticleId,
    required Function(String) onZoneSelected,
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
            final String title = zone['ParkingServiceName'];

            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: CarWashSelectionCard(
                title: title,
                washCost: getCostForZone(articleId),
                selected: selectedCarWashArticleId == articleId,
                onTap: () => onZoneSelected(articleId),
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
        SizedBox(height: 10),
      ],
    );
  }
}
