import 'package:flutter/material.dart';
import 'package:flutterbasics/upload_form.dart';
import 'package:http/http.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:get/get.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  File? videoGal, videoCam;
  final _pickerGal = ImagePicker();
  final _pickerCam = ImagePicker();

  getVideoFile(ImageSource sourceImg) async {
    final videoFile = await ImagePicker().pickVideo(source: sourceImg);

    if (videoFile != null) {
      //video upload form
      Get.to(
        UploadForm(
          videoFile: File(videoFile.path),
          videoPath: videoFile.path,
        ),
      );
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
                  child: const Text("Pick a video")),
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
                  child: const Text("Take a Video")),
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
          const SizedBox(
            height: 150,
          ),
        ],
      ),
    );
  }
}
