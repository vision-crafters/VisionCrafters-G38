import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'app_state.dart'; // Import the AppState class
import 'package:flutterbasics/services/database.dart';
import 'dart:developer' as developer;
import './services/CameraPreviewScreen.dart';
import './services/VideoRecordingScreen.dart';

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

Future<File?> pickMedia(BuildContext context, AppState appState) async {
  // Pick image or video from gallery
  // by taking the choice and parameters from the user
  final ImagePicker _pickerGal = ImagePicker(); // Pick image or video from gallery

  //dialog to give the user an option
  //to select between an image or a video from the gallery
  final choice = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {  // builder for the dialog

      // dialog box
      return AlertDialog(
        title: const Text('Choose Media Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: const Text('Image'),
              onTap: () => Navigator.pop(context, 'image'), // option to select image
              //will open the gallery to select images by the user
            ),
            ListTile(
              title: const Text('Video'),
              onTap: () => Navigator.pop(context, 'video'), // option to select video
              //will open the gallery to select videos by the user
            ),
          ],
        ),
      );
    },
  );
        //before uploading, setting the spinner on...

  if (choice != null) {
        // if choice is not null

    XFile? pickedFile;  //XFile for the selected image or video
    if (choice == 'image') {
      pickedFile = await _pickerGal.pickImage(
        source: ImageSource.gallery,  // will open the gallery to select images by the user
        imageQuality: 100,
        maxHeight: 1080,
        maxWidth: 1920,
      );
    } else if (choice == 'video') {
      pickedFile = await _pickerGal.pickVideo(source: ImageSource.gallery);
      // will open the gallery to select videos by the user
    }

    if (pickedFile != null) { // if pickedFile is not null

      final mimeType = lookupMimeType(pickedFile.path); //mimeType for the selected image or video

      // if mimeType is not null and mimeType starts with 'video'
      if (mimeType != null && mimeType.startsWith('video')) {
        appState.setSpinnerVisibility(true); //before uploading, setting the spinner on...

        appState.setSpinnerVisibility(false); //After uploading, setting the spinner off...

        return File(pickedFile.path);
      } else if (mimeType != null && mimeType.startsWith('image')) {
        appState.setSpinnerVisibility(true); //before uploading, setting the spinner on...
        appState.setSpinnerVisibility(false); //After uploading, setting the spinner off...
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

//function for getting an image from the Camera by taking the required parameters.
Future<File?> getImageCM(BuildContext context, AppState appState) async {
  final ImagePicker _pickerCam = ImagePicker();

  final pickedFile_Camera = await _pickerCam.pickImage(
    source: ImageSource.camera,
    imageQuality: 100,
  );

  if (pickedFile_Camera != null) { //if the file is picked from the camera.

    File imageCam = File(pickedFile_Camera.path);
    appState.setSpinnerVisibility(true);
    appState.setSpinnerVisibility(false);
    return imageCam;
  }
  return null;
}

//function for getting a video from the Camera by taking the required parameters.
Future<File?> getVideoFile(BuildContext context, AppState appState) async {
  final ImagePicker _pickerCam = ImagePicker();

  appState.setSpinnerVisibility(true);
  final videoFile = await _pickerCam.pickVideo(source: ImageSource.camera);
  //will open camera to shoot a video, and that video file will be stored in the
  //variable videoFile.

  if (videoFile != null) { // if videoFile is not null

    return File(videoFile.path);
  } else {
    developer.log("No video captured");
    appState.setSpinnerVisibility(false);
    return null;
  }
}

//function with parameters, used for uploading images
Future<Map<String, dynamic>> uploadImage(
    File? imageFile, AppState appState) async {
  if (imageFile == null) return {'path': '', 'id': ""};

  appState.setSpinnerVisibility(true); //before uploading the spinner will be turned on.

  final bytes = await imageFile.readAsBytes();  //reads the contents of the imageFile
  //asynchronously and stores them in the bytes variable

  final base64Image = base64Encode(bytes);  //converts the bytes into a Base64-encoded string
  //represent binary data as text

  final mimeType = lookupMimeType(imageFile.path);  //returns the MIME type of the file

  if (mimeType == null) {
    developer.log('Unsupported file format');
    appState.setSpinnerVisibility(false); //if it is an unsupported file format the spinner will be turned off.

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
    developer.log(data.toString()); //Response is also displayed on the debug console for the verification purposes.

    appState.setSpinnerVisibility(false);  //After the description is displayed onscreen, the showspinner will be turned off.

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
    File videoFile, AppState appState) async {
  appState.setSpinnerVisibility(true);  //before uploading the spinner will be turned on.

  final storageRef = FirebaseStorage.instance.ref(); //storageRef for the firebase storage
  final uniqueId = Uuid().v1();  //uniqueId for the video file

  final fileRef = storageRef.child('$uniqueId.mp4');  //fileRef for the video file

  final mimeType = lookupMimeType(videoFile.path);

  await fileRef.putFile(videoFile); //uploads the video file to firebase storage

  final videoUrl = await fileRef.getDownloadURL(); //get the download URL for the video file


    //This is an instance of the Firebase
    // Firebase Cloud Function with the name 'video' that is being called.
    //invoke the Firebase Cloud Function with the provided data
    //passing a Map object containing two key-value pairs: 'data' and 'mime_type'
    //'data' and 'mime_type' are the keys and their corresponding values are
    //the video download url and the MIME type of the video file, respectively.
    //response is stored in the response variable
  final response = await FirebaseFunctions.instance
      .httpsCallable('video')
      .call({'data': videoUrl, 'mime_type': mimeType});

  final data = response.data;
  developer.log(data.toString()); //this will be displayed on the debug console for verification purposes.
  appState.setSpinnerVisibility(false);  //After the description is displayed onscreen, the showspinner will be turned off.
  return data;
}

Future<Map<String, String>> saveImage(File? imageFile) async {
  final appDir = await _getAppDirectory();
  if (imageFile == null) {
    developer.log('No image file');
    return {'path': '', 'id': ''};
  }

  final fileName = path.basename(imageFile.path);
  final mimeType = lookupMimeType(imageFile.path);

  if (mimeType == null) {
    developer.log('Unsupported file format');
    return {'path': '', 'id': ''};
  }

  final filePath = '$appDir/images/';
  final newFilePath = path.join(filePath, fileName);
  final newFile = await imageFile.copy(newFilePath);

  final id = await dbHelper.insertMedia(0, mimeType, newFilePath);
  return {'path': newFilePath, 'id': id.toString()};
}

Future<Map<String,dynamic>> saveVideo(File? videoFile) async{
  final appDir = await _getAppDirectory();
  if(videoFile == null){
    developer.log('No video file');
    return {'path': '', 'id': ''};
  }
  final filename = path.basename(videoFile.path);
  final mimeType = lookupMimeType(videoFile.path);
  if(mimeType == null){
    developer.log('Unsupported file format');
    return {'path': '', 'id': ''};
  }
  final filePath = '$appDir/videos/';
  final newFilePath = path.join(filePath, filename);
  final newFile = await videoFile.copy(newFilePath);

  final id = await dbHelper.insertMedia(0, mimeType, newFilePath);
  return {'path': newFilePath, 'id': id};

}
