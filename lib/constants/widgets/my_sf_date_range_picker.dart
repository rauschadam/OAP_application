import 'package:airport_test/constants/constant_functions.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/responsive.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:airport_test/constants/widgets/base_page.dart';

class MyDateRangePickerDialog extends StatefulWidget {
  final DateTime? initialArriveDate;
  final DateTime? initialLeaveDate;
  final TimeOfDay? initialArriveTime;
  final Map<String, List<DateTime>> fullyBookedDateTimes;
  final Function(DateTime arriveDate, DateTime leaveDate, TimeOfDay arriveTime)
      onDateSelected;

  const MyDateRangePickerDialog({
    super.key,
    this.initialArriveDate,
    this.initialLeaveDate,
    this.initialArriveTime,
    required this.fullyBookedDateTimes,
    required this.onDateSelected,
  });

  @override
  State<MyDateRangePickerDialog> createState() =>
      _MyDateRangePickerDialogState();
}

class _MyDateRangePickerDialogState extends State<MyDateRangePickerDialog> {
  DateTime? tempArriveDate;
  DateTime? tempLeaveDate;
  TimeOfDay? tempArriveTime;
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
    tempArriveDate = widget.initialArriveDate;
    tempLeaveDate = widget.initialLeaveDate;
    tempArriveTime = widget.initialArriveTime;

    if (tempArriveDate != null && tempLeaveDate != null) {
      _updateAvailableSlots();
    }
  }

  /// Elérhető időpontok frissítése
  void _updateAvailableSlots() {
    final allSlots = generateHalfHourTimeSlots();
    final today = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(today);

    setState(() {
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

        // Ellenőrizzük, hogy az adott időpont foglalt-e (érkezés napján)
        bool isArriveFullyBookedEverywhere = widget.fullyBookedDateTimes.values
            .every((zoneTimes) => zoneTimes.every((d) =>
                d.year == (tempArriveDate?.year ?? 0) &&
                d.month == (tempArriveDate?.month ?? 0) &&
                d.day == (tempArriveDate?.day ?? 0) &&
                d.hour == time.hour &&
                d.minute == time.minute));

        // Ellenőrizzük, hogy az adott időpont foglalt-e (távozás napján)
        bool isLeaveFullyBookedEverywhere = widget.fullyBookedDateTimes.values
            .every((zoneTimes) => zoneTimes.every((d) =>
                d.year == (tempLeaveDate?.year ?? 0) &&
                d.month == (tempLeaveDate?.month ?? 0) &&
                d.day == (tempLeaveDate?.day ?? 0) &&
                d.hour == time.hour &&
                d.minute == time.minute));

        return !isArriveFullyBookedEverywhere && !isLeaveFullyBookedEverywhere;
      }).toList();
    });
  }

  /// Időpont választó kártyák widgetje
  Widget _buildTimeSlotPicker(List<TimeOfDay> slots) {
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
                      bool isSelected = tempArriveTime == time;
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
                              tempArriveTime = time;
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

  void _onConfirmSelection() {
    if (tempArriveDate != null &&
        tempLeaveDate != null &&
        tempArriveTime != null) {
      final diff = tempLeaveDate!.difference(tempArriveDate!).inDays;
      if (diff < 1) {
        _showErrorDialog(
            "A választott tartománynak legalább 1 napnak kell lennie.");
        return;
      }
      if (diff > 30) {
        _showErrorDialog("A választott tartomány legfeljebb 30 nap lehet.");
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

      widget.onDateSelected(arriveDateTime, leaveDateTime, tempArriveTime!);
      Navigator.of(context).pop();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hiba'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
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

                  setState(() {
                    tempArriveDate = start;
                    tempLeaveDate = end;
                    tempArriveTime = null; // Reseteljük

                    if (tempArriveDate != null && tempLeaveDate != null) {
                      _updateAvailableSlots();
                    }
                  });
                }
              },
            ),

            // Időpont választás
            if (tempArriveDate != null && tempLeaveDate != null)
              availableSlots.isNotEmpty
                  ? _buildTimeSlotPicker(availableSlots)
                  : const Text('Ezen a napon nincs szabad időpont')
            else
              const Text(
                  'Válasszon ki érkezési és távozási dátumot, az időpontok megtekintéséhez'),

            const SizedBox(height: 10),

            // Oké gomb
            if (tempArriveDate != null &&
                tempLeaveDate != null &&
                tempArriveTime != null)
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
                  onPressed: _onConfirmSelection,
                  child: const Text("Időpont kiválasztása"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
