import 'package:flutter/material.dart';

/// Félórás időpontok generálása az időpont választáshoz 0:00 - 23:30 között
List<TimeOfDay> generateHalfHourTimeSlots() {
  List<TimeOfDay> slots = [];
  for (int hour = 0; hour <= 23; hour++) {
    slots.add(TimeOfDay(hour: hour, minute: 0));
    slots.add(TimeOfDay(hour: hour, minute: 30));
  }
  return slots;
}
