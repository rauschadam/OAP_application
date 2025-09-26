class Registration {
  final String name;
  final String password;
  final String email;
  final String phone;
  final String favoriteLicensePlateNumber;
  final String? taxNumber;
  final String? currencyId;
  final String? payTypeId;
  final String? countryId;

  Registration({
    required this.name,
    required this.password,
    required this.email,
    required this.phone,
    required this.favoriteLicensePlateNumber,
    this.taxNumber,
    this.currencyId,
    this.payTypeId,
    this.countryId,
  });

  Map<String, dynamic> toJson() {
    return {
      "Name": name,
      "Password": password,
      "Email": email,
      "Phone": phone,
      "FavoriteLicensePlateNumber": favoriteLicensePlateNumber,
      "TaxNumber": null,
      "CurrencyId": null,
      "PayTypeId": null,
      "CountryId": null,
    };
  }

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      name: json['Name'],
      password: json['Password'],
      email: json['Email'],
      phone: json['Phone'],
      favoriteLicensePlateNumber: json['FavoriteLicensePlateNumber'],
      taxNumber: json['TaxNumber'],
      currencyId: json['CurrencyId'],
      payTypeId: json['PayTypeId'],
      countryId: json['CountryId'],
    );
  }
}
