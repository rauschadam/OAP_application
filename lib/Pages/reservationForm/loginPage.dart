import 'package:airport_test/Pages/reservationForm/parkOrderPage.dart';
import 'package:airport_test/Pages/reservationForm/washOrderPage.dart';
import 'package:airport_test/api_services/api_classes/login_data.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_text_form_field.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
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

  /// Jelszó elrejtése
  bool obscurePassword = true;

  Future<LoginData?> loginUser() async {
    final api = ApiService();
    final LoginData? loginData = await api.loginUser(
        context, emailController.text, passwordController.text);
    return loginData;
  }

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      final loginData = await loginUser();
      if (loginData != null) {
        Widget nextPage;
        switch (widget.bookingOption) {
          case BookingOption.parking:
          case BookingOption.both:
            nextPage = ParkOrderPage(
              authToken: loginData.authorizationToken,
              personId: loginData.personId,
              partnerId: loginData.partnerId,
              bookingOption: widget.bookingOption,
              emailController: emailController,
              alreadyRegistered: widget.alreadyRegistered,
              withoutRegistration: widget.withoutRegistration,
            );
            break;
          case BookingOption.washing:
            nextPage = WashOrderPage(
              authToken: loginData.authorizationToken,
              personId: loginData.personId,
              partnerId: loginData.partnerId,
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
            builder: (_) => nextPage,
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
    return BasePage(
      pageTitle: "Bejelentkezés",
      haveMargins: true,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTextFormFields(),
              NextPageButton(
                focusNode: nextPageButtonFocus,
                onPressed: OnNextPageButtonPressed,
                pushReplacement: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextFormFields() {
    final double sizedBoxHeight = 10;
    return Column(
      children: [
        SizedBox(height: sizedBoxHeight),
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
        SizedBox(height: sizedBoxHeight),
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
      ],
    );
  }
}
