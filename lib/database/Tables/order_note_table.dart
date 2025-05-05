import 'package:sqflite/sqflite.dart';
import '../../model/order_note_model.dart';
import '../databse_helper.dart';

class OrderNoteTable {
  static const String tableName = "orderNote";

  // Create the table
  static Future<void> onCreate(Database db) async {
    await db.execute(
      '''
      CREATE TABLE $tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT
      )
      ''',
    );
  }

  // Handle table upgrades
  static Future<void> onUpgrade(Database db) async {
    await onCreate(db);
  }

  // Insert a single value into the OrderNote table
  static Future<void> insertOrderNote(OrderNoteModel orderNoteModel) async {
    final db = await DatabaseHelper().database;
    // Clear existing records before inserting new data
    await clearOrderNote();
    await db.insert(
      tableName,
      orderNoteModel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print("insereted successfylly notes");
  }

  // Fetch all records
  static Future<List<OrderNoteModel>> fetchOrderNote() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(
      maps.length,
      (i) => OrderNoteModel.fromMap(maps[i]),
    );
  }

  static Future<void> updateOrderNoteData(String newData) async {
    final db = await DatabaseHelper().database;

    try {
      // Perform the update
      int result = await db.update(
        tableName,
        {'data': newData}, // Only updating the "data" field
        where: 'id = ?',
        whereArgs: [1], // Assuming your record ID is 1
      );
      // Check the result and debug
      if (result > 0) {
        print('Update successful: $newData'); // Success message
      } else {
        print(
            'No rows updated. Please check the ID or data.'); // If no rows are updated
      }
    } catch (e) {
      // Catch and print any errors
      print('Error updating data: $e');
    }
  }

  // Clear all records
  static Future<void> clearOrderNote() async {
    final db = await DatabaseHelper().database;
    await db.delete(tableName);
  }
}
