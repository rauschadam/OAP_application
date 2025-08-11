// ignore_for_file: file_names

import 'package:airport_test/api_Services/api_service.dart';
import 'package:airport_test/api_Services/registration.dart';
import 'package:airport_test/basePage.dart';
import 'package:airport_test/bookingForm/parkOrderPage.dart';
import 'package:airport_test/bookingForm/washOrderPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  final BookingOption bookingOption;
  const RegistrationPage({super.key, required this.bookingOption});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController favoriteLicensePlateNumberController =
      TextEditingController();

  FocusNode nameFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode favoriteLicensePlateNumberFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();

  String? authToken;

  Future<String?> RegisterUser() async {
    // Regisztráljuk
    final registration = Registration(
        name: nameController.text,
        password: passwordController.text,
        email: emailController.text,
        phone: phoneController.text,
        favoriteLicensePlateNumber: favoriteLicensePlateNumberController.text);

    await ApiService().registerUser(registration);

    // Bejelentkeztetjük
    final api = ApiService();
    final token = await api.loginUser('abc@valami.hu', 'asdasd');

    if (token == null) {
      print('Nem sikerült bejelentkezni');
    } else {
      setState(() {
        authToken = token;
        print(authToken);
      });
    }

    return token;
  }

  @override
  void initState() {
    super.initState();
    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(nameFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          focusNode: nameFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(passwordFocus);
          },
          decoration: const InputDecoration(labelText: 'Felhasználó név'),
        ),
        TextField(
          controller: passwordController,
          obscureText: true,
          focusNode: passwordFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(emailFocus);
          },
          decoration: const InputDecoration(labelText: 'Jelszó'),
        ),
        TextField(
          controller: emailController,
          focusNode: emailFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(phoneFocus);
          },
          decoration: const InputDecoration(labelText: 'Email cím'),
        ),
        TextField(
          controller: phoneController,
          focusNode: phoneFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            FocusScope.of(context)
                .requestFocus(favoriteLicensePlateNumberFocus);
          },
          decoration: const InputDecoration(labelText: 'Telefonszám'),
        ),
        TextField(
          controller: favoriteLicensePlateNumberController,
          focusNode: favoriteLicensePlateNumberFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(nextPageButtonFocus);
          },
          decoration: const InputDecoration(labelText: 'Kedvenc rendszám'),
        ),
        switch (widget.bookingOption) {
          BookingOption.parking => NextPageButton(
              title: "Parkolás foglalás",
              focusNode: nextPageButtonFocus,
              onPressed: () async {
                final token = await RegisterUser();
                if (token != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BasePage(
                          title: "Parkolás foglalás",
                          child: ParkOrderPage(
                            authToken: authToken!,
                            bookingOption: widget.bookingOption,
                            emailController: emailController,
                            licensePlateController:
                                favoriteLicensePlateNumberController,
                            nameController: nameController,
                            phoneController: phoneController,
                          )),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sikertelen regisztráció!')),
                  );
                }
              },
            ),
          BookingOption.washing => NextPageButton(
              title: "Mosás foglalás",
              focusNode: nextPageButtonFocus,
              onPressed: () async {
                final token = await RegisterUser();
                if (token != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BasePage(
                          title: "Parkolás foglalás",
                          child: WashOrderPage(
                            authToken: authToken!,
                            bookingOption: widget.bookingOption,
                            emailController: emailController,
                            licensePlateController:
                                favoriteLicensePlateNumberController,
                            nameController: nameController,
                            phoneController: phoneController,
                          )),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sikertelen regisztráció!')),
                  );
                }
              },
            ),
          BookingOption.both => NextPageButton(
              title: "Parkolás foglalás",
              focusNode: nextPageButtonFocus,
              onPressed: () async {
                final token = await RegisterUser();
                if (token != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BasePage(
                          title: "Parkolás foglalás",
                          child: ParkOrderPage(
                            authToken: authToken!,
                            bookingOption: widget.bookingOption,
                            emailController: emailController,
                            licensePlateController:
                                favoriteLicensePlateNumberController,
                            nameController: nameController,
                            phoneController: phoneController,
                          )),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sikertelen regisztráció!')),
                  );
                }
              },
            ),
        }
      ],
    );
  }
}
