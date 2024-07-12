import 'package:flutter/material.dart';
import 'dart:io';

class ImageBubble extends StatelessWidget {
  final File image;
  final bool isMe;

  const ImageBubble({super.key, required this.image, required this.isMe});

  @override
  Widget build(BuildContext context) {
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
}
