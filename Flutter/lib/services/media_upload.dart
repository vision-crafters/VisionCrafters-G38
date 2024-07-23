import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../providers/app_state.dart';
import '../utils/chat_utils.dart';

class MediaUploader {
  final storageRef = FirebaseStorage.instance.ref();

  //function with parameters, used for uploading images
  Future<Map<String, dynamic>> uploadImage(
      File? imageFile, String? mimeType, AppState appState) async {
    if (imageFile == null) {
      developer.log('Image file is null');
      throw Exception('Image file is null');
    }
    
    appState.setSpinnerVisibility(
        true); //before uploading the spinner will be turned on.

    final bytes =
        await imageFile.readAsBytes(); //reads the contents of the imageFile
    //asynchronously and stores them in the bytes variable
    final base64Image =
        base64Encode(bytes); //converts the bytes into a Base64-encoded string
    //represent binary data as text

    //This is an instance of the Firebase
    // Firebase Cloud Function with the name 'image' that is being called.
    //invoke the Firebase Cloud Function with the provided data
    //passing a Map object containing two key-value pairs: 'data' and 'mime_type'
    //'data' and 'mime_type' are the keys and their corresponding values are
    //the Base64-encoded image and the MIME type of the image file, respectively.
    //response is stored in the response variable
    final response =
        await FirebaseFunctions.instance.httpsCallable('image', options: HttpsCallableOptions(timeout: const Duration(seconds: 120))).call({
      'data': base64Image,
      'mime_type': mimeType,
    });

    if (response.data != null) {
      final data = response.data;
      developer.log(data
          .toString()); //Response is also displayed on the debug console for the verification purposes.
      appState.setSpinnerVisibility(
          false); //After the description is displayed onscreen, the showspinner will be turned off.
      return data;
    } else {
      developer.log("Failed to upload image.");
      appState.setSpinnerVisibility(false);
      throw Exception('Failed to upload image.');
    }
  }

//This function is used to upload videos
//to the Firebase Cloud Storage and then to the Firebase Cloud Function.
  Future<Map<String, dynamic>> uploadVideo(
      File? videoFile, String? mimeType, AppState appState) async {
    if (videoFile == null) {
      developer.log('Video file is null');
      throw Exception('Video file is null');
    }

    appState.setSpinnerVisibility(
        true); //before uploading the spinner will be turned on.

    final uniqueId = const Uuid().v1(); //uniqueId for the video file
    final fileRef =
        storageRef.child('$uniqueId.mp4'); //fileRef for the video file

    await fileRef
        .putFile(videoFile); //uploads the video file to firebase storage
    final videoUrl = await fileRef
        .getDownloadURL(); //get the download URL for the video file

    //This is an instance of the Firebase
    // Firebase Cloud Function with the name 'video' that is being called.
    //invoke the Firebase Cloud Function with the provided data
    //passing a Map object containing two key-value pairs: 'data' and 'mime_type'
    //'data' and 'mime_type' are the keys and their corresponding values are
    //the video download url and the MIME type of the video file, respectively.
    //response is stored in the response variable
    final response =
        await FirebaseFunctions.instance.httpsCallable('video', options: HttpsCallableOptions(timeout: const Duration(seconds: 180))).call({
      'data': videoUrl,
      'mime_type': mimeType,
    });

    if (response.data != null) {
      final data = response.data;
      developer.log(data
          .toString()); //this will be displayed on the debug console for verification purposes.
      appState.setSpinnerVisibility(
          false); //After the description is displayed onscreen, the showspinner will be turned off.
      return data;
    } else {
      developer.log("Failed to upload video.");
      appState.setSpinnerVisibility(false);
      throw Exception('Failed to upload video.');
    }
  }

  Future<dynamic> uploadQuery(List<Map<String, dynamic>> messages, File? file,
      String? mimeType, AppState appState) async {
    if (file == null) {
      developer.log('File is null');
      throw Exception('File is null');
    }
appState.setSpinnerVisibility(true);
    List<Map<String, dynamic>> conversation = getChatHistory(messages);
    developer.log(conversation.toString());
    if (mimeType != null && mimeType.startsWith('image')) {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final response =
          await FirebaseFunctions.instance.httpsCallable('image', options: HttpsCallableOptions(timeout: const Duration(seconds: 120))).call({
        'data': base64Image,
        'mime_type': mimeType,
        'query': conversation,
      });
      if (response.data != null) {
        final data = response.data;
        developer.log(data.toString());
appState.setSpinnerVisibility(false);
        return data;
      } else {
appState.setSpinnerVisibility(false);
        developer.log("Failed to upload query for image .");
        throw Exception('Failed to upload query for image.');
      }
    } else if (mimeType != null && mimeType.startsWith('video')) {
      final uniqueId = const Uuid().v1();
      final fileRef = storageRef.child('$uniqueId.mp4');
      await fileRef.putFile(file);
      final videoUrl = await fileRef.getDownloadURL();
      final response =
          await FirebaseFunctions.instance.httpsCallable('video', options: HttpsCallableOptions(timeout: const Duration(seconds: 180))).call({
        'data': videoUrl,
        'mime_type': mimeType,
        'query': conversation,
      });
      if (response.data != null) {
        final data = response.data;
appState.setSpinnerVisibility(false);
        developer.log(data.toString());
        return data;
      } else {
appState.setSpinnerVisibility(false);
        developer.log("Failed to upload query for video.");
        throw Exception('Failed to upload query for video.');
      }
    } else {
appState.setSpinnerVisibility(false);
      developer.log('Unsupported file format');
      throw Exception('Unsupported file format');
    }
  }
}
