class ListPanelFields {
  final String listFieldName;
  final int? objectId;
  final String? fieldCaption;
  final int? fieldMinWidth;
  final int? fieldWidth;
  final bool? fieldVisible;
  final String? formatString;
  final String? keyFieldName;
  final bool? editable;
  final String dataType;
  final int? size;
  final int? visibleIndex;

  ListPanelFields({
    required this.listFieldName,
    this.objectId,
    this.fieldCaption,
    this.fieldMinWidth,
    this.fieldWidth,
    this.fieldVisible,
    this.formatString,
    this.keyFieldName,
    this.editable,
    required this.dataType,
    this.size,
    this.visibleIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      "listFieldName": listFieldName,
      "objectId": objectId,
      "fieldCaption": fieldCaption,
      "fieldMinWidth": fieldMinWidth,
      "fieldWidth": fieldWidth,
      "fieldVisible": fieldVisible,
      "formatString": formatString,
      "keyFieldName": keyFieldName,
      "editable": editable,
      "dataType": dataType,
      "size": size,
      "visibleIndex": visibleIndex,
    };
  }

  factory ListPanelFields.fromJson(Map<String, dynamic> json) {
    return ListPanelFields(
      listFieldName: json['listFieldName'],
      objectId: json['objectId'],
      fieldCaption: json['fieldCaption'],
      fieldMinWidth: json['fieldMinWidth'],
      fieldWidth: json['fieldWidth'],
      fieldVisible: json['fieldVisible'],
      formatString: json['formatString'],
      keyFieldName: json['keyFieldName'],
      editable: json['editable'],
      dataType: json['dataType'],
      size: json['size'],
      visibleIndex: json['visibleIndex'],
    );
  }
}
