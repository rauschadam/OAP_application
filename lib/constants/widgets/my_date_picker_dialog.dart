import 'package:airport_test/constants/constant_functions.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/responsive.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

/// WashOrderPage-en használjuk
class MyDatePickerDialog extends StatefulWidget {
  final DateTime? initialWashDate;
  final TimeOfDay? initialWashTime;
  final List<DateTime> fullyBookedDateTimes;
  final Function(DateTime washDate, TimeOfDay washTime) onDateSelected;

  const MyDatePickerDialog({
    super.key,
    this.initialWashDate,
    this.initialWashTime,
    required this.fullyBookedDateTimes,
    required this.onDateSelected,
  });

  @override
  State<MyDatePickerDialog> createState() => _MyDatePickerDialogState();
}

class _MyDatePickerDialogState extends State<MyDatePickerDialog> {
  DateTime? tempWashDate;
  TimeOfDay? tempWashTime;
  List<TimeOfDay> availableSlots = [];
  Map<String, int> hoveredIndexMap = {
    "Hajnal": -1,
    "Reggel": -1,
    "Nappal": -1,
    "Este": -1,
    "Éjszaka": -1,
  };

  @override
  void initState() {
    super.initState();
    tempWashDate = widget.initialWashDate;
    tempWashTime = widget.initialWashTime;

    if (tempWashDate != null) {
      updateAvailableSlots();
    }
  }

  /// Elérhető időpontok frissítése
  void updateAvailableSlots() {
    final allSlots = generateHalfHourTimeSlots();
    final today = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(today);

    setState(() {
      availableSlots = allSlots.where((time) {
        // Múltbeli időpontokat kiszűrjük
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

        ///Ellenőrizzük, hogy foglalt-e az adott időpont
        bool isBooked = widget.fullyBookedDateTimes.any((d) =>
            d.year == (tempWashDate?.year ?? 0) &&
            d.month == (tempWashDate?.month ?? 0) &&
            d.day == (tempWashDate?.day ?? 0) &&
            d.hour == time.hour &&
            d.minute == time.minute);

        return !isBooked;
      }).toList();
    });
  }

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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.isMobile(context) ? 3 : 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: Responsive.isMobile(context) ? 2 : 8,
                      childAspectRatio: Responsive.isMobile(context) ? 2.2 : 3,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final time = entry.value[index];
                      bool isSelected = tempWashTime == time;
                      bool isHovered = hoveredIndexMap[entry.key] == index;

                      Color cardColor;
                      if (isSelected) {
                        cardColor = BasePage.defaultColors.primary;
                      } else if (isHovered) {
                        cardColor = Colors.grey.shade400;
                      } else {
                        cardColor = const Color.fromARGB(255, 234, 238, 244);
                      }

                      return MouseRegion(
                        onEnter: (_) {
                          setState(() {
                            hoveredIndexMap[entry.key] = index;
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            hoveredIndexMap[entry.key] = -1;
                          });
                        },
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              tempWashTime = time;
                            });
                          },
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.large),
                            ),
                            color: cardColor,
                            child: Center(
                              child: Text(
                                time.format(context),
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
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

  void onConfirmSelection() {
    if (tempWashDate != null && tempWashTime != null) {
      final arriveDateTime = DateTime(
        tempWashDate!.year,
        tempWashDate!.month,
        tempWashDate!.day,
        tempWashTime!.hour,
        tempWashTime!.minute,
      );

      widget.onDateSelected(arriveDateTime, tempWashTime!);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium)),
      child: Container(
        width: MediaQuery.of(context).size.width < 600
            ? MediaQuery.of(context).size.width
            : 650,
        height: MediaQuery.of(context).size.width < 600
            ? MediaQuery.of(context).size.height
            : 750,
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          children: [
            SfDateRangePicker(
              headerStyle: const DateRangePickerHeaderStyle(
                backgroundColor: Colors.white,
              ),
              backgroundColor: Colors.white,
              initialDisplayDate: tempWashDate,
              initialSelectedDate: tempWashDate,
              selectionMode: DateRangePickerSelectionMode.single,
              todayHighlightColor: BasePage.defaultColors.primary,
              selectionColor: BasePage.defaultColors.primary,
              showNavigationArrow: true,
              enablePastDates: false,
              maxDate: DateTime.now().add(const Duration(days: 120)),
              onSelectionChanged: (args) {
                if (args.value is DateTime) {
                  final DateTime selectedDate = args.value;

                  setState(() {
                    tempWashDate = selectedDate;
                    tempWashTime = null; // Reseteljük

                    if (tempWashDate != null) {
                      updateAvailableSlots();
                    }
                  });
                }
              },
            ),

            // Időpont választás
            if (tempWashDate != null)
              availableSlots.isNotEmpty
                  ? buildTimeSlotPicker(availableSlots)
                  : const Text('Ezen a napon nincs szabad időpont')
            else
              const Text(
                  'Válasszon ki érkezési dátumot az időpontok megtekintéséhez'),

            const SizedBox(height: 10),

            // Oké gomb
            if (tempWashDate != null && tempWashTime != null)
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(BasePage.defaultColors.primary),
                    foregroundColor: WidgetStateProperty.all(
                        BasePage.defaultColors.background),
                  ),
                  onPressed: onConfirmSelection,
                  child: const Text("Időpont kiválasztása"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
