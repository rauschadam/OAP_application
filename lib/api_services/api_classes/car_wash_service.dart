class CarWashService {
  final String article_Id;
  final String article_Name;
  final double price;

  CarWashService({
    required this.article_Id,
    required this.article_Name,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      "Article_Id": article_Id,
      "Article_Name": article_Name,
      "Price": price,
    };
  }

  factory CarWashService.fromJson(Map<String, dynamic> json) {
    return CarWashService(
      article_Id: json['Article_Id'],
      article_Name: json['Article_Name'],
      price: json['Price'],
    );
  }
}
