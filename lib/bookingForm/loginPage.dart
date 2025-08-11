// ignore_for_file: file_names

import 'package:airport_test/api_Services/api_service.dart';
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

  String? authToken;

  Future<String?> tryLogin() async {
    final api = ApiService();
    final token =
        await api.loginUser(emailController.text, passwordController.text);

    if (token == null) {
      print('Nem sikerült bejelentkezni');
    } else {
      print('token: $token');
      setState(() {
        authToken = token;
      });
    }
    return token;
  }

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
              onPressed: () async {
                final token = await tryLogin();
                if (token != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BasePage(
                        title: "Parkolás foglalás",
                        child: ParkOrderPage(
                          authToken: token,
                          bookingOption: widget.bookingOption,
                          emailController: emailController,
                        ),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sikertelen bejelentkezés!')),
                  );
                }
              },
            ),
          BookingOption.washing => NextPageButton(
              focusNode: nextPageButtonFocus,
              title: "Mosás foglalás",
              onPressed: () async {
                final token = await tryLogin();
                if (token != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BasePage(
                        title: "Mosás foglalás",
                        child: WashOrderPage(
                          authToken: token,
                          bookingOption: widget.bookingOption,
                          emailController: emailController,
                        ),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sikertelen bejelentkezés!')),
                  );
                }
              },
            ),
          BookingOption.both => NextPageButton(
              focusNode: nextPageButtonFocus,
              title: "Parkolás foglalás",
              onPressed: () async {
                final token = await tryLogin();
                if (token != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BasePage(
                        title: "Parkolás foglalás",
                        child: ParkOrderPage(
                          authToken: token,
                          bookingOption: widget.bookingOption,
                          emailController: emailController,
                        ),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sikertelen bejelentkezés!')),
                  );
                }
              },
            ),
        }
      ],
    );
  }
}
