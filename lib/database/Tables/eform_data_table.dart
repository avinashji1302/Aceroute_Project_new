import 'dart:convert';
import 'package:ace_routes/database/databse_helper.dart';
import 'package:ace_routes/model/eform_data_model.dart';
import 'package:sqflite/sqflite.dart';

class EFormDataTable {
  static const String tableName = 'eFormsDataTable';

  static Future<void> onCreate(Database db) async {
    print("Creating table: $tableName");
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        oid TEXT,
        ftid TEXT,
        frmKey TEXT,
        formFields TEXT,
        updatedTimestamp TEXT,
        updatedBy TEXT
      )
    ''');
  }

  static Future<void> insertEForm(EFormDataModel model) async {
    final db = await DatabaseHelper().database;
    print("Inserting into $tableName: ${model.toMap()}");

    await db.insert(
      tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Insert complete.");
  }

  static Future<List<EFormDataModel>> getAllEFormsFromDb() async {
    final db = await DatabaseHelper().database;
    final result = await db.query(tableName);

    return result.map((json) {
      final map = Map<String, dynamic>.from(json);

      // Handle the stored JSON string
      if (map['formFields'] is String) {
        try {
          map['formFields'] = jsonDecode(map['formFields']);
        } catch (e) {
          print('Error decoding stored formFields: $e');
          map['formFields'] = [];
        }
      }

      return EFormDataModel.fromJson(map);
    }).toList();
  }

  static Future<void> deleteForm(String id) async {
    final db = await DatabaseHelper().database;

    final response =
        await db.delete(tableName, where: 'id = ? ', whereArgs: [id]);

    print('response deleted successfully : $response');
  }

  static Future<List<EFormDataModel>> getFormsByType(String ftid) async {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      tableName,
      where: 'ftid = ?',
      whereArgs: [ftid],
    );
    return result.map((json) => EFormDataModel.fromJson(json)).toList();
  }
}
