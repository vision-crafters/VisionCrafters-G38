import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutterbasics/DashBoardScreen.dart';
import 'package:flutterbasics/Settings.dart';
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
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
      body: const Center(
        child: Text(
          "Welcome to Vision Crafters",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
              ),
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const UploadImageScreen()),
                        );
                      },
                    ),
                    SpeedDialChild(
                      shape: const CircleBorder(),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 243, 240, 240),
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
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
