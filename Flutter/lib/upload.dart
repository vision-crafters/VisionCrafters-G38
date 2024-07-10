import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart';
import 'app_state.dart'; // Import the AppState class

Future<void> pickMedia(BuildContext context, Function(String) addDescription,
    AppState appState) async {
  // Pick image or video from gallery
// by taking the choice and parameters from the user
  final ImagePicker pickerGal =
      ImagePicker(); // Pick image or video from gallery
  final choice = await showDialog<String>(
    //dialog to give the user an option
    //to select between an image or a video from the gallery
    context: context,
    builder: (BuildContext context) {
      // builder for the dialog
      return AlertDialog(
        // dialog box
        title: const Text('Choose Media Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              //
              title: const Text('Image'),
              onTap: () =>
                  Navigator.pop(context, 'image'), // option to select image
              //will open the gallery to select images by the user
            ),
            ListTile(
              title: const Text('Video'),
              onTap: () =>
                  Navigator.pop(context, 'video'), // option to select video
              //will open the gallery to select videos by the user
            ),
          ],
        ),
      );
    },
  );

  if (choice != null) {
    // if choice is not null
    XFile? pickedFile; //XFile for the selected image or video
    if (choice == 'image') {
      pickedFile = await pickerGal.pickImage(
        // will open the gallery to select
        //images by the user
        source: ImageSource
            .gallery, // will open the gallery to select images by the user
        imageQuality: 100,
        maxHeight: 1080,
        maxWidth: 1920,
      );
    } else if (choice == 'video') {
      // will open the gallery to select videos by the user
      pickedFile = await pickerGal.pickVideo(source: ImageSource.gallery);
      // will open the gallery to select videos by the user
    }

    if (pickedFile != null) {
      // if pickedFile is not null

      final mimeType = lookupMimeType(pickedFile.path);
      //mimeType for the selected image or video

      if (mimeType != null && mimeType.startsWith('video')) {
        // if mimeType is not null and mimeType starts with 'video'

        appState.setSpinnerVisibility(true);
        //before uploading, setting the spinner on...

        await uploadVideo(File(pickedFile.path), addDescription, appState);
        //uploading the video to firebase storage, by taking required parameters and adding the description to the list
        // of descriptions

        appState.setSpinnerVisibility(false);
        //After uploading, setting the spinner off...
      } else if (mimeType != null && mimeType.startsWith('image')) {
        appState.setSpinnerVisibility(true);
        //before uploading, setting the spinner on...

        await uploadImage(File(pickedFile.path), addDescription, appState);
        //uploading the video to firebase storage, by taking required parameters and adding the description to the list
        //of descriptions

        appState.setSpinnerVisibility(false);
        //After uploading, setting the spinner off...
      } else {
        print("Unsupported file type");
      }
    } else {
      print("No file selected");
    }
  }
}

Future<void> getImageCM(BuildContext context, Function(String) addDescription,
    AppState appState) async {
  //function for getting an image from the Camera
  //by taking the required parameters.
  final ImagePicker pickerCam = ImagePicker();
  final pickedFileCamera = await pickerCam.pickImage(
    source: ImageSource.camera,
    imageQuality: 100,
  );

  if (pickedFileCamera != null) {
    //if the file is picked from the camera.
    File imageCam = File(pickedFileCamera.path);
    appState.setSpinnerVisibility(true);
    await uploadImage(imageCam, addDescription, appState);
    //it will be uploaded to the firebase storage
    appState.setSpinnerVisibility(false);
  } else {
    print("No image Captured");
  }
}

Future<void> getVideoFile(BuildContext context, Function(String) addDescription,
    AppState appState) async {
  //function for getting a video from the Camera
  final ImagePicker pickerCam = ImagePicker();
  appState.setSpinnerVisibility(true);

  final videoFile = await pickerCam.pickVideo(source: ImageSource.camera);
  //will open camera to shoot a video, and that video file will be stored in the
  //variable videoFile.

  if (videoFile != null) {
    // if videoFile is not null

    final storageRef = FirebaseStorage.instance.ref();
    //storageRef for the firebase storage
    final uniqueId = const Uuid().v1();
    //uniqueId for the video file
    final fileRef = storageRef.child('$uniqueId.mp4');
    //fileRef for the video file

    await fileRef.putFile(File(videoFile.path)); //putFile for the video file
    //it will be uploaded to the firebase storage and stored in the fileRef

    final videoUrl =
        await fileRef.getDownloadURL(); //getDownloadURL for the video file
    //it will be downloaded from the firebase storage and stored in the videoUrl

    final response = await FirebaseFunctions
        .instance //This is an instance of the Firebase
        // Functions class, which allows us to interact with server-side functions deployed on Firebase
        .httpsCallable(
            'video') //call a server-side function deployed on Firebase using an HTTP request.
        .call({'data': videoUrl, 'mime_type': 'video/mp4'});
    //Calling HTTP request to the server-side function with
    //parameters, which is a map of data that we want to send along with the request.

    final data = response.data; //Response is recieved and displayed on screen.

    final description_Video_camera =
        ('Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');

    addDescription(
        description_Video_camera); //the response will be added to the
    // list of descriptions, which will be displayed on the screen.

    print(
        'Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');
  }
  //this will be displayed on the debug console for verification purposes.

  appState.setSpinnerVisibility(false);
  //After the description is displayed onscreen, the showspinner will be turned off.
}

