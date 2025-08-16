import 'package:airport_test/api_Services/api_service.dart';
import 'package:airport_test/constantWidgets.dart';
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
  final formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();

  String? authToken;

  Future<String?> LoginUser() async {
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

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      final token = await LoginUser();
      if (token != null) {
        Widget nextPage;
        switch (widget.bookingOption) {
          case BookingOption.parking:
          case BookingOption.both:
            nextPage = ParkOrderPage(
              authToken: authToken!,
              bookingOption: widget.bookingOption,
              emailController: emailController,
            );
            break;
          case BookingOption.washing:
            nextPage = WashOrderPage(
              authToken: authToken!,
              bookingOption: widget.bookingOption,
              emailController: emailController,
            );
            break;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BasePage(
              title: widget.bookingOption == BookingOption.washing
                  ? "Mosás foglalás"
                  : "Parkolás foglalás",
              child: nextPage,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sikertelen Bejelentkezés!')),
        );
      }
    }
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
    return Form(
        key: formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 20),
          MyTextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Adja meg email címét';
              }
              return null;
            },
            controller: emailController,
            focusNode: emailFocus,
            textInputAction: TextInputAction.next,
            nextFocus: passwordFocus,
            labelText: 'Email cím',
          ),
          SizedBox(
            height: 10,
          ),
          MyTextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Adjon meg egy jelszót';
              }
              return null;
            },
            controller: passwordController,
            obscureText: true,
            focusNode: passwordFocus,
            textInputAction: TextInputAction.next,
            nextFocus: nextPageButtonFocus,
            labelText: 'Jelszó',
          ),
          NextPageButton(
            title: widget.bookingOption == BookingOption.washing
                ? "Mosás foglalás"
                : "Parkolás foglalás",
            focusNode: nextPageButtonFocus,
            onPressed: OnNextPageButtonPressed,
          ),
        ]));
  }
}
