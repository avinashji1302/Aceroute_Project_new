import 'dart:convert';

class EFormDataModel {
  final String id;
  final String oid;
  final String ftid;
  final String frmKey;
  final List<dynamic> formFields; // <- Changed from Map to List
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
    return EFormDataModel(
      id: json['id'] ?? '',
      oid: json['oid'] ?? '',
      ftid: json['ftid'] ?? '',
      frmKey: json['frmKey'] ?? '',
      formFields: json['formFields'] != null
          ? List<dynamic>.from(json['formFields'])
          : [],
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
      'formFields': json.encode(formFields), // Store as JSON string
      'updatedTimestamp': updatedTimestamp,
      'updatedBy': updatedBy,
    };
  }
}
