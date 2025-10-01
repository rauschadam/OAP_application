class LoginData {
  final int? sysUserId;
  final int? webUserId;
  final String partnerId;
  final String authorizationToken;
  final String? expiration;

  LoginData({
    required this.authorizationToken,
    required this.partnerId,
    this.expiration,
    this.sysUserId,
    this.webUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      "SysUserId": sysUserId,
      "WebUserId": webUserId,
      "PartnerId": partnerId,
      "AuthorizationToken": authorizationToken,
      "Expiration": expiration,
    };
  }

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      sysUserId: json['SysUserId'],
      webUserId: json['WebUserId'],
      partnerId: json['PartnerId'].toString(),
      authorizationToken: json['AuthorizationToken'],
      expiration: json['Expiration'],
    );
  }
}
