import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/constant_widgets.dart';
import 'package:airport_test/bookingForm/bookingOptionPage.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget with PageWithTitle {
  HomePage({super.key});

  @override
  String get pageTitle => 'Menü';

  @override
  bool get showBackButton => false;

  @override
  bool get haveMargins => false;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? authToken;

  Future<String?> loginReceptionist() async {
    final api = ApiService();
    final token =
        await api.loginUser('receptionAdmin@gmail.com', 'AdminPassword1');

    if (token == null) {
      print('Nem sikerült bejelentkezni');
    } else {
      print('token: $token');
      setState(() {
        authToken = token;
      });
      fetchReservations();
    }
    return token;
  }

  /// Lekérdezett foglalások
  List<dynamic>? reservations;

  Future<void> fetchReservations() async {
    final api = ApiService();
    final data = await api.getReservations(authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        reservations = data;
      });
      fetchServiceTemplates();
    }
  }

  /// Lekérdezett szolgáltatások
  List<dynamic>? serviceTemplates;

  Future<void> fetchServiceTemplates() async {
    final api = ApiService();
    final data = await api.getServiceTemplates(authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        serviceTemplates = data;
      });
      zoneCounters =
          mapCurrentOccupancyByZones(reservations!, serviceTemplates!);
    }
  }

  Map<String, int> zoneCounters = {};

  // parkoló zóna -> jelenlegi foglalások száma
  Map<String, int> mapCurrentOccupancyByZones(
      List<dynamic> reservations, List<dynamic> serviceTemplates) {
    // mostani idő lekerekítve félórára
    final now = DateTime.now();
    final currentSlot = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute - (now.minute % 30),
    );

    for (var reservation in reservations) {
      final parkingArticleId = reservation['ParkingArticleId'];
      if (parkingArticleId == null || parkingArticleId == "") continue;

      final arrive = DateTime.parse(reservation['ArriveDate']);
      final leave = DateTime.parse(reservation['LeaveDate']);

      // Megnézi hogy a foglalás szerint most itt van-e az autó
      if (!currentSlot.isBefore(arrive) && currentSlot.isBefore(leave)) {
        zoneCounters[parkingArticleId] =
            (zoneCounters[parkingArticleId] ?? 0) + 1;
      }
    }

    return zoneCounters;
  }

  Widget buildZoneOccupancyIndicators({
    required List<dynamic> serviceTemplates,
    required Map<String, int> zoneCounters,
  }) {
    final parkingTemplates =
        serviceTemplates.where((t) => t['ParkingServiceType'] == 1).toList();

    return Wrap(
      spacing: 20,
      children: [
        for (var template in parkingTemplates)
          ZoneOccupancyIndicator(
            zoneName: template['ParkingServiceName'].split(' ').last,
            occupied: zoneCounters[template['ArticleId']] ?? 0,
            capacity: template['ZoneCapacity'],
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    loginReceptionist();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (serviceTemplates != null && reservations != null)
                  buildZoneOccupancyIndicators(
                    serviceTemplates: serviceTemplates!,
                    zoneCounters: zoneCounters,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: MyIconButton(
                icon: Icons.add_rounded,
                labelText: "Foglalás rögzítése",
                onPressed: () {
                  BasePage.defaultColors = AppColors.blue;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BasePage(
                        child: BookingOptionPage(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }
}
