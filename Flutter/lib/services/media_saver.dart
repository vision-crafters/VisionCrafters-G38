import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:visioncrafters/services/database.dart';

class MediaSaver {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<String> _getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = directory.path;

    final imageDir = Directory('$appDir/images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: false);
    }

    final videoDir = Directory('$appDir/videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: false);
    }

    return appDir;
  }

  Future<Map<String, String>> saveImage(
      File? imageFile, String? mimeType,final conversationId) async {
    final appDir = await _getAppDirectory();
    if(imageFile == null){
      developer.log('Image file is null');
      throw Exception('Image file is null');
    }
    final fileName = path.basename(imageFile.path);

    if (mimeType == null) {
      developer.log('Unsupported file format');
      throw Exception('Unsupported file format');
    }

    final filePath = '$appDir/images/';
    final newFilePath = path.join(filePath, fileName);
    await imageFile.copy(newFilePath);

    final id = await dbHelper.insertMedia(conversationId  , mimeType, newFilePath);
    return {'path': newFilePath, 'id': id.toString()};
  }

  Future<Map<String, String>> saveVideo(
      File? videoFile, String? mimeType,final conversationId) async {
    final appDir = await _getAppDirectory();
    if(videoFile == null){
      developer.log('Video file is null');
      throw Exception('Video file is null');
    }
    final filename = path.basename(videoFile.path);
    if (mimeType == null) {
      developer.log('Unsupported file format');
      throw Exception('Unsupported file format');
    }

    final filePath = '$appDir/videos/';
    final newFilePath = path.join(filePath, filename);
    await videoFile.copy(newFilePath);

    final id = await dbHelper.insertMedia(conversationId, mimeType, newFilePath);
    return {'path': newFilePath, 'id': id.toString()};
  }
}
