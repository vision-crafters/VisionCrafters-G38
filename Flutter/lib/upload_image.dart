import 'dart:io';
// import 'dart:js_interop';
// import 'dart:js_interop';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';

class UploadImageScreen extends StatefulWidget {
  final Function(String) addDescriptionCallback;
  const UploadImageScreen({Key? key, required this.addDescriptionCallback})
      : super(key: key);

  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? imageGal, imageCam;
  final _pickerGal = ImagePicker();
  final _pickerCam = ImagePicker();
  bool showSpinner = false;
  List<String> descriptions = [];

  Future getImageGL() async {
    final pickedFile_Gallery = await _pickerGal.pickImage(
        source: ImageSource.gallery, imageQuality: 100); //100 will ensure
    // high quality image is picked from the gallery.
//0% compression, we might face memory issues.in future if it exceeds the limit

    if (pickedFile_Gallery != null) {
      imageGal = File(pickedFile_Gallery.path);
      setState(() {});
      await uploadImageFromGallery();
    } else {
      print("No image selected");
    }
  }

  Future getImageCM() async {
    final pickedFile_Camera = await _pickerCam.pickImage(
        source: ImageSource.camera, imageQuality: 100);
//100 will ensure high quality image is clcicked and picked from the camera.
//0% compression, we might face memory issues.in future if it exceeds the limit
    if (pickedFile_Camera != null) {
      imageCam = File(pickedFile_Camera.path);
      setState(() {});
      await uploadImageFromCamera();
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

    // Determine the file extension of the selected image
    String mimeType;
    if (imageGal!.path.toLowerCase().endsWith('.jpg') ||
        imageGal!.path.toLowerCase().endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    } else if (imageGal!.path.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    } else {
      print('Unsupported file format');
      setState(() {
        showSpinner = false;
      });
      return;
    }

    final response = await FirebaseFunctions.instance
        .httpsCallable('image')
        .call(<String, dynamic>{
      'data': base64Image,
      'mime_type': mimeType,
    });

    if (response.data != null) {
      setState(() {
        showSpinner = false;
      });

      final description =
          'Danger: ${response.data["Danger"]}\nTitle: ${response.data["Title"]}\nDescription: ${response.data["Description"]}';

      widget.addDescriptionCallback(description);

      Navigator.pop(context);
      print(description);
      final data = response.data;
      print(data);
      print(
          'Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');
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

    // Determine the file extension of the captured image
    String mimeType;
    if (imageCam!.path.toLowerCase().endsWith('.jpg') ||
        imageCam!.path.toLowerCase().endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    } else if (imageCam!.path.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    } else {
      print('Unsupported file format');
      setState(() {
        showSpinner = false;
      });
      return;
    }

    final response = await FirebaseFunctions.instance
        .httpsCallable('image')
        .call(<String, dynamic>{
      'data': base64Image,
      'mime_type': mimeType,
    });

    if (response.data != null) {
      setState(() {
        showSpinner = false;
      });

      final description =
          'Danger: ${response.data["Danger"]}\nTitle: ${response.data["Title"]}\nDescription: ${response.data["Description"]}';

      widget.addDescriptionCallback(description);
      Navigator.pop(context);
      print(description);
      final data = response.data;

      print(data);

      print(
          'Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');
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
      ),
    );
  }
}
