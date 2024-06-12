import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<Database> initializeDatabase() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'app.db');

  return openDatabase(
    path,
    onCreate: (db, version) async {
      // Create Images table
      await db.execute('''
        CREATE TABLE images (
          id TEXT PRIMARY KEY,
          path TEXT NOT NULL,
          mime_type TEXT NOT NULL
        )
      ''');

      // Create Videos table
      await db.execute('''
        CREATE TABLE videos (
          id TEXT PRIMARY KEY,
          path TEXT NOT NULL,
          mime_type TEXT NOT NULL
        )
      ''');

      // Create Conversations table
      await db.execute('''
        CREATE TABLE conversations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image_id TEXT,
          video_id TEXT,
          timestamp DATE DEFAULT (datetime('now','localtime')),
          FOREIGN KEY(image_id) REFERENCES images(id),
          FOREIGN KEY(video_id) REFERENCES videos(id)
        )
      ''');

      // Create Messages table
      await db.execute('''
        CREATE TABLE messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          conversation_id INTEGER NOT NULL,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          is_image INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(conversation_id) REFERENCES conversations(id)
        )
      ''');
    },
    version: 1,
  );
}

Future<void> insertImage(Database db, String id, String path, String mimeType) async {
  await db.insert(
    'images',
    {
      'id': id,
      'path': path,
      'mime_type': mimeType,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  print('Inserted image with id: $id');
}

Future<void> insertVideo(Database db, String id, String path, String mimeType) async {
  await db.insert(
    'videos',
    {
      'id': id,
      'path': path,
      'mime_type': mimeType,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<int> insertConversation(Database db, String imageId, String videoId) async {
  return await db.insert(
    'conversations',
    {
      'image_id': imageId,
      'video_id': videoId,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> insertMessage(Database db, int conversationId, String role, String content, {bool isImage = false}) async {
  await db.insert(
    'messages',
    {
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'is_image': isImage ? 1 : 0,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Map<String, dynamic>>> getMessages(Database db) async {
  return await db.query('messages');
}



Future<void> truncateImagesTable(Database db) async {
  await db.transaction((txn) async {
    await txn.execute('DROP TABLE IF EXISTS images');
    await txn.execute('''
      CREATE TABLE images (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        mime_type TEXT NOT NULL
      )
    ''');
  });
}

Future<void> insertImageWithTruncate(Database db, String id, String path, String mimeType) async {
  await truncateImagesTable(db);
  await insertImage(db, id, path, mimeType);
}

