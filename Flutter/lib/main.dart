import 'package:flutter/material.dart';
import 'package:flutterbasics/ChatScreen.dart';
import 'package:flutterbasics/DashBoardScreen.dart';
import 'package:flutterbasics/Speech_To_Text.dart';

import 'upload_image.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Vision Crafters",
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomePage(),
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
        heroTag: 'uniqueTag1', // Unique tag assigned here
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadImageScreen()),
          );
        },
        child: const Icon(Icons.camera_alt),
        backgroundColor: Colors.green,
        tooltip: 'Open camera',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
