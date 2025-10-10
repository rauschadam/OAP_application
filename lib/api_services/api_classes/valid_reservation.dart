class ValidReservation {
  final int webParkingId;
  final String partnerId;
  final String partner_Sortname;
  final String licensePlate;
  final String parkingArticleId;
  final String articleNameHUN;
  final int state;
  final DateTime arriveDate;
  final DateTime leaveDate;
  final String webParkingPaperId;
  final String webParkingPaperNumber;
  final String webParkingPaperTypeName;
  final String? webParkingAdvancePaperId;
  final String? webParkingAdvancePaperNumber;
  final String? webParkingAdvancePaperTypeName;
  final String email;
  final String phone;
  final String? description;
  final bool? VIP;
  final int? suitcaseWrappingCount;
  final int? transferCount;

  ValidReservation({
    required this.webParkingId,
    required this.partnerId,
    required this.partner_Sortname,
    required this.licensePlate,
    required this.parkingArticleId,
    required this.articleNameHUN,
    required this.state,
    required this.arriveDate,
    required this.leaveDate,
    required this.webParkingPaperId,
    required this.webParkingPaperNumber,
    required this.webParkingPaperTypeName,
    this.webParkingAdvancePaperId,
    this.webParkingAdvancePaperNumber,
    this.webParkingAdvancePaperTypeName,
    required this.email,
    required this.phone,
    this.description,
    this.VIP,
    this.suitcaseWrappingCount,
    this.transferCount,
  });

  Map<String, dynamic> toJson() {
    return {
      "WebParkingId": webParkingId,
      "ParterId": partnerId,
      "Partner_Sortname": partner_Sortname,
      "LicensePlate": licensePlate,
      "ParkingArticleId": parkingArticleId,
      "ArticleNameHUN": articleNameHUN,
      "State": state,
      "ArriveDate": arriveDate.toIso8601String(),
      "LeaveDate": leaveDate.toIso8601String(),
      "WebParkingPaperId": webParkingPaperId,
      "WebParkingPaperNumber": webParkingPaperNumber,
      "WebParkingPaperTypeName": webParkingPaperTypeName,
      "WebParkingAdvancePaperId": webParkingAdvancePaperId,
      "WebParkingAdvancePaperNumber": webParkingAdvancePaperNumber,
      "WebParkingAdvancePaperTypeName": webParkingAdvancePaperTypeName,
      "Email": email,
      "Phone": phone,
      "Description": description,
      "VIP": VIP,
      "SuitcaseWrappingCount": suitcaseWrappingCount,
      "TransferCount": transferCount,
    };
  }

  factory ValidReservation.fromJson(Map<String, dynamic> json) {
    return ValidReservation(
      webParkingId: json['WebParkingId'],
      partnerId: json['PartnerId'],
      partner_Sortname: json['Partner_Sortname'],
      licensePlate: json['LicensePlate'],
      parkingArticleId: json['ParkingArticleId'],
      articleNameHUN: json['ArticleNameHUN'],
      state: json['State'],
      arriveDate: DateTime.parse(json['ArriveDate']),
      leaveDate: DateTime.parse(json['LeaveDate']),
      webParkingPaperId: json['WebParkingPaperId'],
      webParkingPaperNumber: json['WebParkingPaperNumber'],
      webParkingPaperTypeName: json['WebParkingPaperTypeName'],
      webParkingAdvancePaperId: json['WebParkingAdvancePaperId'],
      webParkingAdvancePaperNumber: json['WebParkingAdvancePaperNumber'],
      webParkingAdvancePaperTypeName: json['WebParkingAdvancePaperTypeName'],
      email: json['Email'],
      phone: json['Phone'],
      description: json['Description'],
      VIP: json['VIP'],
      suitcaseWrappingCount: json['SuitcaseWrappingCount'],
      transferCount: json['TransferCount'],
    );
  }
}
