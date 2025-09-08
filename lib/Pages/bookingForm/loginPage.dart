import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/Pages/bookingForm/parkOrderPage.dart';
import 'package:airport_test/Pages/bookingForm/washOrderPage.dart';
import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/constant_widgets/my_text_form_field.dart';
import 'package:airport_test/constants/constant_widgets/next_page_button.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Bejelentkezés';

  final BookingOption bookingOption;
  final bool alreadyRegistered;
  final bool withoutRegistration;
  const LoginPage(
      {super.key,
      required this.bookingOption,
      required this.alreadyRegistered,
      required this.withoutRegistration});

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

  Future<String?> loginUser() async {
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
      final token = await loginUser();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sikertelen Bejelentkezés!')),
        );
      } else {
        Widget nextPage;
        switch (widget.bookingOption) {
          case BookingOption.parking:
          case BookingOption.both:
            nextPage = ParkOrderPage(
              authToken: authToken!,
              bookingOption: widget.bookingOption,
              emailController: emailController,
              alreadyRegistered: widget.alreadyRegistered,
              withoutRegistration: widget.withoutRegistration,
            );
            break;
          case BookingOption.washing:
            nextPage = WashOrderPage(
              authToken: authToken!,
              bookingOption: widget.bookingOption,
              emailController: emailController,
              alreadyRegistered: widget.alreadyRegistered,
              withoutRegistration: widget.withoutRegistration,
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
            hintText: 'Jelszó',
            onEditingComplete: OnNextPageButtonPressed,
          ),
          NextPageButton(
            focusNode: nextPageButtonFocus,
            onPressed: OnNextPageButtonPressed,
          ),
        ]));
  }
}
