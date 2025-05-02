import 'dart:convert'; // <-- Add this import for jsonEncode

import 'package:ace_routes/database/databse_helper.dart';
import 'package:sqflite/sqflite.dart';

class AddFormSyncTable {
  static const tableName = 'add_form_sync';

  static Future<void> onCreate(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        geo TEXT,
        oid TEXT,
        formId TEXT,
        ftid TEXT,
        fdata TEXT,
        frmkey TEXT,
        imagePath TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> insert({
    required String geo,
    required String oid,
    required String formId,
    required String ftid,
    required Map<String, dynamic> fdata, // <-- Accept Map
    required String frmkey,
    String? imagePath,
  }) async {
    final db = await DatabaseHelper().database;
    final String encodedFdata = jsonEncode(fdata); // <-- Convert Map to JSON string

    await db.insert(tableName, {
      'geo': geo,
      'oid': oid,
      'formId': formId,
      'ftid': ftid,
      'fdata': encodedFdata, // <-- Save encoded string
      'frmkey': frmkey,
      'imagePath': imagePath ?? '',
    });
  }

  static Future<List<Map<String, dynamic>>> getUnsynced() async {
    final db = await DatabaseHelper().database;
    return await db.query(tableName, where: 'synced = 0');
  }

  static Future<void> markSynced(int id) async {
    final db = await DatabaseHelper().database;
    await db.update(tableName, {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
