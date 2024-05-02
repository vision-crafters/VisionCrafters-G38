import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutterbasics/DashBoardScreen.dart';
import 'package:flutterbasics/Speech_To_Text.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';  
import 'package:flutterbasics/upload_video.dart';
import 'upload_image.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();  // Ensure Flutter Firebase is initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);  // Initialize Firebase

  // Point to local emulator during development
  if(kDebugMode){
    const host = '192.168.109.26';  // Localhost IP
    FirebaseFunctions.instanceFor(region: "us-central1").useFunctionsEmulator(host, 5001);
    FirebaseStorage.instance.useStorageEmulator(host, 9199);
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
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const isRecording = false;
    const icons = isRecording ? Icons.stop : Icons.mic;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Vision Crafters",
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ), //heading.
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.black,
            ),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.8,
        child: DashBoardScreen(),
      ),
      body: const Speech(),
      floatingActionButton: FloatingActionButton(
        heroTag: "UniqueTag1",
        onPressed: () {},
        child: SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          direction: SpeedDialDirection.up,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.camera),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UploadImageScreen()),
                );
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.video_call),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UploadVideoScreen()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
