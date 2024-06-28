import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class VideoRecordingScreen extends StatefulWidget {
  final CameraController controller;

  const VideoRecordingScreen({Key? key, required this.controller})
      : super(key: key);

  @override
  _VideoRecordingScreenState createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _recordVideo() async {
    try {
      await _initializeControllerFuture;

      if (!_isRecording) {
        await _controller.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
      } else {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String videoPath = path.join(
          appDir.path,
          '${DateTime.now()}.mp4',
        );

        XFile video = await _controller.stopVideoRecording();
        File videoFile = File(video.path);
        File savedVideo = await videoFile.copy(videoPath);

        setState(() {
          _isRecording = false;
        });

        Navigator.pop(context, savedVideo);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Record a Video')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(_isRecording ? Icons.stop : Icons.videocam),
        onPressed: _recordVideo,
      ),
    );
  }
}
