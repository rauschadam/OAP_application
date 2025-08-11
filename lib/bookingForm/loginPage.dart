// ignore_for_file: file_names

import 'package:airport_test/basePage.dart';
import 'package:airport_test/bookingForm/parkOrderPage.dart';
import 'package:airport_test/bookingForm/washOrderPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final BookingOption bookingOption;
  const LoginPage({super.key, required this.bookingOption});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(emailFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: emailController,
          focusNode: emailFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(passwordFocus);
          },
          decoration: const InputDecoration(labelText: 'Email cím'),
        ),
        TextField(
          controller: passwordController,
          obscureText: true,
          focusNode: passwordFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(nextPageButtonFocus);
          },
          decoration: const InputDecoration(labelText: 'Jelszó'),
        ),
        switch (widget.bookingOption) {
          BookingOption.parking => NextPageButton(
              focusNode: nextPageButtonFocus,
              title: "Parkolás foglalás",
              nextPage: ParkOrderPage(
                bookingOption: widget.bookingOption,
                emailController: emailController,
              )),
          BookingOption.washing => NextPageButton(
              focusNode: nextPageButtonFocus,
              title: "Mosás foglalás",
              nextPage: WashOrderPage(
                bookingOption: widget.bookingOption,
                emailController: emailController,
              )),
          BookingOption.both => NextPageButton(
              focusNode: nextPageButtonFocus,
              title: "Parkolás foglalás",
              nextPage: ParkOrderPage(
                bookingOption: widget.bookingOption,
                emailController: emailController,
              )),
        }
      ],
    );
  }
}
