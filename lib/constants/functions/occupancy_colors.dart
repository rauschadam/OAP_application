import 'package:airport_test/api_services/api_classes/parking_zone.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';

class OccupancyColor {
  final Color primary;
  final Color secondary;

  OccupancyColor({
    required this.primary,
    required this.secondary,
  });
}

OccupancyColor getOccupancyColor(ParkingZone? parkingZone) {
  if (parkingZone != null) {
    switch (parkingZone.occupancy) {
      case "Szabad":
        return OccupancyColor(
          primary: const Color(0xFF2A822D),
          secondary: const Color(0xFF2A822D).withValues(alpha: 0.2),
        );
      case "Közepes":
        return OccupancyColor(
          primary: const Color(0xFFE6B800),
          secondary: const Color(0xFFE6B800).withValues(alpha: 0.2),
        );
      case "Magas":
        return OccupancyColor(
          primary: const Color(0xFFFF9800),
          secondary: const Color(0xFFFF9800).withValues(alpha: 0.2),
        );
      case "Kritikus":
        return OccupancyColor(
          primary: const Color(0xFFE64A19),
          secondary: const Color(0xFFE64A19).withValues(alpha: 0.2),
        );
      case "Nincs szabad hely":
        return OccupancyColor(
          primary: const Color(0xFFD32F2F),
          secondary: const Color(0xFFD32F2F).withValues(alpha: 0.2),
        );
    }
  }
  return OccupancyColor(
    primary: AppColors.primary,
    secondary: AppColors.primary.withValues(alpha: 0.2),
  );
}
