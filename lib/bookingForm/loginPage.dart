import 'package:airport_test/api_Services/api_service.dart';
import 'package:airport_test/constantWidgets.dart';
import 'package:airport_test/bookingForm/parkOrderPage.dart';
import 'package:airport_test/bookingForm/washOrderPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget implements PageWithTitle {
  @override
  String get pageTitle => 'Bejelentkezés';

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

  bool obscurePassword = true;

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
          SizedBox(height: 10),
          MyTextFormField(
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Adja meg email-címét';
              } else if (!EmailValidator.validate(value.trim())) {
                return 'Érvénytelen email-cím';
              }
              return null;
            },
            controller: emailController,
            focusNode: emailFocus,
            textInputAction: TextInputAction.next,
            nextFocus: passwordFocus,
            hintText: 'Email cím',
          ),
          SizedBox(height: 10),
          MyTextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Adjon meg egy jelszót';
              }
              return null;
            },
            controller: passwordController,
            obscureText: obscurePassword,
            onObscureToggle: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
            focusNode: passwordFocus,
            textInputAction: TextInputAction.next,
            nextFocus: nextPageButtonFocus,
            hintText: 'Jelszó',
          ),
          NextPageButton(
            focusNode: nextPageButtonFocus,
            onPressed: OnNextPageButtonPressed,
          ),
        ]));
  }
}
