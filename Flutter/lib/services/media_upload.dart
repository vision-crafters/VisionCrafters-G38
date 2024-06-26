import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state.dart';

class MediaUploader {
  //function with parameters, used for uploading images
  Future<Map<String, dynamic>> uploadImage(
      File? imageFile, String? mimeType, AppState appState) async {
    if (imageFile == null) return {'path': '', 'id': ""};

    appState.setSpinnerVisibility(
        true); //before uploading the spinner will be turned on.

    final bytes =
        await imageFile.readAsBytes(); //reads the contents of the imageFile
    //asynchronously and stores them in the bytes variable
    final base64Image =
        base64Encode(bytes); //converts the bytes into a Base64-encoded string
    //represent binary data as text

    if (mimeType == null) {
      developer.log('Unsupported file format');
      appState.setSpinnerVisibility(
          false); //if it is an unsupported file format the spinner will be turned off.
      return {'path': '', 'id': ""};
    }

    //This is an instance of the Firebase
    // Firebase Cloud Function with the name 'image' that is being called.
    //invoke the Firebase Cloud Function with the provided data
    //passing a Map object containing two key-value pairs: 'data' and 'mime_type'
    //'data' and 'mime_type' are the keys and their corresponding values are
    //the Base64-encoded image and the MIME type of the image file, respectively.
    //response is stored in the response variable
    final response =
        await FirebaseFunctions.instance.httpsCallable('image').call({
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
      developer.log("Failed to upload");
      appState.setSpinnerVisibility(false);
      return {'path': '', 'id': ""};
    }
  }

//This function is used to upload videos
//to the Firebase Cloud Storage and then to the Firebase Cloud Function.
  Future<Map<String, dynamic>> uploadVideo(
      File videoFile, String? mimeType, AppState appState) async {
    appState.setSpinnerVisibility(
        true); //before uploading the spinner will be turned on.

    final storageRef =
        FirebaseStorage.instance.ref(); //storageRef for the firebase storage
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
        await FirebaseFunctions.instance.httpsCallable('video').call({
      'data': videoUrl,
      'mime_type': mimeType,
    });

    final data = response.data;
    developer.log(data
        .toString()); //this will be displayed on the debug console for verification purposes.
    appState.setSpinnerVisibility(
        false); //After the description is displayed onscreen, the showspinner will be turned off.
    return data;
  }
}
