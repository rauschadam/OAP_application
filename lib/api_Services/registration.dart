class Registration {
  final String name;
  final String password;
  final String email;
  final String phone;
  final String favoriteLicensePlateNumber;

  Registration({
    required this.name,
    required this.password,
    required this.email,
    required this.phone,
    required this.favoriteLicensePlateNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      "Name": name,
      "Password": password,
      "Email": email,
      "Phone": phone,
      "FavoriteLicensePlateNumber": favoriteLicensePlateNumber,
    };
  }

  // Ha valaha válaszként kapsz adatot, ezt bővítheted:
  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      name: json['Name'],
      password: json['Password'],
      email: json['Email'],
      phone: json['Phone'],
      favoriteLicensePlateNumber: json['FavoriteLicensePlateNumber'],
    );
  }
}
