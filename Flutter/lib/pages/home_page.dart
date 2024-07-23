import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutterbasics/pages/dashboard.dart';
import 'package:flutterbasics/pages/settings.dart';
import 'package:flutterbasics/pages/speech_to_text.dart';
import 'package:flutterbasics/providers/app_state.dart';
import 'package:flutterbasics/services/beep_sound.dart';
import 'package:flutterbasics/services/database.dart';
import 'package:flutterbasics/services/flutter_tts.dart';
import 'package:flutterbasics/services/media_picker.dart';
import 'package:flutterbasics/services/media_saver.dart';
import 'package:flutterbasics/services/media_upload.dart';
import 'package:flutterbasics/widgets/image_bubble.dart';
import 'package:flutterbasics/widgets/message_bubble.dart';
import 'package:flutterbasics/widgets/video_bubble.dart';
import 'package:flutterbasics/widgets/dialog_box.dart';
import 'package:mime/mime.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class HomePage extends StatefulWidget {
  final Database database;

  const HomePage({super.key, required this.database});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  bool showSpinner = false;
  bool _isFocused = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> messages = [];
  final MediaPicker _mediaPicker = MediaPicker();
  final MediaSaver _mediaSaver = MediaSaver();
  final MediaUploader _mediaUploader = MediaUploader();
  late File? fileName = null;
  late String? mimeType = null;
  final TTSService _ttsService = TTSService();
  final BeepSound _beep = BeepSound();
  int conversationId = -1;
  bool flag = true;
  final ScrollController _scrollController =
      ScrollController(); // Add this line

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    if (conversationId != -1) {
      _loadMessages();
      flag = false;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose(); // Dispose the ScrollController
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  Future<void> _loadMessages() async {
    List<Map<String, dynamic>> data =
        await dbHelper.getConversationData(conversationId);
    messages = List<Map<String, dynamic>>.from(data);
    developer.log(messages.toString());
    setState(() {});
  }

  void _sendMessage(String text, AppState appState) async {
    String message = text.trim();
    if (fileName == null) {
      DialogBox.showErrorDialog(context, 'No File Selected',
          'Please select a image/video before sending a message.');
      _controller.clear(); // to clear the text box after displaying the error
      return;
    }
    if (message.isNotEmpty) {
      try {
        final id =
            await dbHelper.insertMessage(conversationId, 'user', message);
        developer.log('Message sent to database: $message');
        _controller.clear();
        addMessage(id, 'user', message, '', '', 'message');
        final response = await _mediaUploader.uploadQuery(
            messages, fileName, mimeType, appState);
        final id2 = await dbHelper.insertMessage(
            conversationId, 'assistant', response['Description']);
        _ttsService.setSpeechRate(0.6);
        _ttsService.setLanguage("hi-IN");
        _ttsService.speak(response['Description']);
        addMessage(
            id2, 'assistant', response['Description'], '', '', 'message');
        _scrollToBottom(); // Scroll to the bottom after sending a message
      } catch (e) {
        DialogBox.showErrorDialog(context, 'Message Send Failed',
            'The message could not be sent. Please try again.');
      }
    }
  }

  Future<void> getMedia(BuildContext context, AppState appState) async {
    Map<String, dynamic> upload = {};
    fileName = await _mediaPicker.pickMedia(context, appState);
    if (fileName == null) {
      return;
    }
    if (flag) {
      conversationId = await dbHelper.insertConversation();
    }
    try {
      mimeType = lookupMimeType(fileName!.path);
      if (mimeType != null && mimeType!.startsWith('image')) {
        final image =
            await _mediaSaver.saveImage(fileName, mimeType, conversationId);
        addMessage(image['id'], 'user', '', mimeType, image['path'], 'media');
        upload = await _mediaUploader.uploadImage(fileName, mimeType, appState);
      } else if (mimeType != null && mimeType!.startsWith('video')) {
        final video =
            await _mediaSaver.saveVideo(fileName, mimeType, conversationId);
        addMessage(video['id'].toString(), 'user', '', mimeType, video['path'],
            'media');
        upload = await _mediaUploader.uploadVideo(fileName, mimeType, appState);
      } else {
        throw Exception('Unsupported media type');
      }

      final id = await dbHelper.insertMessage(
          conversationId, "assistant", upload['Description']);
      addMessage(
          id.toString(), 'assistant', upload['Description'], '', '', 'message');
      if (flag) {
        dbHelper.updateConversationWithId(upload['Title'], conversationId);
        flag = false;
      }
      if (upload['Danger'].startsWith("Yes")) {
        await _beep
            .makeDangerAlert(); // makes danger alert after every response
        await Future.delayed(
            const Duration(seconds: 1)); // make a delay after beep
      }
      _ttsService.setSpeechRate(0.6);
      _ttsService.setLanguage("hi-IN");
      _ttsService.speak(upload['Description']);
      _scrollToBottom(); // Scroll to the bottom after sending a message
    } catch (e) {
      appState.setSpinnerVisibility(false);
      if (mimeType != null && mimeType!.startsWith('image')) {
        DialogBox.showErrorDialog(context, 'Image Upload Failed',
            'The image could not be uploaded from media. Please try again.');
      } else if (mimeType != null && mimeType!.startsWith('video')) {
        DialogBox.showErrorDialog(context, 'Video Upload Failed',
            'The video could not be uploaded from media. Please try again.');
      } else {
        DialogBox.showErrorDialog(context, 'Media Upload Failed',
            'The media could not be uploaded. Please try again.');
      }
    }
  }

  Future<void> getVideo(BuildContext context, AppState appState,
      DragStartDetails? details) async {
    fileName = await _mediaPicker.getVideoFile(context, appState);
    if (fileName == null) {
      return;
    }
    if (flag) {
      conversationId = await dbHelper.insertConversation();
    }
    try {
      mimeType = lookupMimeType(fileName!.path);
      final path =
          await _mediaSaver.saveVideo(fileName, mimeType, conversationId);
      addMessage(
          path['id'].toString(), 'user', '', mimeType, path['path'], 'media');

      Map<String, dynamic> upload =
          await _mediaUploader.uploadVideo(fileName, mimeType, appState);
      final id = await dbHelper.insertMessage(
          conversationId, "assistant", upload['Description']);
      addMessage(
          id.toString(), 'assistant', upload['Description'], '', '', 'message');
      if (flag) {
        dbHelper.updateConversationWithId(upload['Title'], conversationId);
        flag = false;
      }
      if (upload['Danger'].startsWith("Yes")) {
        await _beep
            .makeDangerAlert(); // makes danger alert after every response
        await Future.delayed(
            const Duration(seconds: 1)); // make a delay after beep
      }
      _ttsService.setSpeechRate(0.6);
      _ttsService.setLanguage("hi-IN");
      _ttsService.speak(upload['Description']);
      _scrollToBottom();
    } catch (e) {
      appState.setSpinnerVisibility(false);
      DialogBox.showErrorDialog(context, 'Video Upload Failed',
          'The video could not be uploaded. Please try again.');
    }
  }

  Future<void> getImage(BuildContext context, AppState appState) async {
    fileName = await _mediaPicker.getImageCM(context, appState);
    if (fileName == null) {
      return;
    }
    if (flag) {
      conversationId = await dbHelper.insertConversation();
    }
    try {
      mimeType = lookupMimeType(fileName!.path);
      final path =
          await _mediaSaver.saveImage(fileName, mimeType, conversationId);
      addMessage(
          path['id'].toString(), 'user', '', mimeType, path['path'], 'media');

      Map<String, dynamic> upload =
          await _mediaUploader.uploadImage(fileName, mimeType, appState);
      final id = await dbHelper.insertMessage(
          conversationId, "assistant", upload['Description']);
      addMessage(
          id.toString(), 'assistant', upload['Description'], '', '', 'message');
      if (flag) {
        dbHelper.updateConversationWithId(upload['Title'], conversationId);
        flag = false;
      }
      if (upload['Danger'].startsWith("Yes")) {
        await _beep
            .makeDangerAlert(); // makes danger alert after every response
        await Future.delayed(
            const Duration(seconds: 1)); // make a delay after beep
      }
      _ttsService.setSpeechRate(0.6);
      _ttsService.setLanguage("hi-IN");
      _ttsService.speak(upload['Description']);
      _scrollToBottom(); // Scroll to the bottom after sending a message
    } catch (e) {
      appState.setSpinnerVisibility(false);
      DialogBox.showErrorDialog(context, 'Image Upload Failed',
          'The image could not be uploaded. Please try again.');
    }
  }

  Future<void> addMessage(final id, final role, final content, final mimeType,
      final path, final type) async {
    setState(() {
      messages.add({
        'id': id.toString(),
        'conversation_id': conversationId,
        'role': role,
        'content': content,
        'mime_type': mimeType,
        'path': path,
        'timestamp': DateTime.now(),
        'type': type,
      });
    });
    _scrollToBottom(); // Scroll to the bottom after sending a message
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      onDoubleTap: () {
        getImage(context, appState);
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => Speech(
            onSpeechResult: (result) {
              _sendMessage(result, appState); // Pass speech result to sendMessage
              Navigator.pop(context);
            },
          ),
        );
      },
      onHorizontalDragStart: (DragStartDetails? details) {
        getVideo(context, appState, details);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Vision Crafters"),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      database: widget.database,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            const Padding(padding: EdgeInsets.only(right: 10.0)),
          ],
        ),
        drawer: Drawer(
          width: MediaQuery.of(context).size.width * 0.8,
          child: DashBoardScreen(
            database: widget.database,
          ),
        ),
        body: ModalProgressHUD(
          // Displays a loading spinner when appState.showSpinner is true
          inAsyncCall: appState.showSpinner,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController, // Attach ScrollController
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
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      heroTag: "UniqueTag2",
                      onPressed:
                          () {}, // onPressed is required but does not need to do anything
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
                            onTap: () => getVideo(context, appState, null),
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
                          ),
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: _isFocused
                          ? () {
                              _sendMessage(_controller.text, appState);
                              FocusScope.of(context).unfocus();
                            }
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => Speech(
                                  onSpeechResult: (result) {
                                    _sendMessage(result,
                                        appState); // Pass speech result to sendMessage
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                      child: Icon(_isFocused ? Icons.send : Icons.mic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
