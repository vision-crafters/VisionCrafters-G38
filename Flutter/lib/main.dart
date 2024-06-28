import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutterbasics/pages/Dashboard.dart';
import 'package:flutterbasics/pages/Settings.dart';
import 'package:flutterbasics/pages/Speech_To_Text.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutterbasics/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutterbasics/upload.dart';
import 'package:provider/provider.dart';
import 'app_state.dart'; // Import the AppState class
import 'package:sqflite/sqflite.dart';
import 'package:flutterbasics/services/database.dart';
import 'package:mime/mime.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter Firebase is initialized
  await dotenv.load(fileName: ".env");

  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  final database = await dbHelper.database;

  //Ensures that Firebase has been fully initialized before running the app.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    //Configures Firebase Functions to use a local emulator if
    //the app is running in debug mode.
    final host = dotenv.get('HOST');
    FirebaseFunctions.instanceFor(region: "us-central1")
        .useFunctionsEmulator(host, 5001);//Uses the local emulator
  }
  runApp(MyApp(database: database)); //Launches the root widget of the application
}

class MyApp extends StatelessWidget {
  final Database database;

  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: ChangeNotifierProvider(
      //Provides the AppState to the widget tree,
      //allowing state management.
      create: (_) => AppState(),
      child: MaterialApp(
        //Sets up the material design for the app,
        //including themes and the home page.
          debugShowCheckedModeBanner: false,
          title: "Vision Crafters",
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.system,
          home: HomePage(database: database),
      ),
        //The initial screen displayed when the app starts.
      ),
    );
  }
}

//A stateful widget that maintains the state of the home page.
class HomePage extends StatefulWidget {
  final Database database;

  const HomePage({super.key, required this.database}); //constructor for the HomePage widget

  @override
  State<HomePage> createState() => _HomePageState();//Creates the state of the widget
}

