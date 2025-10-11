import 'dart:async';

import 'package:airport_test/api_services/api_classes/login_data.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/globals.dart';

/// A recepciós első bejelentkezése után automatikusan frissítjük a tokent, a lejárata előtt 1 perccel
class AuthManager {
  static Timer? refreshTimer;

  static void setLoginData(LoginData data) {
    ReceptionistToken = data.authorizationToken;
    TokenExpiration = data.expiration;

    scheduleTokenRefresh();
  }

  static void scheduleTokenRefresh() {
    refreshTimer?.cancel();

    if (TokenExpiration == null) return;

    // Frissítés 1 perccel a lejárat előtt
    final now = DateTime.now();
    final refreshTime = TokenExpiration!.subtract(const Duration(minutes: 1));

    final duration = refreshTime.isAfter(now)
        ? refreshTime.difference(now)
        : const Duration(seconds: 5);

    refreshTimer = Timer(duration, refreshToken);
  }

  static Future<void> refreshToken() async {
    if (ReceptionistToken == null || GlobalContext == null) return;

    try {
      final updatedLoginData = await ApiService().loginUser(
        GlobalContext!,
        ReceptionistEmail!,
        ReceptionistPassword!,
      );

      if (updatedLoginData != null) {
        setLoginData(updatedLoginData);
      }
    } catch (e) {
      print('Token refresh hiba: $e');
    }
  }
}
