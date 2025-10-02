class PayType {
  final String payTypeId;
  final String payTypeName;
  final int? days;
  final bool? isWorkday;
  final bool? isCheckout;

  PayType({
    required this.payTypeId,
    required this.payTypeName,
    this.days,
    this.isWorkday,
    this.isCheckout,
  });

  Map<String, dynamic> toJson() {
    return {
      "Partner_Paytype_Id": payTypeId,
      "Paytype_Name": payTypeName,
      "Days": days,
      "Is_Workday": isWorkday,
      "Is_Checkout": isCheckout,
    };
  }

  factory PayType.fromJson(Map<String, dynamic> json) {
    return PayType(
      payTypeId: json['Partner_Paytype_Id'],
      payTypeName: json['Paytype_Name'],
      days: json['Days'],
      isWorkday: json['Is_Workday'],
      isCheckout: json['Is_Checkout'],
    );
  }
}
