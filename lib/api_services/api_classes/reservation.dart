class Reservation {
  final int parkingService;
  final String partnerId;
  final bool alreadyRegistered;
  final bool withoutRegistration;
  final String name;
  final String email;
  final String phone;
  final String licensePlate;
  final DateTime arriveDate;
  final DateTime leaveDate;
  final String? parkingArticleId;
  final String parkingArticleVolume;
  final int? transferPersonCount;
  final bool vip;
  final int? suitcaseWrappingCount;
  final String? carWashArticleId;
  final DateTime? washDateTime;
  final String payTypeId;
  final String description;

  Reservation({
    required this.parkingService,
    required this.partnerId,
    required this.alreadyRegistered,
    required this.withoutRegistration,
    required this.name,
    required this.email,
    required this.phone,
    required this.licensePlate,
    required this.arriveDate,
    required this.leaveDate,
    this.parkingArticleId,
    required this.parkingArticleVolume,
    this.transferPersonCount,
    required this.vip,
    this.suitcaseWrappingCount,
    this.carWashArticleId,
    this.washDateTime,
    required this.payTypeId,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      "ParkingService": parkingService,
      "PartnerId": partnerId,
      "AlreadyRegistered": alreadyRegistered,
      "WithoutRegistration": withoutRegistration,
      "Name": name,
      "Email": email,
      "Phone": phone,
      "LicensePlate": licensePlate,
      "ArriveDate": arriveDate.toIso8601String(),
      "LeaveDate": leaveDate.toIso8601String(),
      "ParkingArticleId": parkingArticleId,
      "ParkingArticleVolume": parkingArticleVolume,
      "TransferPersonCount": transferPersonCount,
      "VIP": vip,
      "SuitcaseWrappingCount": suitcaseWrappingCount,
      "CarWashArticleId": carWashArticleId,
      "WashDateTime": washDateTime?.toIso8601String(),
      "PayTypeId": payTypeId,
      "Description": description,
    };
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      parkingService: json['ParkingService'],
      partnerId: json['PartnerId'],
      alreadyRegistered: json['AlreadyRegistered'],
      withoutRegistration: json['WithoutRegistration'],
      name: json['Name'],
      email: json['Email'],
      phone: json['Phone'],
      licensePlate: json['LicensePlate'],
      arriveDate: DateTime.parse(json['ArriveDate']),
      leaveDate: DateTime.parse(json['LeaveDate']),
      parkingArticleId: json['ParkingArticleId'],
      parkingArticleVolume: json['ParkingArticleVolume'],
      transferPersonCount: json['TransferPersonCount'],
      vip: json['VIP'],
      suitcaseWrappingCount: json['SuitcaseWrappingCount'],
      carWashArticleId: json['CarWashArticleId'],
      washDateTime: DateTime.parse(json['WashDateTime']),
      payTypeId: json['PayTypeId'],
      description: json['Description'],
    );
  }
}
