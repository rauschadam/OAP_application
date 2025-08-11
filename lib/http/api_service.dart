import 'dart:convert';
import 'package:airport_test/http/Reservation.dart';
import 'package:airport_test/http/registration.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = '192.168.100.3:9013';
  final http.Client client = http.Client();

  /// Regisztráció
  Future<String?> registerUser(Registration registration) async {
    final uri = Uri.http(baseUrl, '/service/v1/airport/registration');

    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registration.toJson()),
      );

      if (response.statusCode == 200) {
        print('Sikeres Regisztráció!');
        final json = jsonDecode(response.body);
        return json['responseContent']['authorizationToken'];
      } else {
        print('Regisztrációs hiba: ${response.statusCode}');
        print(response.body);
        return null;
      }
    } catch (e) {
      print('Hálózati hiba: $e');
      return null;
    }
  }

  /// Bejelentkezés
  Future<String?> loginUser(String loginName, String password) async {
    final uri = Uri.http(baseUrl, '/service/v1/auth/login');

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
        print('Sikeres bejelentkezés!');
        final json = jsonDecode(response.body);
        return json['responseContent']['authorizationToken'];
      } else {
        print('Bejelentkezési hiba: ${response.statusCode}');
        print(response.body);
        return null;
      }
    } catch (e) {
      print('Hálózati hiba: $e');
      return null;
    }
  }

  /// Foglalás
  Future<void> submitReservation(Reservation reservation, String token) async {
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
        print('Sikeres foglalás!');
      } else {
        print('Hiba történt: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      print('Hálózati hiba: $e');
    } finally {
      client.close();
    }
  }
}
