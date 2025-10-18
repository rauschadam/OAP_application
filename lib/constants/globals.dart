// Ebben a fájlban tároljuk a globális változókat

import 'package:airport_test/api_services/api_classes/car_wash_service.dart';
import 'package:airport_test/api_services/api_classes/available_list_panel.dart';
import 'package:airport_test/api_services/api_classes/pay_type.dart';
import 'package:airport_test/api_services/api_classes/service_templates.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> GlobalNavigatorKey =
    GlobalKey<NavigatorState>();

BuildContext? get GlobalContext => GlobalNavigatorKey.currentContext;

/// Recepciós email-címe, amellyel bejelentkezett
String? ReceptionistEmail;

/// Recepciós jelszava, amellyel bejelentkezett
String? ReceptionistPassword;

/// Recepciós saját tokenje
String? ReceptionistToken;

/// A token lejárata
DateTime? TokenExpiration;

/// Elérhető lista panelek
List<AvailableListPanel> AvailableListPanels = [];

/// Elindításkor megnézi, hogy mobilról van-e megnyitva.
/// True -> Mobil | False -> Desktop
bool? IsMobile;

/// Az applikáció elindításakor lekért fizetési módok.
// A fizetési módokat CSAK az elindításkor kérjük le.
// Így, ha változás van, újrakell indítani az appot.
List<PayType> PayTypes = [];

/// Az applikáció elindításakor lekért szolgáltatások.
// A szolgáltatásokat CSAK az elindításkor kérjük le.
// Így, ha változás van, újrakell indítani az appot.
List<ServiceTemplate> ServiceTemplates = [];

List<CarWashService> CarWashServices = [];
