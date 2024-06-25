import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'app_state.dart'; // Import the AppState class
import 'package:flutterbasics/services/database.dart';
import 'dart:developer' as developer;

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

Future<File?> pickMedia(BuildContext context,
    Function(Map<String, dynamic>) addDescription, AppState appState) async {
  final ImagePicker _pickerGal = ImagePicker();

  final choice = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Choose Media Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: const Text('Image'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              title: const Text('Video'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      );
    },
  );

  if (choice != null) {
    XFile? pickedFile;
    if (choice == 'image') {
      pickedFile = await _pickerGal.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
        maxHeight: 1080,
        maxWidth: 1920,
      );
    } else if (choice == 'video') {
      pickedFile = await _pickerGal.pickVideo(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      final mimeType = lookupMimeType(pickedFile.path);

      if (mimeType != null && mimeType.startsWith('video')) {
        appState.setSpinnerVisibility(true);
        appState.setSpinnerVisibility(false);
        return File(pickedFile.path);
      } else if (mimeType != null && mimeType.startsWith('image')) {
        appState.setSpinnerVisibility(true);
        return File(pickedFile.path);
      } else {
        developer.log("Unsupported file type");
        return null;
      }
    } else {
      developer.log("No file selected");
      return null;
    }
  } else {
    developer.log("No choice selected");
    return null;
  }
}

Future<File?> getImageCM(BuildContext context,
    Function(Map<String, dynamic>) addDescription, AppState appState) async {
  final ImagePicker _pickerCam = ImagePicker();

  final pickedFile_Camera = await _pickerCam.pickImage(
    source: ImageSource.camera,
    imageQuality: 100,
  );

  if (pickedFile_Camera != null) {
    File imageCam = File(pickedFile_Camera.path);
    appState.setSpinnerVisibility(true);
    appState.setSpinnerVisibility(false);
    return imageCam;
  }
  return null;
}

Future<File?> getVideoFile(BuildContext context,
    Function(Map<String, String>) addDescription, AppState appState) async {
  final ImagePicker _pickerCam = ImagePicker();

  appState.setSpinnerVisibility(true);
  final videoFile = await _pickerCam.pickVideo(source: ImageSource.camera);

  if (videoFile != null) {
    return File(videoFile.path);
  } else {
    developer.log("No video captured");
    appState.setSpinnerVisibility(false);
    return null;
  }
}

Future<Map<String, dynamic>> uploadImage(File? imageFile,
    Function(Map<String, dynamic>) addDescription, AppState appState) async {
  if (imageFile == null) return {'path': '', 'id': ""};

  appState.setSpinnerVisibility(true);

  final bytes = await imageFile.readAsBytes();
  final uniqueImageId = Uuid().v1();
  final base64Image = base64Encode(bytes);
  final mimeType = lookupMimeType(imageFile.path);

  if (mimeType == null) {
    developer.log('Unsupported file format');
    appState.setSpinnerVisibility(false);
    return {'path': '', 'id': ""};
  }

  final response =
      await FirebaseFunctions.instance.httpsCallable('image').call({
    'data': base64Image,
    'mime_type': mimeType,
  });

  if (response.data != null) {
    final data = response.data;
    developer.log(data.toString());
    addDescription(data);

    appState.setSpinnerVisibility(false);
    return data;
  } else {
    developer.log("Failed to upload");
    appState.setSpinnerVisibility(false);
    return {'path': '', 'id': ""};
  }
}

Future<Map<String, String>> uploadVideo(File videoFile,
    Function(Map<String, String>) addDescription, AppState appState) async {
  final storageRef = FirebaseStorage.instance.ref();
  final uniqueId = Uuid().v1();
  final fileRef = storageRef.child('$uniqueId.mp4');

  await fileRef.putFile(videoFile);

  final videoUrl = await fileRef.getDownloadURL();

  final response = await FirebaseFunctions.instance
      .httpsCallable('video')
      .call({'data': videoUrl, 'mime_type': 'video/mp4'});

  final data = response.data;
  developer.log(data.toString());
  addDescription(data);

  appState.setSpinnerVisibility(false);
  return data;
}

Future<Map<String, String>> saveImage(File? imageFile) async {
  final appDir = await _getAppDirectory();
  final uniqueImageId = Uuid().v1();
  if (imageFile == null) {
    developer.log('No image file');
    return {'path': '', 'id': ""};
  }
  final mimeType = lookupMimeType(imageFile.path);


  if (mimeType == null) {
    developer.log('Unsupported file format');
    return {'path': '', 'id': ""};
  }
  final bytes = await imageFile.readAsBytes();
  final newFilePath =
      '$appDir/images/$uniqueImageId.${imageFile.path.split('.').last}';
  // Encode the image to PNG or JPG before saving to file system.
  File file = File(newFilePath);
  await file.writeAsBytes(bytes);

  final id = await dbHelper.insertMedia(0, mimeType, newFilePath);
  return {'path': newFilePath, 'id': id.toString()};
}

Future<Map<String, dynamic>> saveVideo(File videoFile) async {
  final appDir = await _getAppDirectory();
  final uniqueId = Uuid().v1();
  final newFilePath = '$appDir/videos/$uniqueId.mp4';
  final newFile = await videoFile.copy(newFilePath);

  final id = await dbHelper.insertMedia(0, 'video/mp4', newFilePath);
  return {'path': newFilePath, 'id': id};
}
