// clockout_sync_table.dart
import 'package:ace_routes/database/databse_helper.dart';
import 'package:sqflite/sqflite.dart';

class ClockOutSyncTable {
  static const String tableName = 'clock_out_sync';

  static Future<void> onCreate(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lstoid TEXT,
        nxtoid TEXT,
        tid INTEGER,
        timestamp INTEGER,
        latitude REAL,
        longitude REAL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> insert(
      {String? lstoid,
      String? nxtoid,
      required int tid,
      required int timestamp,
      required double latitude,
      required double longitude}) async {
    final db = await DatabaseHelper().database;
    await db.insert(tableName, {
      'lstoid': lstoid,
      'nxtoid': nxtoid,
      'tid': tid,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'synced': 0,
    });
    print("📝 ClockOut stored offline (tid=$tid)");
  }

  static Future<List<Map<String, dynamic>>> getUnsynced() async {
    final db = await DatabaseHelper().database;
    return await db.query(tableName, where: 'synced = 0');
  }

  static Future<void> markSynced(int id) async {
    final db = await DatabaseHelper().database;
    await db.update(
      tableName,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
