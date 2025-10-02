// Ebben a fájlban tároljuk a globális változókat

import 'package:airport_test/api_services/api_classes/pay_type.dart';
import 'package:airport_test/api_services/api_classes/service_templates.dart';

/// Recepciós saját tokenje
String? ReceptionistToken;

/// Elindításkor megnézi, hogy mobilról van-e megnyitva.
/// True -> Mobil | False -> Desktop
bool? IsMobile;

List<PayType> PayTypes = [];

List<ServiceTemplate> ServiceTemplates = [];
