class UserData {
  final String personId;
  final String person_Name;
  final String? phone;
  final String email;
  final String? groupNameQuality;

  UserData({
    required this.personId,
    required this.person_Name,
    this.phone,
    required this.email,
    this.groupNameQuality,
  });

  Map<String, dynamic> toJson() {
    return {
      "Person_Id": personId,
      "Person_Name": person_Name,
      "Phone": phone,
      "Email": email,
      "GroupNameQuality": groupNameQuality,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      personId: json['Person_Id'],
      person_Name: json['Person_Name'],
      phone: json['Phone'],
      email: json['Email'],
      groupNameQuality: json['GroupNameQuality'],
    );
  }
}
