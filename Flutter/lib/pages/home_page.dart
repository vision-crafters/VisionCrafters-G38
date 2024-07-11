import 'dart:async'; // Add this import for the Timer
import 'dart:io';
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
  int conversationId = -1;
  bool flag = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _startTimer();
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
    _timer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {}); // This will refresh the state periodically
    });
  }

  Future<void> _loadMessages() async {
    List<Map<String, dynamic>> data =
        await dbHelper.getConversationData(conversationId);
    messages = List<Map<String, dynamic>>.from(data);
    developer.log(messages.toString());
    setState(() {});
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      final id = await dbHelper.insertMessage(conversationId, 'user', message);
      developer.log('Message sent to database: $message');
      _controller.clear();
      addMessage(id, 'user', message, '', '', 'message');
    }
  }

  Future<void> getMedia(BuildContext context, AppState appState) async {
    File? mediaFileName = await _mediaPicker.pickMedia(context, appState);
    if (flag) {
      conversationId = await dbHelper.insertConversation();
    }

    if (mediaFileName != null) {
      final mimeType = lookupMimeType(mediaFileName.path);
      if (mimeType != null && mimeType.startsWith('image')) {
        final image = await _mediaSaver.saveImage(
            mediaFileName, mimeType, conversationId);
        addMessage(image['id'], 'user', '', mimeType, image['path'], 'media');

        Map<String, dynamic> upload =
            await _mediaUploader.uploadImage(mediaFileName, mimeType, appState);
        final id = await dbHelper.insertMessage(
            conversationId, "assistant", upload['Description']);
        addMessage(id.toString(), 'assistant', upload['Description'], '', '',
            'message');
        if (flag) {
          dbHelper.updateConversationWithId(upload['Title'], conversationId);
        }
      } else if (mimeType != null && mimeType.startsWith('video')) {
        final video = await _mediaSaver.saveVideo(
            mediaFileName, mimeType, conversationId);
        addMessage(video['id'].toString(), 'user', '', mimeType, video['path'],
            'media');

        Map<String, dynamic> upload =
            await _mediaUploader.uploadVideo(mediaFileName, mimeType, appState);
        final id = await dbHelper.insertMessage(
            conversationId, "assistant", upload['Description']);
        addMessage(id.toString(), 'assistant', upload['Description'], '', '',
            'message');
        if (flag) {
          dbHelper.updateConversationWithId(upload['Title'], conversationId);
          flag = false;
        }
      } else {
        developer.log("Unsupported file type");
      }
    }
  }

  Future<void> getVideo(BuildContext context, AppState appState) async {
    File? videoFile = await _mediaPicker.getVideoFile(context, appState);
    if (flag) {
      conversationId = await dbHelper.insertConversation();
    }
    if (videoFile != null) {
      final mimeType = lookupMimeType(videoFile.path);
      final path =
          await _mediaSaver.saveVideo(videoFile, mimeType, conversationId);
      addMessage(
          path['id'].toString(), 'user', '', mimeType, path['path'], 'media');

      Map<String, dynamic> upload =
          await _mediaUploader.uploadVideo(videoFile, mimeType, appState);
      final id = await dbHelper.insertMessage(
          conversationId, "assistant", upload['Description']);
      addMessage(
          id.toString(), 'assistant', upload['Description'], '', '', 'message');
      if (flag) {
        dbHelper.updateConversationWithId(upload['Title'], conversationId);
        flag = false;
      }
    }
  }

  Future<void> getImage(BuildContext context, AppState appState) async {
    File? imageFile = await _mediaPicker.getImageCM(context, appState);
    if (flag) {
      conversationId = await dbHelper.insertConversation();
    }
    if (imageFile != null) {
      final mimeType = lookupMimeType(imageFile.path);
      final path =
          await _mediaSaver.saveImage(imageFile, mimeType, conversationId);
      addMessage(
          path['id'].toString(), 'user', '', mimeType, path['path'], 'media');

      Map<String, dynamic> upload =
          await _mediaUploader.uploadImage(imageFile, mimeType, appState);
      final id = await dbHelper.insertMessage(
          conversationId, "assistant", upload['Description']);
      addMessage(
          id.toString(), 'assistant', upload['Description'], '', '', 'message');
      if (flag) {
        dbHelper.updateConversationWithId(upload['Title'], conversationId);
        flag = false;
      }
    }
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
          builder: (context) => const Speech(),
        );
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
                }),
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
                          ),
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: _isFocused
                          ? () {
                              _sendMessage();
                              FocusScope.of(context).unfocus();
                            }
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
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
