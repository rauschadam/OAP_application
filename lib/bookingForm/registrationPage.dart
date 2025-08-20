import 'package:airport_test/api_Services/api_service.dart';
import 'package:airport_test/api_Services/registration.dart';
import 'package:airport_test/constantWidgets.dart';
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
  final formKey = GlobalKey<FormState>();

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
            hintText: 'Email cím',
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
            nextFocus: nameFocus,
            hintText: 'Jelszó',
          ),
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
          MyTextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Adja meg telefonszámát';
              }
              return null;
            },
            controller: phoneController,
            focusNode: phoneFocus,
            textInputAction: TextInputAction.next,
            nextFocus: favoriteLicensePlateNumberFocus,
            hintText: 'Telefonszám',
          ),
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
            forceUppercase: true,
          ),
          SizedBox(height: 20),
          NextPageButton(
            title: widget.bookingOption == BookingOption.washing
                ? "Mosás foglalás"
                : "Parkolás foglalás",
            focusNode: nextPageButtonFocus,
            onPressed: OnNextPageButtonPressed,
          ),
        ],
      ),
    );
  }
}
