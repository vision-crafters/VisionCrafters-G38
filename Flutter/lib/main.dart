import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutterbasics/pages/Dashboard.dart';
import 'package:flutterbasics/pages/Settings.dart';
import 'package:flutterbasics/pages/Speech_To_Text.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutterbasics/firebase_options.dart';
import 'package:flutterbasics/upload_video.dart';
import 'package:flutterbasics/upload_image.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutterbasics/services/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize the local database
  final database = await initializeDatabase();

  if (kDebugMode) {
    // const host = '192.168.1.3';
    const host = '192.168.46.62';

    FirebaseFunctions.instanceFor(region: "us-central1")
        .useFunctionsEmulator(host, 5001);
  }
  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final Database database;

  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Vision Crafters",
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: HomePage(database: database),
    );
  }
}

class HomePage extends StatefulWidget {
  final Database database;

  const HomePage({super.key, required this.database});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _loadMessages();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  Future<void> _loadMessages() async {
    messages = await getMessages(widget.database);
    setState(() {});
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      await insertMessage(widget.database, 1, 'user', message);
      print(
          'Message sent to database: $message'); // Print the message to the terminal
      _controller.clear();
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vision Crafters"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
      body: Column(
        children: [
          const Center(
            child: Text(
              "Welcome to Vision Crafters",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message['role'] == 'user';
                if (message['is_image'] == 1) {
                  final imageProvider = AssetImage(message['content']);
                  return ListTile(
                    title: _buildImageBubble(imageProvider,
                        isMe: isMe, context: context),
                  );
                } else {
                  return ListTile(
                    title: _buildMessageBubble(message['content'],
                        isMe: isMe, context: context),
                  );
                }
              },
            ),
          ),
          Container(
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UploadImageScreen(
                                addDescriptionCallback: (path) async {
                                  await insertMessage(
                                      widget.database, 1, 'user', path,
                                      isImage: true);
                                  _loadMessages();
                                },
                              ),
                            ),
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
                                builder: (context) =>
                                    const UploadVideoScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Enter your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 0, 0, 0),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 8),
                        hintStyle: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                ),
                FloatingActionButton(
                  onPressed: _isFocused
                      ? _sendMessage
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => const Speech(),
                          );
                        },
                  child: Icon(_isFocused ? Icons.send : Icons.mic),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

Widget _buildImageBubble(ImageProvider image,
    {required bool isMe, required BuildContext context}) {
  final imageWidth = MediaQuery.of(context).size.width * 0.7;
  final alignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;

  return Row(
    mainAxisAlignment: alignment,
    children: [
      Container(
        constraints: BoxConstraints(maxWidth: imageWidth),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image(
            image: image,
            fit: BoxFit.cover,
            width: imageWidth,
            height: 150,
          ),
        ),
      ),
    ],
  );
}

Widget _buildMessageBubble(String message,
    {required bool isMe, required BuildContext context}) {
  final messageWidth = MediaQuery.of(context).size.width * 0.7;
  final alignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;

  return Row(
    mainAxisAlignment: alignment,
    children: [
      Container(
        constraints: BoxConstraints(maxWidth: messageWidth),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xff373E4E)
              : const Color.fromARGB(255, 58, 70, 99),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    ],
  );
}
