class ServiceTemplate {
  final int parkingTemplateId;
  final String parkingServiceName;
  final int parkingServiceType;
  final int? zoneCapacity;
  final String articleId;
  final int advanceReserveLimit;
  final int? reserveIntervalLimit;

  ServiceTemplate({
    required this.parkingTemplateId,
    required this.parkingServiceName,
    required this.parkingServiceType,
    this.zoneCapacity,
    required this.articleId,
    required this.advanceReserveLimit,
    required this.reserveIntervalLimit,
  });

  Map<String, dynamic> toJson() {
    return {
      "ParkingTemplateId": parkingTemplateId,
      "ParkingServiceName": parkingServiceName,
      "ParkingServiceType": parkingServiceType,
      "ZoneCapacity": zoneCapacity,
      "ArticleId": articleId,
      "AdvenceReserveLimit": advanceReserveLimit,
      "ReserveIntervalLimit": reserveIntervalLimit,
    };
  }

  factory ServiceTemplate.fromJson(Map<String, dynamic> json) {
    return ServiceTemplate(
      parkingTemplateId: json['ParkingTemplateId'],
      parkingServiceName: json['ParkingServiceName'],
      parkingServiceType: json['ParkingServiceType'],
      zoneCapacity: json['ZoneCapacity'],
      articleId: json['ArticleId'],
      advanceReserveLimit: json['AdvenceReserveLimit'],
      reserveIntervalLimit: json['ReserveIntervalLimit'],
    );
  }
}
