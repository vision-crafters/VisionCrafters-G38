import 'package:flutter/material.dart';
import 'package:visioncrafters/pages/chat_screen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:visioncrafters/services/database.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class DashBoardScreen extends StatefulWidget {
  final Database database;

  const DashBoardScreen({super.key, required this.database});

  @override
  DashBoardState createState() => DashBoardState();
}

class DashBoardState extends State<DashBoardScreen> {
  late Database database;
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> conversations = [];

  Future<void> _load() async {
    List<Map<String, dynamic>> items = await dbHelper.getAllConversations();
    conversations = List<Map<String, dynamic>>.from(items);
    conversations = conversations.where((item) => item["title"] != null).toList();
    developer.log('Conversations: ${conversations.toString()}');
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Container(
              height: 70,
              color: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/logo.jpg'),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = conversations[index];
                  String formattedTime = DateFormat('HH:mm')
                      .format(DateTime.parse(item["timestamp"]));
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            database: widget.database,
                            conversationId: item['conversation_id'],
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      flex: 3,
                                      child: Text(
                                        item["title"]!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Flexible(
                                      flex: 1,
                                      child: Text(
                                        formattedTime,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  color: Colors.black,
                                  thickness: 1,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
