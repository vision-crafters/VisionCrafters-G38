import 'package:flutter/material.dart';
import 'package:flutterbasics/DashBoardScreen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Padding(
        padding: const EdgeInsets.only(left: 14, right: 14),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.pop(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => DashBoardScreen())));
                      },
                      child:
                          const Icon(Icons.arrow_back, color: Colors.white70)),
                  const SizedBox(width: 20),
                  const Text(
                    "Viishhnu",
                    style: TextStyle(
                      fontSize: 19,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.search,
                    color: Colors.white70,
                    size: 30,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  "1 FEB 12:00",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildMessageBubble(
                "I am a Flutter Developer, I love building amazing apps!",
                isMe: true,
                context: context,
              ),
              const SizedBox(height: 20),
              _buildMessageBubble(
                "I am also an Android developer! I work on iOS apps!",
                isMe: false,
                context: context,
              ),
              const SizedBox(height: 20),
              _buildMessageBubble(
                "I am a Flutter Developer, I love building amazing apps!",
                isMe: true,
                context: context,
              ),
              const SizedBox(height: 20),
              _buildMessageBubble(
                "I am also an Android developer! I work on iOS apps!",
                isMe: false,
                context: context,
              ),
              const SizedBox(height: 20),
              _buildMessageBubble(
                "I am a Flutter Developer, I love building amazing apps!",
                isMe: true,
                context: context,
              ),
              const SizedBox(height: 20),
              _buildMessageBubble(
                "Goodbye",
                isMe: false,
                context: context,
              ),
            ],
          ),
        ),
      ),
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
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
