import 'package:airport_test/api_services/api_classes/available_list_panel.dart';

class LoginData {
  final int? sysUserId;
  final int? webUserId;
  final String partnerId;
  final String personId;
  final String authorizationToken;
  final DateTime expiration;
  final List<AvailableListPanel>? availableListPanels;

  LoginData({
    required this.authorizationToken,
    required this.partnerId,
    required this.personId,
    required this.expiration,
    this.sysUserId,
    this.webUserId,
    this.availableListPanels,
  });

  Map<String, dynamic> toJson() {
    return {
      "sysUserId": sysUserId,
      "webUserId": webUserId,
      "personId": personId,
      "partnerId": partnerId,
      "authorizationToken": authorizationToken,
      "expiration": expiration.toIso8601String(),
      "availableListPanels":
          availableListPanels?.map((e) => e.toJson()).toList(),
    };
  }

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      sysUserId: json['sysUserId'],
      webUserId: json['webUserId'],
      personId: json['personId'],
      partnerId: json['partnerId'].toString(),
      authorizationToken: json['authorizationToken'],
      expiration: DateTime.parse(json['expiration']),
      availableListPanels: (json['availableListPanels'] as List?)
          ?.map((e) => AvailableListPanel.fromJson(e))
          .toList(),
    );
  }
}
