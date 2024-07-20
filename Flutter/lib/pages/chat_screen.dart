import 'dart:async';
import 'dart:io';
import 'package:flutterbasics/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutterbasics/widgets/message_bubble.dart';
import 'package:flutterbasics/widgets/image_bubble.dart';
import 'package:flutterbasics/widgets/video_bubble.dart';
import 'package:flutterbasics/pages/settings.dart';
import 'package:flutterbasics/services/database.dart';
import 'package:flutterbasics/providers/app_state.dart';
import 'dart:developer' as developer;

class ChatScreen extends StatefulWidget {
  final Database database;
  final int conversationId;

  const ChatScreen({
    super.key,
    required this.database,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  bool showSpinner = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> messages = [];
  late int conversationId;
  String conversation_title = '';

  @override
  void initState() {
    super.initState();
    conversationId = widget.conversationId;
    if (conversationId != -1) {
      _loadMessages();
      _getTitle(); // Fetch conversation title
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    List<Map<String, dynamic>> data =
        await dbHelper.getConversationData(conversationId);
    messages = List<Map<String, dynamic>>.from(data);
    developer.log(messages.toString());
    setState(() {});
  }

  Future<void> _getTitle() async {
    conversation_title = await dbHelper.getTitleByID(conversationId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: Text(conversation_title), // Use conversation_title here
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
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),
            const Padding(padding: EdgeInsets.only(right: 10.0)),
          ],
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
                          title: VideoBubble(
                            video: message['path'],
                            isMe: isMe,
                          ),
                        );
                      } else {
                        final imageProvider = File(message['path']);
                        developer.log('Image path: ${message['path']}');
                        return ListTile(
                          title: ImageBubble(
                            image: imageProvider,
                            isMe: isMe,
                          ),
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
            ],
          ),
        ),
      ),
    );
  }
}
