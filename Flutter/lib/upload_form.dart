import "dart:io";
// import 'package:video_player/video_player.dart';
import "package:flutter/material.dart";

class UploadForm extends StatefulWidget {
  // const UploadForm({super.key});

  final File videoFile;
  final String videoPath;

  UploadForm({
    required this.videoFile,
    required this.videoPath,
  });

  @override
  State<UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends State<UploadForm> {
//   late VideoPlayerController _controller;
// late Future<void> _initializeVideoPlayerFuture;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
