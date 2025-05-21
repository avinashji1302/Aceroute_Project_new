import 'dart:convert';

class EFormDataModel {
  final String id;
  final String oid;
  final String ftid;
  final String frmKey;
  final List<dynamic> formFields;
  final String updatedTimestamp;
  final String updatedBy;

  EFormDataModel({
    required this.id,
    required this.oid,
    required this.ftid,
    required this.frmKey,
    required this.formFields,
    required this.updatedTimestamp,
    required this.updatedBy,
  });

  factory EFormDataModel.fromJson(Map<String, dynamic> json) {
    // Handle formFields conversion
    dynamic formFieldsData = json['formFields'];
    List<dynamic> formFieldsList = [];

    if (formFieldsData is String) {
      try {
        formFieldsData = jsonDecode(formFieldsData);
      } catch (e) {
        print('Error decoding formFields string: $e');
      }
    }

    if (formFieldsData is Map && formFieldsData.containsKey('frm')) {
      formFieldsList = formFieldsData['frm'];
    } else if (formFieldsData is List) {
      formFieldsList = formFieldsData;
    }

    return EFormDataModel(
      id: json['id'] ?? '',
      oid: json['oid'] ?? '',
      ftid: json['ftid'] ?? '',
      frmKey: json['frmKey'] ?? '',
      formFields: formFieldsList,
      updatedTimestamp: json['updatedTimestamp'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'oid': oid,
      'ftid': ftid,
      'frmKey': frmKey,
      'formFields': jsonEncode(formFields),
      'updatedTimestamp': updatedTimestamp,
      'updatedBy': updatedBy,
    };
  }
}
