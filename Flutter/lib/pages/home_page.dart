import 'dart:io';

import 'package:flutterbasics/services/flutter_tts.dart'; // for tts check in services folder
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutterbasics/widgets/message_bubble.dart';
import 'package:flutterbasics/widgets/image_bubble.dart';
import 'package:flutterbasics/widgets/video_bubble.dart';
import 'package:flutterbasics/pages/speech_to_text.dart';
import 'package:flutterbasics/pages/settings.dart';
import 'package:flutterbasics/pages/dashboard.dart';
import 'package:flutterbasics/services/database.dart';
import 'package:flutterbasics/services/media_picker.dart';
import 'package:flutterbasics/services/media_saver.dart';
import 'package:flutterbasics/services/media_upload.dart';
import 'package:flutterbasics/providers/app_state.dart';
import 'dart:developer' as developer;
import 'package:flutterbasics/services/beep_sound.dart';
//A stateful widget that maintains the state of the home page.
class HomePage extends StatefulWidget {
  final Database database;

  const HomePage(
      {super.key,
      required this.database}); //constructor for the HomePage widget

  @override
  State<HomePage> createState() =>
      _HomePageState(); //Creates the state of the widget
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  bool showSpinner =
      false; //Boolean to control the display of a loading spinner.
  bool _isFocused = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> messages = [];
  final MediaPicker _mediaPicker = MediaPicker();
  final MediaSaver _mediaSaver = MediaSaver();
  final MediaUploader _mediaUploader = MediaUploader();
  late File fileName;
  late String? mimeType;
  final TTSService _ttsService = TTSService();
  
  final BeepSound _beep = BeepSound();
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

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      final id = await dbHelper.insertMessage(0, 'user', message);
      developer.log('Message sent to database: $message');
      _controller.clear();
      addMessage(id, 'user', message, '', '', 'message');
      final response = await _mediaUploader.uploadQuery(
          messages, fileName, mimeType, message);
      final id2 =
          await dbHelper.insertMessage(0, 'assistant', response['Description']);
      await _beep.makeDangerAlert(); // makes danger alert after every response
      _ttsService.speak(response['Description']);
      addMessage(id2, 'assistant', response['Description'], '', '', 'message');
    }
  }

  Future<void> getMedia(BuildContext context, AppState appState) async {
    Map<String, dynamic> upload = {};
    fileName = await _mediaPicker.pickMedia(context, appState);
    mimeType = lookupMimeType(fileName.path);
    if (mimeType != null && mimeType!.startsWith('image')) {
      final image = await _mediaSaver.saveImage(fileName, mimeType);
      addMessage(image['id'], 'user', '', mimeType, image['path'], 'media');

      upload = await _mediaUploader.uploadImage(fileName, mimeType, appState);
    } else if (mimeType != null && mimeType!.startsWith('video')) {
      final video = await _mediaSaver.saveVideo(fileName, mimeType);
      addMessage(
          video['id'].toString(), 'user', '', mimeType, video['path'], 'media');

      upload = await _mediaUploader.uploadVideo(fileName, mimeType, appState);
    }
    final id =
        await dbHelper.insertMessage(0, "assistant", upload['Description']);
    if(upload['Danger'].startsWith("Yes")) await _beep.makeDangerAlert(); // makes danger alert after every response
    await Future.delayed(const Duration(seconds: 1)); // make a delay after beep
    _ttsService.speak(upload['Description']);
   
    addMessage(
        id.toString(), 'assistant', upload['Description'], '', '', 'message');
  }

  Future<void> getVideo(BuildContext context, AppState appState) async {
    fileName = await _mediaPicker.getVideoFile(context, appState);
    mimeType = lookupMimeType(fileName.path);
    final path = await _mediaSaver.saveVideo(fileName, mimeType);
    addMessage(
        path['id'].toString(), 'user', '', mimeType, path['path'], 'media');

    Map<String, dynamic> upload =
        await _mediaUploader.uploadVideo(fileName, mimeType, appState);
    final id =
        await dbHelper.insertMessage(0, "assistant", upload['Description']);
    if(upload['Danger'].startsWith("Yes")) await _beep.makeDangerAlert(); // makes danger alert after every response
    await Future.delayed(const Duration(seconds: 1));
    _ttsService.speak(upload['Description']);
    

    addMessage(
        id.toString(), 'assistant', upload['Description'], '', '', 'message');
  }

  Future<void> getImage(BuildContext context, AppState appState) async {
    fileName = await _mediaPicker.getImageCM(context, appState);
    mimeType = lookupMimeType(fileName.path);
    final path = await _mediaSaver.saveImage(fileName, mimeType);
    addMessage(
        path['id'].toString(), 'user', '', mimeType, path['path'], 'media');

    Map<String, dynamic> upload =
        await _mediaUploader.uploadImage(fileName, mimeType, appState);
    final id = await dbHelper.insertMessage(0, "assistant", upload['Description']);
    if(upload['Danger'].startsWith("Yes")) await _beep.makeDangerAlert(); // makes danger alert after every response'
    await Future.delayed(const Duration(seconds: 1));
    _ttsService.speak(upload['Description']);
      

    addMessage(
        id.toString(), 'assistant', upload['Description'], '', '', 'message');
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
        'timestamp': DateTime.now(),
        'type': type,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    //Builds the UI of the home page
    final appState = Provider.of<AppState>(context);
    return GestureDetector(
      onDoubleTap: () {
        getImage(context, appState);
      }, //Double tap gesture to open the camera
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
              onPressed: () {
                //Function to be executed when the settings button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const SettingsPage()), //Navigates to the settings page
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          //Provides a navigation drawer
          width: MediaQuery.of(context).size.width * 0.8,
          child: DashBoardScreen(), //Displays the dashboard screen
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
                      if (message['mime_type'].contains('video')) {
                        return ListTile(
                          title:
                              VideoBubble(video: message['path'], isMe: isMe),
                        );
                      } else {
                        final imageProvider = File(message['path']);
                        developer.log('Image path: ${message['path']}');
                        return ListTile(
                          title: ImageBubble(image: imageProvider, isMe: isMe),
                        );
                      }
                    } else {
                      return ListTile(
                        title: MessageBubble(
                          message: message['content'],
                          isMe: isMe,
                        ),
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
                            child:
                                const Icon(Icons.camera), //Icon for the button
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
                      onPressed: _isFocused
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
                      child: Icon(_isFocused
                          ? Icons.send
                          : Icons.mic), // Icon for the microphone button
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