class _HomePageState extends State<HomePage> {
  bool showSpinner = false; //Boolean to control the display of a loading spinner.

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
    List<Map<String, dynamic>> data = await dbHelper.getConversationData(0);
    messages = List<Map<String, dynamic>>.from(data);
    developer.log(messages.toString());
    setState(() {});
  }

  Future<void> addMessage(final id, final role, final content, final mimeType,
      final path, final type) async {
    setState(() {
      messages.add({
        'id': id.toString(),
        'conversation_id': '0',
        'role': role,
        'content': content,
        'mime_type': mimeType,
        'path': path,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': type,
      });
    });
  }

  Future<void> getMedia(BuildContext context, AppState appState) async {
    File? mediaFileName = await pickMedia(context, appState);
    final mimetype = lookupMimeType(mediaFileName!.path);
    if (mimetype!.contains("image")) {
      final image = await saveImage(mediaFileName);
      addMessage(image['id'], 'user', '', mimetype, image['path'], 'media');
      Map<String, dynamic> upload = await uploadImage(mediaFileName, appState);
      final id =
          await dbHelper.insertMessage(0, "assistant", upload['Description']);
      addMessage(id, 'assistant', upload['Description'], '', '', 'message');
    } else {
      final video = await saveVideo(mediaFileName);
      addMessage(video['id'], 'user', '', mimetype, video['path'], 'media');

      Map<String, dynamic> upload = await uploadVideo(mediaFileName, appState);

      final id =
          await dbHelper.insertMessage(0, "assistant", upload['Description']);

      addMessage(id, 'assistant', upload['Description'], '', '', 'message');
    }
  }

  Future<void> getVideo(BuildContext context, AppState appState) async {
    File? videoFile = await getVideoFile(context, appState);
    final mimetype = lookupMimeType(videoFile!.path);
    final path = await saveVideo(videoFile);
    addMessage(path['id'], 'user', '', mimetype, path['path'], 'media');
    Map<String, dynamic> upload = await uploadVideo(videoFile, appState);
    final id =
        await dbHelper.insertMessage(0, "assistant", upload['Description']);
    addMessage(id, 'assistant', upload['Description'], '', '', 'message');
  }

  Future<void> getImage(BuildContext context, AppState appState) async {
    File? imageFile = await getImageCM(context, appState);
    Map<String, String> path = await saveImage(imageFile);
    final mimeType = lookupMimeType(imageFile!.path);

    await addMessage(path['id'], 'user', '', mimeType, path['path'], 'media');

    Map<String, dynamic> upload = await uploadImage(imageFile, appState);
    final id =
        await dbHelper.insertMessage(0, "assistant", upload['Description']);
    developer.log('Image path: $path');
    await addMessage(id, 'assistant', upload['Description'], '', '', 'message');
    developer.log('Image uploaded: ${upload['Description']}');
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      final id = await dbHelper.insertMessage(0, 'user', message);
      developer.log('Message sent to database: $message');
      _controller.clear();
      addMessage(id, 'user', message, '', '', 'message');
    }
  }


  @override
  Widget build(BuildContext context) {
    //Builds the UI of the home page
    final appState = Provider.of<AppState>(context);
    return GestureDetector(
      onDoubleTap: () {
        getImage(context, appState);
      },//Double tap gesture to open the camera
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => const Speech(),
        );
      },    
      child: Scaffold(
        appBar: AppBar(
          //Displays the title and a settings button.
        title: const Text("Vision Crafters"),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {//Function to be executed when the settings button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),//Navigates to the settings page
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          //Provides a navigation drawer
        width: MediaQuery.of(context).size.width * 0.8,
          child: DashBoardScreen(),//Displays the dashboard screen
        ),
        body: ModalProgressHUD(
          //Displays a loading spinner when appState.showSpinner is true
        inAsyncCall: appState.showSpinner,
          child: Column(
            children: [
              //Displays the UI of the home page
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
                // Displays a floating action button
              padding: const EdgeInsets.all(8.0), // Padding around the button
                child: Row(
                  //Contains a speed dial for image/video picking,a text
                //input field, and a microphone button for speech-to-text
                children: [
                    FloatingActionButton(
                      //Displays a speed dial for image/video picking
                    shape: const CircleBorder(),
                      heroTag: "UniqueTag2", //Unique identifier for the button
                      onPressed: () {},
                      child: SpeedDial(
                        //Speed dial for image/video picking
                      animatedIcon: AnimatedIcons
                          .menu_close, //Animated icon for the button
                        direction:
                          SpeedDialDirection.up, //Direction of the speed dial
                        children: [
                          //List of children for the speed dial
                        SpeedDialChild(
                            //Child for the camera button
                          shape: const CircleBorder(), //Shape of the button
                            child: const Icon(Icons.camera), //Icon for the button
                            onTap: () => getImage(context, appState),
                            //Function to be executed when the button is pressed
                          //Calls the getImageCM function with the context,
                          //addDescription, and appState as parameters
                        ),
                          SpeedDialChild(
                            //Child for the video button
                          shape: const CircleBorder(),
                            child: const Icon(Icons.video_call),
                            onTap: () => getVideo(context, appState),
                            // Function to be executed when the button is pressed
                          //Calls the getVideoFile function with the context,
                          //addDescription, and appState as parameters
                        ),
                          SpeedDialChild(
                            //Child for the gallery button
                          shape: const CircleBorder(),
                            child: const Icon(Icons.browse_gallery_sharp),
                            onTap: () => getMedia(context, appState),
                            //Function to be executed when the button is pressed
                          //Calls the pickMedia function with the context,
                          //addDescription, and appState as parameters
                        ),
                        ],
                      ),
                    ),
                    Expanded(
                      //Expanded widget to expand the text input field
                    child: Padding(
                        //Padding widget to add padding to the text input field
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextFormField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Enter your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      //Displays a microphone button for speech-to-text
                    onPressed:  _isFocused
                      ? _sendMessage
                      : () {
                      showDialog(
                          //Displays a dialog box for speech-to-text
                        context: context, //Context for the dialog box
                          builder: (context) =>
                            const Speech(), //Speech dialog box
                        // will be opened up when the microphone button is pressed
                        );
                      },
                      child: Icon(_isFocused ? Icons.send : Icons.mic), // Icon for the microphone button
                    ),
                  ], //end of children
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      //This places the FAB at the center of the bottom of the screen, docked 
      //within the BottomAppBar.
      ),
    );
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