import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/registration.dart';
import 'package:airport_test/constants/constant_widgets.dart';
import 'package:airport_test/bookingForm/parkOrderPage.dart';
import 'package:airport_test/bookingForm/washOrderPage.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Regisztráció';

  final BookingOption bookingOption;
  final bool alreadyRegistered;
  final bool withoutRegistration;
  const RegistrationPage(
      {super.key,
      required this.bookingOption,
      required this.alreadyRegistered,
      required this.withoutRegistration});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController favoriteLicensePlateNumberController =
      TextEditingController();

  FocusNode nameFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode confirmPasswordFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode favoriteLicensePlateNumberFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();

  String? authToken;

  bool obscurePassword = true;

  Future<String?> RegisterUser() async {
    final registration = Registration(
      name: nameController.text,
      password: passwordController.text,
      email: emailController.text,
      phone: phoneController.text,
      favoriteLicensePlateNumber: favoriteLicensePlateNumberController.text,
    );

    await ApiService().registerUser(registration);

    final api = ApiService();
    final token =
        await api.loginUser(emailController.text, passwordController.text);

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

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      final token = await RegisterUser();
      if (token != null) {
        Widget nextPage;
        switch (widget.bookingOption) {
          case BookingOption.parking:
          case BookingOption.both:
            nextPage = ParkOrderPage(
              authToken: authToken!,
              bookingOption: widget.bookingOption,
              emailController: emailController,
              licensePlateController: favoriteLicensePlateNumberController,
              nameController: nameController,
              phoneController: phoneController,
              alreadyRegistered: widget.alreadyRegistered,
              withoutRegistration: widget.withoutRegistration,
            );
            break;
          case BookingOption.washing:
            nextPage = WashOrderPage(
              authToken: authToken!,
              bookingOption: widget.bookingOption,
              emailController: emailController,
              licensePlateController: favoriteLicensePlateNumberController,
              nameController: nameController,
              phoneController: phoneController,
              alreadyRegistered: widget.alreadyRegistered,
              withoutRegistration: widget.withoutRegistration,
            );
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sikeres regisztráció!')),
        );

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
          const SnackBar(content: Text('Sikertelen regisztráció!')),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            nextFocus: confirmPasswordFocus,
            hintText: 'Jelszó',
          ),
          SizedBox(height: 10),
          MyTextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Adjon meg egy jelszót';
              } else if (confirmPasswordController.text !=
                  passwordController.text) {
                return 'A jelszó nem egyezik';
              }
              return null;
            },
            controller: confirmPasswordController,
            obscureText: obscurePassword,
            onObscureToggle: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
            focusNode: confirmPasswordFocus,
            textInputAction: TextInputAction.next,
            nextFocus: nameFocus,
            hintText: 'Jelszó megerősítése',
          ),
          SizedBox(height: 10),
          MyTextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Adjon meg egy felhasználó nevet';
              }
              return null;
            },
            controller: nameController,
            focusNode: nameFocus,
            textInputAction: TextInputAction.next,
            nextFocus: phoneFocus,
            hintText: 'Felhasználó név',
          ),
          SizedBox(height: 10),
          MyTextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Adja meg telefonszámát';
                } else if (phoneController.text.length < 10) {
                  return 'Hibás telefonszám';
                }
                return null;
              },
              controller: phoneController,
              focusNode: phoneFocus,
              textInputAction: TextInputAction.next,
              nextFocus: favoriteLicensePlateNumberFocus,
              hintText: 'Telefonszám',
              selectedTextFormFieldType: MyTextFormFieldType.phone),
          SizedBox(height: 10),
          MyTextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Adja meg kedvenc rendszámát';
              }
              return null;
            },
            controller: favoriteLicensePlateNumberController,
            focusNode: favoriteLicensePlateNumberFocus,
            textInputAction: TextInputAction.done,
            nextFocus: nextPageButtonFocus,
            hintText: 'Kedvenc rendszám',
            selectedTextFormFieldType: MyTextFormFieldType.licensePlate,
            onEditingComplete: OnNextPageButtonPressed,
          ),
          SizedBox(height: 10),
          NextPageButton(
            focusNode: nextPageButtonFocus,
            onPressed: OnNextPageButtonPressed,
          ),
        ],
      ),
    );
  }
}
