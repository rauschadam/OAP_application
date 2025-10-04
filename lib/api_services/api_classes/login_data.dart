class LoginData {
  final int? sysUserId;
  final int? webUserId;
  final String personId;
  final String partnerId;
  final String authorizationToken;
  final String? expiration;

  LoginData({
    required this.authorizationToken,
    required this.partnerId,
    required this.personId,
    this.expiration,
    this.sysUserId,
    this.webUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      "SysUserId": sysUserId,
      "WebUserId": webUserId,
      "PersonId": personId,
      "PartnerId": partnerId,
      "AuthorizationToken": authorizationToken,
      "Expiration": expiration,
    };
  }

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      sysUserId: json['SysUserId'],
      webUserId: json['WebUserId'],
      personId: json['PersonId'],
      partnerId: json['PartnerId'].toString(),
      authorizationToken: json['AuthorizationToken'],
      expiration: json['Expiration'],
    );
  }
}
