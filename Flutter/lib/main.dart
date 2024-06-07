import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutterbasics/DashBoardScreen.dart';
import 'package:flutterbasics/Settings.dart';
import 'package:flutterbasics/Speech_To_Text.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:mime/mime.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter Firebase is initialized
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform); // Initialize Firebase

  // Point to local emulator during development
  if (kDebugMode) {
    const host = '192.168.244.168'; // Localhost IP
    FirebaseFunctions.instanceFor(region: "us-central1")
        .useFunctionsEmulator(host, 5001);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Vision Crafters",
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> descriptions = [];
  // File VideoCam;
  File? imageGal;
  File? imageCam;
  final ImagePicker _pickerGal = ImagePicker();
  final ImagePicker _pickerCam = ImagePicker();

  bool showSpinner = false;

  void addDescription(String description) {
    setState(() {
      descriptions.add(description);
    });
  }

  Future<void> pickMedia(ImageSource source) async {
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
          source: source,
          imageQuality: 100, // High quality for images
          maxHeight: 1080, // Optional: limits the image size for performance
          maxWidth: 1920, // Optional: limits the image size for performance
        );
      } else if (choice == 'video') {
        pickedFile = await _pickerGal.pickVideo(source: source);
      }

      if (pickedFile != null) {
        final mimeType = lookupMimeType(pickedFile.path);

        // Check if the file is a video
        if (mimeType != null && mimeType.startsWith('video')) {
          // Handle video file
          setState(() {
            showSpinner = true; // Show spinner during upload
          });

          await uploadVideo(File(pickedFile.path));

          setState(() {
            showSpinner = false; // Hide spinner after upload
          });
        } else if (mimeType != null && mimeType.startsWith('image')) {
          // Handle image file
          setState(() {
            showSpinner = true; // Show spinner during upload
          });

          await uploadImage(File(pickedFile.path)); // Reusing existing method

          setState(() {
            showSpinner = false; // Hide spinner after upload
          });
        } else {
          print("Unsupported file type");
        }
      } else {
        print("No file selected");
      }
    }
  }

  Future getImageGL() async {
    final pickedFile_Gallery = await _pickerGal.pickImage(
        source: ImageSource.gallery,
        imageQuality:
            100); //100 will ensure high quality image is picked from the gallery. 0% compression, we might face memory issues in future if it exceeds the limit

    if (pickedFile_Gallery != null) {
      imageGal = File(pickedFile_Gallery.path);
      setState(() {});
      await uploadImage(imageGal);
    } else {
      print("No image selected");
    }
  }

  Future getImageCM() async {
    final pickedFile_Camera = await _pickerCam.pickImage(
        source: ImageSource.camera,
        imageQuality:
            100); // 100 will ensure high quality image is clicked and picked from the camera. 0% compression, we might face memory issues in future if it exceeds the limit

    if (pickedFile_Camera != null) {
      imageCam = File(pickedFile_Camera.path);
      setState(() {});
      await uploadImage(imageCam);
    } else {
      print("No image Captured");
    }
  }

  Future<void> uploadImage(File? imageFile) async {
    if (imageFile == null) return;

    setState(() {
      showSpinner = true;
    });

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = lookupMimeType(imageFile.path);

    if (mimeType == null) {
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

      addDescription(description);

      print(description);
      final data = response.data;
      print(data);
      print(
          'Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');
    } else {
      print("Failed to upload");
      setState(() {
        showSpinner = false;
      });
    }
  }

  Future<void> uploadVideo(File videoFile) async {
    final storageRef = FirebaseStorage.instance.ref();
    final uniqueId = Uuid().v1();
    final fileRef = storageRef.child('$uniqueId.mp4');

    await fileRef.putFile(videoFile);

    final videoUrl = await fileRef.getDownloadURL();

    final response = await FirebaseFunctions.instance
        .httpsCallable('video')
        .call({'data': videoUrl, 'mime_type': 'video/mp4'});

    final data = response.data;
    // addDescription(data);

    final description_Vid =
        ('Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');

    addDescription(description_Vid);

    print(
        'Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');
  }

  Future<void> getVideoFile(ImageSource sourceImg) async {
    setState(() {
      showSpinner = true;
    });
    final videoFile = await _pickerCam.pickVideo(source: sourceImg);

    if (videoFile != null) {
      final storageRef = FirebaseStorage.instance.ref();
      final uniqueId = Uuid().v1();
      final fileRef = storageRef.child('$uniqueId.mp4');

      await fileRef.putFile(File(videoFile.path));

      final videoUrl = await fileRef.getDownloadURL();

      final response = await FirebaseFunctions.instance
          .httpsCallable('video')
          .call({'data': videoUrl, 'mime_type': 'video/mp4'});

      final data = response.data;

      final description_Video_camera =
          ('Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');

      addDescription(description_Video_camera);

      print(
          'Danger: ${data["Danger"]}\nTitle: ${data["Title"]}\nDescription: ${data["Description"]}');
    }

    setState(() {
      showSpinner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Vision Crafters",
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.settings,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          width: MediaQuery.of(context).size.width * 0.8,
          child: DashBoardScreen(),
        ),
        body: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: Column(
            children: [
              const Center(
                child: Text(
                  "Welcome to Vision Crafters",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: descriptions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(descriptions[index]),
                    );
                  },
                ),
              ),
              Container(
                // color: Colors.black,
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      heroTag: "UniqueTag2",
                      onPressed: () {},
                      child: SpeedDial(
                        animatedIcon: AnimatedIcons.menu_close,
                        direction: SpeedDialDirection.up,
                        children: [
                          SpeedDialChild(
                            shape: const CircleBorder(),
                            child: const Icon(Icons.camera),
                            onTap: getImageCM,
                          ),
                          SpeedDialChild(
                            shape: const CircleBorder(),
                            child: const Icon(Icons.video_call),
                            onTap: () => getVideoFile(ImageSource.camera),
                          ),
                          SpeedDialChild(
                            shape: const CircleBorder(),
                            child: const Icon(Icons.browse_gallery_sharp),
                            onTap: () => pickMedia(ImageSource.gallery),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 8),
                            hintStyle: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const Speech(),
                        );
                      },
                      child: const Icon(Icons.mic),
                    ),
                  ],
                ),
              ),

              // ),
            ],
          ),
        ));
    floatingActionButtonLocation:
    FloatingActionButtonLocation.centerDocked;
  }
}
