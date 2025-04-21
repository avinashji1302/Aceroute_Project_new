import 'package:ace_routes/database/databse_helper.dart';
import 'package:sqflite/sqflite.dart';

class OrderPartSyncTable {
  static const String tableName = 'order_part_sync';

  static Future<void> onCreate(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id TEXT NOT NULL,
        action TEXT NOT NULL, -- add, edit, delete
        sku TEXT,
        qty TEXT,
        tid TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
    print("✅ Order part sync table created.");
  }

  static Future<void> insert({
    required String orderId,
    required String action,
    String? sku,
    String? qty,
    String? tid,
  }) async {
    final db = await DatabaseHelper().database;

    await db.insert(
      tableName,
      {
        'order_id': orderId,
        'action': action,
        'sku': sku ?? '',
        'qty': qty ?? '',
        'tid': tid ?? '',
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("✅ Queued $action for order_id: $orderId");
  }

  static Future<List<Map<String, dynamic>>> getUnsynced() async {
    final db = await DatabaseHelper().database;
    return await db.query(tableName, where: 'synced = ?', whereArgs: [0]);
  }

  static Future<void> markSynced(int id) async {
    final db = await DatabaseHelper().database;
    await db.update(tableName, {'synced': 1}, where: 'id = ?', whereArgs: [id]);
    print("✅ Marked order part sync $id as synced.");
    await clearSynced(); // Optional cleanup
  }

  static Future<void> clearSynced() async {
    final db = await DatabaseHelper().database;
    await db.delete(tableName, where: 'synced = ?', whereArgs: [1]);
    print("🧹 Cleared all synced order part records.");
  }
}
