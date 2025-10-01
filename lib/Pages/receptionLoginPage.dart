import 'package:airport_test/Pages/homePage.dart';
import 'package:airport_test/api_services/api_classes/login_data.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_text_form_field.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class ReceptionLoginPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Recepciós bejelentkezés';

  const ReceptionLoginPage({super.key});

  @override
  State<ReceptionLoginPage> createState() => _ReceptionLoginPageState();
}

class _ReceptionLoginPageState extends State<ReceptionLoginPage> {
  final formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();

  /// Jelszó elrejtése
  bool obscurePassword = true;

  /// Recepciós bejelentkeztetése
  /// TODO: Ezt most úgy tesszük meg mintha usert loginelnénk, pedig nem
  Future<LoginData?> loginReceptionist() async {
    final api = ApiService();
    final LoginData? loginData =
        //await api.loginUser(emailController.text, passwordController.text);
        await api.loginUser(
            context, 'receptionAdmin@gmail.com', 'AdminPassword1');

    if (loginData != null) {
      setState(() {
        receptionistToken = loginData.authorizationToken;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BasePage(
            child: HomePage(),
          ),
        ),
      );
    }
    return loginData;
  }

  @override
  void initState() {
    super.initState();

    loginReceptionist();

    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(emailFocus);
    });
  }

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      final LoginData? loginData = await loginReceptionist();
      if (loginData != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BasePage(
              child: HomePage(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTextFormFields(),
          NextPageButton(
            focusNode: nextPageButtonFocus,
            onPressed: OnNextPageButtonPressed,
          ),
        ],
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
              return 'Adja meg jelszavát';
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
