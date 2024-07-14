import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;
  static const String dbName = 'vlm_database.db';

  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), dbName);
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create tables
    await db.execute('''
      CREATE TABLE Conversations (
        conversation_id INTEGER PRIMARY KEY AUTOINCREMENT CHECK (conversation_id >= 0),
        title TEXT,
        timestamp DATE DEFAULT (datetime('now','localtime'))
      )
    ''');

    await db.execute('''
      CREATE TABLE Messages (
        message_id INTEGER PRIMARY KEY,
        conversation_id INTEGER,
        role TEXT,
        content TEXT,
        timestamp DATE DEFAULT (datetime('now','localtime')),
        FOREIGN KEY (conversation_id) REFERENCES Conversations(conversation_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE Media (
        media_id INTEGER PRIMARY KEY,
        conversation_id INTEGER,
        mime_type TEXT,
        path TEXT,
        timestamp DATE DEFAULT (datetime('now','localtime')),
        FOREIGN KEY (conversation_id) REFERENCES Conversations(conversation_id)
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getAllConversations() async {
    Database db = await instance.database;
    return await db.query('Conversations', orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getConversationData(
      int conversationId) async {
    Database db = await instance.database;

    // SQL query to join Messages and Media tables and order by timestamp
    String query = '''
    SELECT 
      message_id as id, conversation_id, role, content, NULL as mime_type, NULL as path, timestamp, 'message' as type 
    FROM Messages 
    WHERE conversation_id = ? 
    UNION
    SELECT 
      media_id as id, conversation_id, "user" as role, NULL as content, mime_type, path, timestamp, 'media' as type 
    FROM Media 
    WHERE conversation_id = ? 
    ORDER BY timestamp ASC
  ''';

    List<Map<String, dynamic>> result =
        await db.rawQuery(query, [conversationId, conversationId]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getMessages(int conversationId) async {
    List<Map<String, dynamic>> data = await getConversationData(conversationId);
    List<Map<String, dynamic>> messages =
        data.where((element) => element['type'] == 'message').toList();
    return messages;
  }

  Future<int> insertConversation() async {
    Database db = await instance.database;
    return await db.insert('Conversations', {},nullColumnHack: 'title');
  }

Future<int> updateConversationWithId(String title, int conversationId) async {
  Database db = await instance.database;
  return await db.update(
    'Conversations', 
    {'title': title},
    where: 'conversation_id = ?', 
    whereArgs: [conversationId]
  );
}

  Future<int> insertMessage(
      int conversationId, String role, String content) async {
    Database db = await instance.database;
    return await db.insert('Messages', {
      'conversation_id': conversationId,
      'role': role,
      'content': content,
    });
  }

  Future<int> insertMedia(
      int conversationId, String mimeType, String path) async {
    Database db = await instance.database;
    return await db.insert('Media', {
      'conversation_id': conversationId,
      'mime_type': mimeType,
      'path': path,
    });
  }
}
