import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MessageLogService {
  static Database? _db;

  static Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'messages.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE messages(
          number TEXT,
          timestamp TEXT,
          sent INTEGER,
          PRIMARY KEY(number, timestamp)
        )
      '''),
    );
  }

  static Future<void> logMessage(String number, String timestamp) async {
    final db = await _database;
    await db.insert(
      'messages',
      {'number': number, 'timestamp': timestamp, 'sent': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<bool> isMessageSent(String number, String timestamp) async {
    final db = await _database;
    final res = await db.query(
      'messages',
      where: 'number = ? AND timestamp = ? AND sent = 1',
      whereArgs: [number, timestamp],
    );
    return res.isNotEmpty;
  }

  
 static Future<int> updateMessage(
    String number, 
    String oldTimestamp, 
    {String? updatedTimestamp, int? status}) async {
  
  final db = await _database;

  // Prepare values to update
  Map<String, dynamic> updates = {};
  if (updatedTimestamp != null) updates['timestamp'] = updatedTimestamp;
  if (status != null) updates['sent'] = status;  // Ensure 'sent' is correct.

  if (updates.isNotEmpty) {
    int updatedRows = await db.update(
      'messages',
      updates,
      where: 'number = ? AND timestamp = ?',
      whereArgs: [number, oldTimestamp],
    );

    // Log the update status
    print('Updated $updatedRows row(s) for number: $number');

    return updatedRows;  // Return number of updated rows
  }
  
  return 0; // No update performed
}



  void debugPrintMessages() async {
  final db = await MessageLogService._database;
  final messages = await db.query('messages');
  print('Stored Messages:');
  messages.forEach((msg) => print(
    'Number: ${msg['number']}, '
    'Time: ${msg['timestamp']}, '
    'Sent: ${msg['sent'] == 1}'
  ));
}
}