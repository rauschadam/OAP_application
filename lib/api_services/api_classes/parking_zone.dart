import 'package:airport_test/constants/globals.dart';

class ParkingZone {
  final String articleId;
  final String zone;
  final double totalPrice;
  final int zoneCapacity;

  ParkingZone({
    required this.articleId,
    required this.zone,
    required this.totalPrice,
    required this.zoneCapacity,
  });
}

List<ParkingZone> mapParkingZones(List<dynamic> parkingPrices) {
  return parkingPrices.map((zone) {
    final String articleId = zone['articleId'];
    final int zoneCapacity = ServiceTemplates.firstWhere(
          (template) => template.articleId == articleId,
        ).zoneCapacity ??
        1;
    return ParkingZone(
      articleId: articleId,
      zone: zone['zone'],
      totalPrice: (zone['totalPrice'] is int)
          ? (zone['totalPrice'] as int).toDouble()
          : (zone['totalPrice']),
      zoneCapacity: zoneCapacity,
    );
  }).toList();
}
