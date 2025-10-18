class AvailableListPanel {
  final String listPanelName;
  final int disrtibutedId;

  AvailableListPanel({
    required this.listPanelName,
    required this.disrtibutedId,
  });

  Map<String, dynamic> toJson() {
    return {
      "listPanelName": listPanelName,
      "distributedId": disrtibutedId,
    };
  }

  factory AvailableListPanel.fromJson(Map<String, dynamic> json) {
    return AvailableListPanel(
      listPanelName: json['listPanelName'],
      disrtibutedId: json['distributedId'],
    );
  }
}
