class PlatformSetting {
  final String listFieldName;
  final int? objectId;
  final String? fieldCaption;
  final int? fieldMinWidth;
  final int? fieldWidth;
  final bool fieldVisible;
  final String? formatString;
  final int? filterNo;
  final int? mobileWidth;
  final bool filterable;
  final bool sortable;
  final bool movable;
  final bool focusable;
  final bool groupable;
  final bool fixWidth;
  final bool resizeable;
  final bool repairable;
  final bool copyable;
  final bool allowCount;
  final bool allowSummary;
  final bool allowMin;
  final bool allowMax;
  final bool allowAverage;
  final String? keyFieldName;
  final bool? editable;
  final String? dataType;
  final int? size;
  final int? visibleIndex;

  PlatformSetting({
    required this.listFieldName,
    required this.fieldVisible,
    required this.filterable,
    required this.sortable,
    required this.movable,
    required this.focusable,
    required this.groupable,
    required this.fixWidth,
    required this.resizeable,
    required this.repairable,
    required this.copyable,
    required this.allowCount,
    required this.allowSummary,
    required this.allowMin,
    required this.allowMax,
    required this.allowAverage,
    this.objectId,
    this.fieldCaption,
    this.fieldMinWidth,
    this.fieldWidth,
    this.formatString,
    this.filterNo,
    this.mobileWidth,
    this.keyFieldName,
    this.editable,
    this.dataType,
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
      "visible": fieldVisible,
      "formatString": formatString,
      "filterNo": filterNo,
      "mobileWidth": mobileWidth,
      "filterable": filterable,
      "sortable": sortable,
      "movable": movable,
      "focusable": focusable,
      "groupable": groupable,
      "fixWidht": fixWidth,
      "resizeable": resizeable,
      "repairable": repairable,
      "copyable": copyable,
      "allowCount": allowCount,
      "allowSummary": allowSummary,
      "allowMin": allowMin,
      "allowMax": allowMax,
      "allowAverage": allowAverage,
      "keyFieldName": keyFieldName,
      "editable": editable,
      "dataType": dataType,
      "size": size,
      "visibleIndex": visibleIndex,
    };
  }

  factory PlatformSetting.fromJson(Map<String, dynamic> json) {
    return PlatformSetting(
      listFieldName: json['listFieldName'],
      objectId: json['objectId'],
      fieldCaption: json['fieldCaption'],
      fieldMinWidth: json['fieldMinWidth'],
      fieldWidth: json['fieldWidth'],
      formatString: json['formatString'],
      filterNo: json['filterNo'],
      mobileWidth: json['mobileWidth'],
      fieldVisible: json['visible'] ?? false,
      fixWidth: json['fixWidht'] ?? false,
      filterable: json['filterable'] ?? false,
      sortable: json['sortable'] ?? false,
      movable: json['movable'] ?? false,
      focusable: json['focusable'] ?? false,
      groupable: json['groupable'] ?? false,
      resizeable: json['resizeable'] ?? false,
      repairable: json['repairable'] ?? false,
      copyable: json['copyable'] ?? false,
      allowCount: json['allowCount'] ?? false,
      allowSummary: json['allowSummary'] ?? false,
      allowMin: json['allowMin'] ?? false,
      allowMax: json['allowMax'] ?? false,
      allowAverage: json['allowAverage'] ?? false,
      keyFieldName: json['keyFieldName'],
      editable: json['editable'] ?? false,
      dataType: json['dataType'],
      size: json['size'],
      visibleIndex: json['visibleIndex'],
    );
  }
}
