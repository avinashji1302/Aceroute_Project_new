import 'package:ace_routes/database/databse_helper.dart';
import 'package:sqflite/sqflite.dart';
class DeleteSyncEformTable {
  static const String tableName = 'delete_sync_eform';

  static Future<void> onCreate(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        form_id TEXT NOT NULL,
        geo TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
    print("✅ Delete sync table created");
  }

  static Future<void> queueDelete({
    required String formId,
    required String geo,
  }) async {
    final db = await DatabaseHelper().database;

    await db.insert(
      tableName,
      {
        'form_id': formId,
        'geo': geo,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("🗑️ Queued delete for form $formId");
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedDeletes() async {
    final db = await DatabaseHelper().database;
    return await db.query(
      tableName,
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  static Future<void> markSynced(int id) async {
    final db = await DatabaseHelper().database;
    await db.update(
      tableName,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    print("✅ Marked delete $id as synced");
  }

  static Future<void> clearSynced() async {
    final db = await DatabaseHelper().database;
    await db.delete(
      tableName,
      where: 'synced = ?',
      whereArgs: [1],
    );
    print("🧹 Cleared synced delete records");
  }
}