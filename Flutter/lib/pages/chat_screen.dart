import 'dart:async';
import 'dart:io';
import 'package:visioncrafters/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:visioncrafters/widgets/message_bubble.dart';
import 'package:visioncrafters/widgets/image_bubble.dart';
import 'package:visioncrafters/widgets/video_bubble.dart';
import 'package:visioncrafters/pages/settings.dart';
import 'package:visioncrafters/services/database.dart';
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
  List<Map<String, dynamic>> messages = [];
  late int conversationId;
  String conversationTitle = '';

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
    conversationTitle = await dbHelper.getTitleByID(conversationId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(conversationTitle), // Use conversation_title here
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
      body: Column(
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
    );
  }
}