import 'dart:convert';
import 'package:airport_test/api_services/api_classes/login_data.dart';
import 'package:airport_test/api_services/api_classes/pay_type.dart';
import 'package:airport_test/api_services/api_classes/reservation.dart';
import 'package:airport_test/api_services/api_classes/registration.dart';
import 'package:airport_test/api_services/api_classes/service_templates.dart';
import 'package:airport_test/api_services/api_classes/user_data.dart';
import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:intl/intl.dart';

class ApiService {
  final String baseUrl = '81.183.212.64:9006';
  final http.Client client = http.Client();

  void dispose() {
    client.close();
  }

  /// Ügyfél regisztrációja
  Future<String?> registerUser(
      BuildContext context, Registration registration) async {
    final uri = Uri.http(baseUrl, '/service/v1/airport/registration');

    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registration.toJson()),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final responseCode = json['responseCode'];
        final errorMessage = json['responseMessage'] ?? 'Ismeretlen hiba';

        if (responseCode != null) {
          AwesomeDialog(
            context: context,
            width: 300,
            dialogType: DialogType.error,
            title: 'Sikertelen regisztráció',
            desc: errorMessage,
          ).show();
          return null;
        } else {
          final json = jsonDecode(response.body);
          return json['responseContent']['authorizationToken'];
        }
      } else {
        String errorMessage = 'Ismeretlen hiba';
        try {
          final json = jsonDecode(response.body);
          errorMessage = json['responseMessage'] ?? errorMessage;
        } catch (_) {}
        AwesomeDialog(
          context: context,
          width: 300,
          dialogType: DialogType.error,
          title: 'Sikertelen regisztráció',
          desc: errorMessage,
        ).show();
        return null;
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        width: 300,
        dialogType: DialogType.error,
        title: 'Sikertelen regisztráció',
        desc: "Hálózati hiba",
      ).show();
      return null;
    }
  }

  /// Ügyfél bejelentkeztetése
  Future<LoginData?> loginUser(
      BuildContext context, String loginName, String password) async {
    final uri = Uri.http(baseUrl, '/service/v2/auth/login');

    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'LoginName': loginName,
          'Password': password,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final LoginData loginData = LoginData.fromJson(json['responseContent']);
        return loginData;
      } else {
        final errorMessage =
            jsonDecode(response.body)['responseMessage'] ?? 'Ismeretlen hiba';
        AwesomeDialog(
          context: context,
          width: 300,
          dialogType: DialogType.error,
          title: 'Bejelentkezési hiba',
          desc: errorMessage,
        ).show();
        return null;
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        width: 300,
        dialogType: DialogType.error,
        title: 'Sikertelen bejelentkezés',
        desc: e.toString(),
      ).show();
      return null;
    }
  }

  /// Foglalás rögzítése
  Future<void> submitReservation(
      BuildContext context, Reservation reservation, String? token) async {
    final uri = Uri.http(baseUrl, '/service/v1/airport/reserve');

    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$token',
        },
        body: jsonEncode(reservation.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
      } else {
        final errorMessage =
            jsonDecode(response.body)['responseMessage'] ?? 'Ismeretlen hiba';
        AwesomeDialog(
          context: context,
          width: 300,
          dialogType: DialogType.error,
          title: "Foglalás rögzítése sikertelen",
          desc: errorMessage,
        ).show();
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        width: 300,
        dialogType: DialogType.error,
        title: 'Foglalás rögzítése sikertelen',
        desc: e.toString(),
      ).show();
    }
  }

  /// Foglalások lekérdezése
  Future<List<dynamic>?> getReservations(BuildContext context) async {
    final uri = Uri.http(baseUrl, '/service/v1/airport/webparkings');

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$ReceptionistToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List reservations = data['responseContent'];
        return reservations;
      } else {
        final errorMessage =
            jsonDecode(response.body)['responseMessage'] ?? 'Ismeretlen hiba';
        AwesomeDialog(
          context: context,
          width: 300,
          dialogType: DialogType.error,
          title: "Foglalások lekérése sikertelen",
          desc: errorMessage,
        ).show();
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        width: 300,
        dialogType: DialogType.error,
        title: 'Foglalások lekérése sikertelen',
        desc: e.toString(),
      ).show();
    }
    return null;
  }

  /// Általános Lista Panel lekérdezés
  Future<List<dynamic>?> fetchListPanelData({
    required BuildContext context,
    required String? token,
    required int listPanelId,
    required String errorDialogTitle,
  }) async {
    final uri = Uri.http(baseUrl, '/service/v1/eslist/query');
    final listPanelQuery = createListPanelDataQuery(listPanelId);

    try {
      final request = http.Request("GET", uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': '$token',
        })
        ..body = jsonEncode(listPanelQuery);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final content = data['responseContent'];
        final List result = content['Data'] as List;
        return result;
      } else {
        final responseBody = json.decode(response.body);
        final errorMessage =
            responseBody['responseMessage'] ?? 'Ismeretlen hiba';
        AwesomeDialog(
          context: context,
          width: 300,
          dialogType: DialogType.error,
          title: errorDialogTitle,
          desc: errorMessage,
        ).show();
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        width: 300,
        dialogType: DialogType.error,
        title: errorDialogTitle,
        desc: "Hálózati hiba: $e",
      ).show();
    }
    return null;
  }

  /// Szolgáltatások lekérdezése
  Future<List<ServiceTemplate>?> getServiceTemplates(
      BuildContext context, String token) async {
    final data = await fetchListPanelData(
      context: context,
      token: token,
      listPanelId: 100,
      errorDialogTitle: 'Szolgáltatások lekérdezése sikertelen',
    );
    if (data == null) return [];
    return data
        .map<ServiceTemplate>((json) => ServiceTemplate.fromJson(json))
        .toList();
  }

  /// Fizetési módok lekérése
  Future<List<PayType>?> getPayTypes(BuildContext context, String token) async {
    final data = await fetchListPanelData(
      context: context,
      token: token,
      listPanelId: 102,
      errorDialogTitle: 'Fizetési módok lekérdezése sikertelen',
    );
    if (data == null) return [];
    return data.map<PayType>((json) => PayType.fromJson(json)).toList();
  }

  /// Érvényes foglalások lekérése
  Future<List<ValidReservation>?> getValidReservations(
      BuildContext context) async {
    final data = await fetchListPanelData(
      context: context,
      token: ReceptionistToken,
      listPanelId: 107,
      errorDialogTitle: 'Érvényes foglalások lekérdezése sikertelen',
    );
    if (data == null) return [];
    return data
        .map<ValidReservation>((json) => ValidReservation.fromJson(json))
        .toList();
  }

  /// Vissza adja a helyes fiókot personId alapján
  Future<UserData?> getUserData(BuildContext context, String personId) async {
    final allUserDataJson = await fetchListPanelData(
      context: context,
      token: ReceptionistToken,
      listPanelId: 103,
      errorDialogTitle: 'Felhasználói fiókok lekérdezése sikertelen',
    );
    if (allUserDataJson == null || allUserDataJson.isEmpty) return null;
    final allUserData = allUserDataJson
        .map<UserData>((json) => UserData.fromJson(json))
        .toList();
    try {
      return allUserData.firstWhere((data) => data.personId == personId);
    } catch (e) {
      return null; // ha nincs ilyen personId
    }
  }

  /// Ügyfél érkeztetése
  Future<void> logCustomerArrival(
      BuildContext context, String licensePlateNumber) async {
    final uri = Uri.http(baseUrl, '/service/v1/airport/arriving');

    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$ReceptionistToken',
        },
        body: jsonEncode(licensePlateNumber),
      );

      final responseBody = json.decode(response.body);
      final responseStatusCode = responseBody['responseStatusCode'];
      final errorMessage = responseBody['responseMessage'];

      if (response.statusCode == 200 && responseStatusCode == 200) {
        AwesomeDialog(
          context: context,
          width: 300,
          dialogType: DialogType.success,
          title: 'Sikeres érkeztetés',
          desc: licensePlateNumber,
        ).show();
      } else {
        AwesomeDialog(
          context: context,
          width: 300,
          dialogType: DialogType.error,
          title: 'Sikertelen érkeztetés',
          desc: errorMessage,
        ).show();
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        width: 300,
        dialogType: DialogType.error,
        title: 'Sikertelen érkeztetés',
        desc: "Hálózati hiba",
      ).show();
    }
  }

  /// Ügyfél kiléptetése
  Future<void> logCustomerLeave(
      BuildContext context, String licensePlateNumber) async {
    final uri = Uri.http(baseUrl, '/service/v1/airport/leaving');

    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$ReceptionistToken',
        },
        body: jsonEncode(licensePlateNumber),
      );

      final responseBody = json.decode(response.body);
      final responseStatusCode = responseBody['responseStatusCode'];
      final errorMessage = responseBody['responseMessage'];

      if (responseStatusCode == 200) {
        AwesomeDialog(
          context: context,
          width: 300,
          dialogType: DialogType.success,
          title: 'Sikeres kiléptetés',
          desc: licensePlateNumber,
        ).show();
      } else {
        AwesomeDialog(
          context: context,
          width: 300,
          dialogType: DialogType.error,
          title: 'Sikertelen kiléptetés',
          desc: errorMessage,
        ).show();
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        width: 300,
        dialogType: DialogType.error,
        title: 'Sikertelen kiléptetés',
        desc: "Hálózati hiba",
      ).show();
    }
  }

  /// Parkoló zóna árak lekérdezése
  Future<List<dynamic>?> getParkingPrices(
      BuildContext context,
      String? token,
      DateTime beginInterval,
      DateTime endInterval,
      String partnerId,
      String payTypeId) async {
    final uri = Uri.http(baseUrl, '/service/v1/airport/getparkingprices');

    try {
      final response = await client.post(uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': '$token',
          },
          body: jsonEncode({
            "BeginIntervall": formatDateTime(beginInterval),
            "EndIntervall": formatDateTime(endInterval),
            "PartnerId": partnerId,
            "PayTypeId": payTypeId,
          }));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List parkingPrices = data['responseContent'];
        return parkingPrices;
      } else {
        print('HTTP hibakód: ${response.statusCode}');
        print('Response body: ${response.body}');

        final responseBody = json.decode(response.body);
        final errorMessage =
            responseBody['responseMessage'] ?? 'Ismeretlen hiba';
        AwesomeDialog(
          context: context,
          width: 300,
          dialogType: DialogType.error,
          title: 'Árak lekérdezése sikertelen',
          desc: errorMessage,
        ).show();
        return null;
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        width: 300,
        dialogType: DialogType.error,
        title: 'Árak lekérdezése sikertelen',
        desc: "Hálózati hiba: $e",
      ).show();
    }
    return null;
  }

  String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat("yyyy-MM-ddTHH:mm:ss");
    return formatter.format(dateTime);
  }

  Map<String, dynamic> createListPanelDataQuery(int listPanelId) {
    return {
      "ListPanelId": listPanelId,
      "Skip": null,
      "Take": null,
      "Filter": [
        {
          "FieldName": "",
          "FieldValue": "",
          "IntervalBegin": "",
          "IntervalEnd": "",
          "FilterType": "",
          "ConnectType": ""
        }
      ]
    };
  }
}
