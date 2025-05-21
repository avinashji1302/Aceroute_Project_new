import 'dart:convert'; // <-- Add this import for jsonEncode

import 'package:ace_routes/database/databse_helper.dart';
import 'package:sqflite/sqflite.dart';

class AddFormSyncTable {
  static const String tableName = 'form_sync';

  static Future<void> onCreate(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        geo TEXT NOT NULL,
        oid TEXT NOT NULL,
        form_id TEXT NOT NULL,
        ftid TEXT NOT NULL,
        name TEXT NOT NULL,
        frm TEXT NOT NULL,
        frmkey TEXT NOT NULL,
        action TEXT NOT NULL, -- save, edit
        synced INTEGER DEFAULT 0
      )
    ''');
    print("✅ Form sync table created.");
  }

  static Future<void> insert({
    required String geo,
    required String oid,
    required String formId,
    required String ftid,
    required String name,
    required List<dynamic> frm, // Accepts List<dynamic>
    required String frmkey,
    required String action,
  }) async {
    final db = await DatabaseHelper().database;

    await db.insert(
      tableName,
      {
        'geo': geo,
        'oid': oid,
        'form_id': formId,
        'ftid': ftid,
        'name': name,
        'frm': jsonEncode(frm), // Store as JSON string
        'frmkey': frmkey,
        'action': action,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("✅ Queued $action for oid: $oid");
  }

  static Future<List<Map<String, dynamic>>> getUnsynced() async {
    final db = await DatabaseHelper().database;
    return await db.query(tableName, where: 'synced = ?', whereArgs: [0]);
  }

  static Future<void> markSynced(int id) async {
    final db = await DatabaseHelper().database;
    await db.update(tableName, {'synced': 1}, where: 'id = ?', whereArgs: [id]);
    print("✅ Marked form sync $id as synced.");
  }

  static Future<void> clearSynced() async {
    final db = await DatabaseHelper().database;
    await db.delete(tableName, where: 'synced = ?', whereArgs: [1]);
    print("🧹 Cleared all synced form records.");
  }


  
}
