import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutterbasics/DashBoardScreen.dart';
import 'package:flutterbasics/Settings.dart';
import 'package:flutterbasics/Speech_To_Text.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'upload_image.dart';

void main() {
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
                      onTap: () {},
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
