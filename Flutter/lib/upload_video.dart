import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  File? videoGal, videoCam;
  final _pickerGal = ImagePicker();
  final _pickerCam = ImagePicker();

  Future<void> getVideoFile(ImageSource sourceImg) async {
    // Firebase storage reference
    final storageRef = FirebaseStorage.instance.ref();   
    final videoFile = await ImagePicker().pickVideo(source: sourceImg);

    if (videoFile != null) {
       // Generate unique ID for the video
      final uniqueId = Uuid().v1();
      final fileRef = storageRef.child('$uniqueId.mp4');
      
      // Print the path of the picked video
      print('Picked video path: ${videoFile.path}');
      
      // Upload the picked video file to Firebase storage
      await fileRef.putFile(File(videoFile.path));
      
      // Get the download URL of the uploaded video
      final videoUrl = await fileRef.getDownloadURL();
      
      // Call the Firebase function to process the video
      final response = await FirebaseFunctions.instance.httpsCallable('video').call({
        'data': videoUrl,
        'mime_type': 'video/mp4'
      });
      
      // Extract and print response data
      final data = response.data;
      print('Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              getVideoFile(ImageSource.gallery);
            },
            child: Container(
                child: Center(
              child: ElevatedButton(
                  onPressed: () => getVideoFile(ImageSource.gallery),
                  child: Text("Pick a video")),
            )
                // : Container(
                //     child: Center(
                //       child: Image.file(
                //         File(imageGal!.path).absolute,
                //         height: 100,
                //         width: 100,
                //         fit: BoxFit.cover,
                //       ),
                //     ),
                //   ),
                ),
          ),
          GestureDetector(
            onTap: () {
              getVideoFile(ImageSource.gallery);
            },
            child: Container(
                child: Center(
              child: ElevatedButton(
                  onPressed: () => getVideoFile(ImageSource.camera),
                  child: Text("Take a Video")),
            )
                // : Container(
                //     child: Center(
                //       child: Image.file(
                //         File(imageCam!.path).absolute,
                //         height: 100,
                //         width: 100,
                //         fit: BoxFit.cover,
                //       ),
                //     ),
                //   ),
                ),
          ),
          SizedBox(
            height: 150,
          ),
        ],
      ),
    );
  }
}
