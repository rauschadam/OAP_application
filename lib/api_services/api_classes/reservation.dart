import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:flutter_riverpod/legacy.dart';

class ReservationFormState {
  // Hitelesítés / Felhasználó
  final String authToken;
  final String partnerId;
  final String personId;
  final bool alreadyRegistered;
  final bool withoutRegistration;
  final BookingOption bookingOption;

  // Személyes adatok
  final String name;
  final String email;
  final String phone;
  final String licensePlate;

  // Parkolási adatok
  final DateTime? arriveDate;
  final DateTime? leaveDate;
  final String? parkingArticleId;
  final int transferPersonCount;
  final bool vip;
  final int suitcaseWrappingCount;
  final int parkingCost; // A parkolás teljes költsége

  // Mosási adatok
  final String? carWashArticleId;
  final DateTime? washDateTime;

  // Végső adatok
  final String payTypeId;
  final String description;

  ReservationFormState({
    this.authToken = '',
    this.partnerId = '',
    this.personId = '',
    this.alreadyRegistered = false,
    this.withoutRegistration = false,
    this.bookingOption = BookingOption.parking,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.licensePlate = '',
    this.arriveDate,
    this.leaveDate,
    this.parkingArticleId,
    this.transferPersonCount = 1,
    this.vip = false,
    this.suitcaseWrappingCount = 0,
    this.parkingCost = 0,
    this.carWashArticleId,
    this.washDateTime,
    this.payTypeId = '',
    this.description = '',
  });

  ReservationFormState copyWith({
    String? authToken,
    String? partnerId,
    String? personId,
    bool? alreadyRegistered,
    bool? withoutRegistration,
    BookingOption? bookingOption,
    String? name,
    String? email,
    String? phone,
    String? licensePlate,
    DateTime? arriveDate,
    DateTime? leaveDate,
    String? parkingArticleId,
    int? transferPersonCount,
    bool? vip,
    int? suitcaseWrappingCount,
    int? parkingCost,
    String? carWashArticleId,
    DateTime? washDateTime,
    String? payTypeId,
    String? description,
  }) {
    return ReservationFormState(
      authToken: authToken ?? this.authToken,
      partnerId: partnerId ?? this.partnerId,
      personId: personId ?? this.personId,
      alreadyRegistered: alreadyRegistered ?? this.alreadyRegistered,
      withoutRegistration: withoutRegistration ?? this.withoutRegistration,
      bookingOption: bookingOption ?? this.bookingOption,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      licensePlate: licensePlate ?? this.licensePlate,
      arriveDate: arriveDate ?? this.arriveDate,
      leaveDate: leaveDate ?? this.leaveDate,
      parkingArticleId: parkingArticleId ?? this.parkingArticleId,
      transferPersonCount: transferPersonCount ?? this.transferPersonCount,
      vip: vip ?? this.vip,
      suitcaseWrappingCount:
          suitcaseWrappingCount ?? this.suitcaseWrappingCount,
      parkingCost: parkingCost ?? this.parkingCost,
      carWashArticleId: carWashArticleId ?? this.carWashArticleId,
      washDateTime: washDateTime ?? this.washDateTime,
      payTypeId: payTypeId ?? this.payTypeId,
      description: description ?? this.description,
    );
  }
}

// Állapotkezelő (Notifier)
class ReservationNotifier extends StateNotifier<ReservationFormState> {
  ReservationNotifier() : super(ReservationFormState());

  // Kezdő beállítások (BookingOption + RegistrationOption)
  void updateOptions({
    required BookingOption bookingOption,
    required bool alreadyRegistered,
    required bool withoutRegistration,
  }) {
    state = state.copyWith(
      bookingOption: bookingOption,
      alreadyRegistered: alreadyRegistered,
      withoutRegistration: withoutRegistration,
    );
  }

  // Hitelesítési adatok (Login / Registration után)
  void updateAuth({
    required String authToken,
    required String partnerId,
    required String personId,
  }) {
    state = state.copyWith(
      authToken: authToken,
      partnerId: partnerId,
      personId: personId,
    );
  }

  // Kapcsolattartási és rendszám adatok
  void updateContactAndLicense({
    required String name,
    required String email,
    required String phone,
    required String licensePlate,
  }) {
    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
      licensePlate: licensePlate,
    );
  }

  // Parkolás adatok
  void updateParking({
    required DateTime arriveDate,
    required DateTime leaveDate,
    required String? parkingArticleId,
    required int transferPersonCount,
    required bool vip,
    required int suitcaseWrappingCount,
    required int parkingCost,
    required String payTypeId,
    required String description,
  }) {
    state = state.copyWith(
      arriveDate: arriveDate,
      leaveDate: leaveDate,
      parkingArticleId: parkingArticleId,
      transferPersonCount: transferPersonCount,
      vip: vip,
      suitcaseWrappingCount: suitcaseWrappingCount,
      parkingCost: parkingCost,
      payTypeId: payTypeId,
      description: description,
    );
  }

  // Mosás adatok
  void updateWash({
    required String? carWashArticleId,
    required DateTime? washDateTime,
    required String payTypeId,
    required String description,
  }) {
    state = state.copyWith(
      carWashArticleId: carWashArticleId,
      washDateTime: washDateTime,
      payTypeId: payTypeId,
      description: description,
    );
  }

