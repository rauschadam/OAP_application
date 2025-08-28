import 'package:airport_test/api_Services/api_service.dart';
import 'package:airport_test/constantWidgets.dart';
import 'package:airport_test/bookingForm/registrationOptionPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';

class GetReservationsPage extends StatefulWidget implements PageWithTitle {
  @override
  String get pageTitle => 'Foglalások lekérdezése';

  final String authToken;

  const GetReservationsPage({super.key, required this.authToken});

  @override
  State<GetReservationsPage> createState() => GetReservationsPageState();
}

class GetReservationsPageState extends State<GetReservationsPage> {
  List<dynamic>? reservations;

  Future<void> fetchReservations() async {
    final api = ApiService();
    final data = await api.getReservations(widget.authToken);

    if (data == null) {
      print('Nem sikerült a lekérdezés');
    } else {
      setState(() {
        reservations = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: fetchReservations,
          child: const Text("Foglalások lekérése"),
        ),
        if (reservations != null)
          Expanded(
            child: ListView.builder(
              itemCount: reservations!.length,
              itemBuilder: (context, index) {
                final r = reservations![index];
                return ListTile(
                  title: Text("ID: ${r['WebParkingId']}"),
                  subtitle: Text("Név: ${r['Name']}"),
                );
              },
            ),
          ),
      ],
    );
  }
}
