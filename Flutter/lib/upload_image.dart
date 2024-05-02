import 'dart:io';
// import 'dart:js_interop';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';


class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({Key? key}) : super(key: key);

  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? imageGal, imageCam;
  final _pickerGal = ImagePicker();
  final _pickerCam = ImagePicker();
  bool showSpinner = false;

  Future getImageGL() async {
    final pickedFile_Gallery = await _pickerGal.pickImage(
        source: ImageSource.gallery, imageQuality: 80);

        

    if (pickedFile_Gallery != null) {
      imageGal = File(pickedFile_Gallery.path);
      setState(() {});
      uploadImageFromGallery();
    } else {
      print("No image selected");
    }
  }

  Future getImageCM() async {
    final pickedFile_Camera = await _pickerCam.pickImage(
        source: ImageSource.camera, imageQuality: 80);

    if (pickedFile_Camera != null) {
      imageCam = File(pickedFile_Camera.path);
      setState(() {});
      uploadImageFromCamera();
    } else {
      print("No image Captured");
    }
  }

  Future<void> uploadImageFromGallery() async {
    setState(() {
      showSpinner = true;
    });

    final bytes = await imageGal!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await FirebaseFunctions.instance.httpsCallable('image').call(<String, dynamic>{
      'data': base64Image,
      'mime_type': 'image/jpeg'
    });

    if (response.data != null) {
      setState(() {
        showSpinner = false;
      });

    final data = response.data;
    print(data);
    print('Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');
            

    } else {
      print("failed to upload");
      setState(() {
        showSpinner = true;
      });
    }
  }

  Future<void> uploadImageFromCamera() async {
    setState(() {
      showSpinner = true;
    });
    final bytes = await imageCam!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await FirebaseFunctions.instance.httpsCallable('image').call(<String, dynamic>{
      'data': base64Image,
      'mime_type': 'image/jpeg'
    });

    if (response.data != null) {
      setState(() {
        showSpinner = false;
      });

    final data = response.data;
    print(data);
    print('Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');
      
    } else {
      print("failed to upload");
      setState(() {
        showSpinner = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Upload Image'),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  getImageGL();
                },
                child: Container(
                  child: imageGal == null
                      ? Center(
                          child: ElevatedButton(
                              onPressed: getImageGL,
                              child: Text("Pick an image")),
                        )
                      : Container(
                          child: Center(
                            child: Image.file(
                              File(imageGal!.path).absolute,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  getImageCM();
                },
                child: Container(
                  child: imageCam == null
                      ? Center(
                          child: ElevatedButton(
                              onPressed: getImageCM,
                              child: Text("Click an image")),
                        )
                      : Container(
                          child: Center(
                            child: Image.file(
                              File(imageCam!.path).absolute,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(
                height: 150,
              ),
            ],
          ),
        ));
  }
}