// Parkolás adatok resetelése
// (Megadtunk parkolási adatokat aztán rájöttünk hogy csak mosást akarunk)
// A [payTaypeId]-t, [description]-t meghagyjuk
  void resetParking() {
    state = ReservationFormState(
      // Megtartjuk a meglévő, nem-parkolási adatokat
      authToken: state.authToken,
      partnerId: state.partnerId,
      personId: state.personId,
      alreadyRegistered: state.alreadyRegistered,
      withoutRegistration: state.withoutRegistration,
      bookingOption: state.bookingOption,
      name: state.name,
      email: state.email,
      phone: state.phone,
      licensePlate: state.licensePlate,
      carWashArticleId: state.carWashArticleId,
      washDateTime: state.washDateTime,
      payTypeId: state.payTypeId, // Meghagyjuk
      description: state.description, // Meghagyjuk

      // Töröljük/alaphelyzetbe állítjuk a parkolási adatokat
      arriveDate: null,
      leaveDate: null,
      parkingArticleId: null,
      transferPersonCount: 1, // Alapértelmezett
      vip: false, // Alapértelmezett
      suitcaseWrappingCount: 0, // Alapértelmezett
      parkingCost: 0, // Alapértelmezett
    );
  }

  // Mosás adatok
  // (Megadtunk mosási adatokat aztán rájöttünk hogy csak parkolást akarunk)
// A [payTaypeId]-t, [description]-t meghagyjuk
  void resetWash() {
    state = ReservationFormState(
      // Megtartjuk a meglévő, nem-mosási adatokat
      authToken: state.authToken,
      partnerId: state.partnerId,
      personId: state.personId,
      alreadyRegistered: state.alreadyRegistered,
      withoutRegistration: state.withoutRegistration,
      bookingOption: state.bookingOption,
      name: state.name,
      email: state.email,
      phone: state.phone,
      licensePlate: state.licensePlate,
      arriveDate: state.arriveDate,
      leaveDate: state.leaveDate,
      parkingArticleId: state.parkingArticleId,
      transferPersonCount: state.transferPersonCount,
      vip: state.vip,
      suitcaseWrappingCount: state.suitcaseWrappingCount,
      parkingCost: state.parkingCost,
      payTypeId: state.payTypeId, // Meghagyjuk
      description: state.description, // Meghagyjuk

      // Töröljük a mosási adatokat
      carWashArticleId: null,
      washDateTime: null,
    );
  }

  /// Visszaállítja az állapotot a kiinduló helyzetbe
  void resetState() {
    state = ReservationFormState();
  }
}

// Globális Provider
final reservationProvider =
    StateNotifierProvider<ReservationNotifier, ReservationFormState>(
        (ref) => ReservationNotifier());

class Reservation {
  final int parkingService;
  final String partnerId;
  final bool alreadyRegistered;
  final bool withoutRegistration;
  final String name;
  final String email;
  final String phone;
  final String licensePlate;
  final DateTime? arriveDate;
  final DateTime? leaveDate;
  final String? parkingArticleId;
  final String? parkingArticleVolume;
  final int? transferPersonCount;
  final bool vip;
  final int? suitcaseWrappingCount;
  final String? carWashArticleId;
  final DateTime? washDateTime;
  final String payTypeId;
  final String description;
  final bool webReserve;

  Reservation({
    required this.parkingService,
    required this.partnerId,
    required this.alreadyRegistered,
    required this.withoutRegistration,
    required this.name,
    required this.email,
    required this.phone,
    required this.licensePlate,
    required this.arriveDate,
    required this.leaveDate,
    this.parkingArticleId,
    required this.parkingArticleVolume,
    this.transferPersonCount,
    required this.vip,
    this.suitcaseWrappingCount,
    this.carWashArticleId,
    this.washDateTime,
    required this.payTypeId,
    required this.description,
    this.webReserve = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "ParkingService": parkingService,
      "PartnerId": partnerId,
      "AlreadyRegistered": alreadyRegistered,
      "WithoutRegistration": withoutRegistration,
      "Name": name,
      "Email": email,
      "Phone": phone,
      "LicensePlate": licensePlate,
      "ArriveDate": arriveDate?.toIso8601String(),
      "LeaveDate": leaveDate?.toIso8601String(),
      "ParkingArticleId": parkingArticleId,
      "ParkingArticleVolume": parkingArticleVolume,
      "TransferPersonCount": transferPersonCount,
      "VIP": vip,
      "SuitcaseWrappingCount": suitcaseWrappingCount,
      "CarWashArticleId": carWashArticleId,
      "WashDateTime": washDateTime?.toIso8601String(),
      "PayTypeId": payTypeId,
      "Description": description,
    };
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      parkingService: json['ParkingService'],
      partnerId: json['PartnerId'],
      alreadyRegistered: json['AlreadyRegistered'],
      withoutRegistration: json['WithoutRegistration'],
      name: json['Name'],
      email: json['Email'],
      phone: json['Phone'],
      licensePlate: json['LicensePlate'],
      arriveDate: DateTime.parse(json['ArriveDate']),
      leaveDate: DateTime.parse(json['LeaveDate']),
      parkingArticleId: json['ParkingArticleId'],
      parkingArticleVolume: json['ParkingArticleVolume'],
      transferPersonCount: json['TransferPersonCount'],
      vip: json['VIP'],
      suitcaseWrappingCount: json['SuitcaseWrappingCount'],
      carWashArticleId: json['CarWashArticleId'],
      washDateTime: DateTime.parse(json['WashDateTime']),
      payTypeId: json['PayTypeId'],
      description: json['Description'],
    );
  }
}
