import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutterbasics/pages/Dashboard.dart';
import 'package:flutterbasics/pages/Settings.dart';
import 'package:flutterbasics/pages/Speech_To_Text.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter/foundation.dart';
import 'package:flutterbasics/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutterbasics/upload.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'app_state.dart'; // Import the AppState class
import 'package:sqflite/sqflite.dart';
import 'package:flutterbasics/services/database.dart';
import 'package:mime/mime.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  final database = await dbHelper.database;
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform); // Initialize Firebase

  // Point to local emulator during development
  if (kDebugMode) {
    final host = dotenv.get('HOST'); // Localhost IP
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
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Vision Crafters",
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: HomePage(database: database),
      ),
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
  List<Map<String, dynamic>> descriptions = [];
  File? imageGal;
  File? imageCam;
  bool showSpinner = false;

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
    messages = await dbHelper.getMessages(1);
    setState(() {});
  }

  Future<void> getMedia(BuildContext context, AppState appState) async {
    File? path = await pickMedia(context, addDescription, appState);
    final mimetype = lookupMimeType(path!.path);
    if(mimetype!.contains("image")){
      final image = await saveImage(path);
      messages.add(
        {
          'id': image['id'],
          'conversation_id': '0',
          'role': 'user',
          'content': '',
          'mime_type': '',
          'path': image['path'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'type': 'media',
        },
      );
      Map<String, dynamic> upload =
          await uploadImage(path, addDescription, appState);
      messages.add(
        {
          'id': '',
          'conversation_id': '0',
          'role': 'assistant',
          'content': upload['Description'],
          'mime_type': '',
          'path': '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'type': 'message',
        },
      );
    }
    else{
      final video = await saveVideo(path);
      messages.add(
        {
          'id': video['id'],
          'conversation_id': '0',
          'role': 'user',
          'content': '',
          'mime_type': '',
          'path': video['path'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'type': 'media',
        },
      );
      Map<String, dynamic> upload =
          await uploadVideo(path, addDescription, appState);
      messages.add(
        {
          'id': '',
          'conversation_id': '0',
          'role': 'assistant',
          'content': upload['Description'],
          'mime_type': '',
          'path': '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'type': 'message',
        },
      );
    }
  }

  Future<void> getVideo(BuildContext context, AppState appState) async {
    File? videoFile = await getVideoFile(context, addDescription, appState);
    final mimetype = lookupMimeType(videoFile!.path);
    final path = await saveVideo(videoFile);
    messages.add(
      {
        'id': path['id'],
        'conversation_id': '0',
        'role': 'user',
        'content': '',
        'mime_type': '',
        'path': path['path'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'media',
      },
    );
    Map<String, dynamic> upload =
        await uploadVideo(videoFile, addDescription, appState);
    messages.add(
      {
        'id': '',
        'conversation_id': '0',
        'role': 'assistant',
        'content': upload['Description'],
        'mime_type': '',
        'path': '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'message',
      },
    );
  }

  Future<void> getImage(BuildContext context, AppState appState) async {
    File? imageFile = await getImageCM(context, addDescription, appState);
    Map<String, String> path = await saveImage(imageFile);

      messages.add(
        {
          'id': path['id'],
          'conversation_id': '0',
          'role': 'user',
          'content': '',
          'mime_type': '',
          'path': path['path'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'type': 'media',
        },
      );

    Map<String, dynamic> upload =
        await uploadImage(imageFile, addDescription, appState);
    developer.log('Image path: $path');
      messages.add(
        {
          'id': '',
          'conversation_id': '0',
          'role': 'assistant',
          'content': upload['Description'],
          'mime_type': '',
          'path': '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'type': 'message',
        },
      );
      dbHelper.insertMessage(1, "assistant", descriptions.last['Description']);
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      await dbHelper.insertMessage(1, 'user', message);
      developer.log('Message sent to database: $message');
      _controller.clear();
      messages.add(
        {
          'id': '',
          'conversation_id': '0',
          'role': 'user',
          'content': message,
          'mime_type': '',
          'path': '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'type': 'message',
        },
      );
    }
  }

  void addDescription(Map<String, dynamic> description) {
    setState(() {
      descriptions.add(description);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
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
        body: ModalProgressHUD(
          inAsyncCall: appState.showSpinner,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['role'] == 'user';
                    developer.log('Message: ${message['type']}');
                    if (message['type'] == 'media') {
                      final imageProvider = File(message['path']);
                      developer.log('Image path: ${message['path']}');
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
                            onTap: () => getImage(context, appState),
                          ),
                          SpeedDialChild(
                            shape: const CircleBorder(),
                            child: const Icon(Icons.video_call),
                            onTap: () => getVideo(context, appState),
                          ),
                          SpeedDialChild(
                            shape: const CircleBorder(),
                            child: const Icon(Icons.browse_gallery_sharp),
                            onTap: () => getMedia(context, appState),
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
        ));
  }
}

Widget _buildImageBubble(File image,
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
          child: Image.file(image),
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
