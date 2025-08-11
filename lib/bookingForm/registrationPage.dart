// ignore_for_file: file_names

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
            FocusScope.of(context).unfocus();
          },
          decoration: const InputDecoration(labelText: 'Kedvenc rendszám'),
        ),
        switch (widget.bookingOption) {
          BookingOption.parking => NextPageButton(
              title: "Parkolás foglalás",
              nextPage: ParkOrderPage(
                bookingOption: widget.bookingOption,
                emailController: emailController,
                licensePlateController: favoriteLicensePlateNumberController,
                nameController: nameController,
              )),
          BookingOption.washing => NextPageButton(
              title: "Mosás foglalás",
              nextPage: WashOrderPage(
                bookingOption: widget.bookingOption,
                emailController: emailController,
                licensePlateController: favoriteLicensePlateNumberController,
                nameController: nameController,
              )),
          BookingOption.both => NextPageButton(
              title: "Parkolás foglalás",
              nextPage: ParkOrderPage(
                bookingOption: widget.bookingOption,
                emailController: emailController,
                licensePlateController: favoriteLicensePlateNumberController,
                nameController: nameController,
              )),
        }
      ],
    );
  }
}