Future<void> uploadImage(
    //function with parameters, used for uploading videos from the gallery
    File? imageFile,
    Function(String) addDescription,
    AppState appState) async {
  if (imageFile == null) return;

  appState.setSpinnerVisibility(true);
  //before uploading the spinner will be turned on.

  final bytes =
      await imageFile.readAsBytes(); //reads the contents of the imageFile
  //asynchronously and stores them in the bytes variable
  final base64Image =
      base64Encode(bytes); //converts the bytes into a Base64-encoded string
  //represent binary data as text
  final mimeType =
      lookupMimeType(imageFile.path); //returns the MIME type of the file

  if (mimeType == null) {
    print('Unsupported file format');
    appState.setSpinnerVisibility(false);
    //if it is an unsupported file format the spinner will be turned off.
    return;
  }

  final response = await FirebaseFunctions
      .instance //This is an instance of the Firebase
      .httpsCallable(
          'image') // Firebase Cloud Function with the name 'image' that is being called.
      .call(<String, dynamic>{
    //invoke the Firebase Cloud Function with the provided data
    'data':
        base64Image, //passing a Map object containing two key-value pairs: 'data' and 'mime_type'
    'mime_type':
        mimeType, //'data' and 'mime_type' are the keys and their corresponding values are
    //the Base64-encoded image and the MIME type of the image file, respectively.
  });
//response is stored in the response variable
  if (response.data != null) {
    final description =
        'Danger: ${response.data["Danger"]}\nTitle: ${response.data["Title"]}\nDescription: ${response.data["Description"]}';

    addDescription(description); //the response will be added to the
    // list of descriptions, which will be displayed on the screen.

    print(description);
    final data = response.data;
    print(data);
    print(
        'Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');
  } //Response is also displayed on the debug console for the verification purposes.
  else {
    print("Failed to upload");
    appState.setSpinnerVisibility(false);
    //After the description is displayed onscreen, the showspinner will be turned off.
  }

  appState.setSpinnerVisibility(false);
  //After the description is displayed onscreen, the showspinner will be turned off.
}

Future<void> uploadVideo(
    //This function is used to upload videos from the gallery
    File videoFile,
    Function(String) addDescription,
    AppState appState) async {
  final storageRef = FirebaseStorage.instance.ref();
  //storageRef for the firebase storage
  final uniqueId = const Uuid().v1();
  //uniqueId for the video file
  final fileRef = storageRef.child('$uniqueId.mp4');
  //fileRef for the video file
  await fileRef.putFile(videoFile); //uploads the video file to firebase storage

  final videoUrl =
      await fileRef.getDownloadURL(); //getDownloadURL for the video file
  //it will be downloaded from the firebase storage and stored in the videoUrl

  final response = await FirebaseFunctions
      .instance //This is an instance of the Firebase
      // Functions class, which allows us to interact with server-side functions deployed on Firebase
      .httpsCallable(
          'video') //call a server-side function deployed on Firebase using an HTTP request.
      .call({'data': videoUrl, 'mime_type': 'video/mp4'});
  //Calling HTTP request to the server-side function with
  //parameters, which is a map of data that we want to send along with the request.

  final data =
      response.data; //Response is recieved and displayed on Home screen.

  final descriptionVid =
      ('Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');
  //The response is stored in the descriptionVid variable

  addDescription(descriptionVid); //the response will be added to the
  // list of descriptions, which will be displayed on the screen.

  print(
      'Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');
  //this will be displayed on the debug console for verification purposes.

  appState.setSpinnerVisibility(false);
  //After the description is displayed onscreen, the showspinner will be turned off.
}
