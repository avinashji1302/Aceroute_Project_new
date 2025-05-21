import 'package:ace_routes/database/databse_helper.dart';
import 'package:sqflite/sqflite.dart';

class UploadSyncTable {
  static const String tableName = 'upload_sync';

  static Future<void> onCreate(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL,
        event_id TEXT NOT NULL,
        file_type TEXT NOT NULL,
        description TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
    print("✅ Upload sync table created.");
  }

  static Future<void> insert(
      {required String filePath,
      required String eventId,
      required String fileType,
      required String description,
      required String timestamp}) async {
    final db = await DatabaseHelper().database;

    await db.insert(
      tableName,
      {
        'file_path': filePath,
        'event_id': eventId,
        'file_type': fileType,
        'description': description,
        'timestamp': timestamp,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("📥 Queued file for eventId: $eventId");
  }

  static Future<List<Map<String, dynamic>>> getUnsynced() async {
    final db = await DatabaseHelper().database;
    return await db.query(tableName, where: 'synced = 0');
  }

  static Future<void> markSynced(int id) async {
    final db = await DatabaseHelper().database;
    await db.update(tableName, {'synced': 1}, where: 'id = ?', whereArgs: [id]);
    print("✅ Marked upload $id as synced.");
  }

  static Future<void> clearSynced() async {
    final db = await DatabaseHelper().database;
    await db.delete(tableName, where: 'synced = 1');
    print("🧹 Cleared all synced uploads.");
  }
}
