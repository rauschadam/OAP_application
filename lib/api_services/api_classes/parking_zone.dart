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

List<ParkingZone> mapParkingZones(
    List<dynamic> parkingPrices, List<dynamic> serviceTemplates) {
  return parkingPrices.map((zone) {
    final String articleId = zone['articleId'];
    final int zoneCapacity = serviceTemplates.firstWhere(
            (template) => template['ArticleId'] == articleId,
            orElse: () => {'ZoneCapacity': 1})['ZoneCapacity'] ??
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
