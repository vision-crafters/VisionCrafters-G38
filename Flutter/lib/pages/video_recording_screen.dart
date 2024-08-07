import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

class VideoRecordingScreen extends StatefulWidget {
  final CameraController controller;

  const VideoRecordingScreen({super.key, required this.controller});

  @override
  VideoRecordingScreenState createState() => VideoRecordingScreenState();
}

class VideoRecordingScreenState extends State<VideoRecordingScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
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
        _timer = Timer(const Duration(seconds: 10), () async {
          if (_isRecording) {
            XFile video = await _controller.stopVideoRecording();
            _saveAndReturnVideo(video);
          }
        });
      } else {
        XFile video = await _controller.stopVideoRecording();
        _timer?.cancel();
        _saveAndReturnVideo(video);
      }
    } catch (e) {
      developer.log(e.toString());
    }
  }

  Future<void> _saveAndReturnVideo(XFile video) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String newPath = path.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}.mp4',
    );

    File newFile = await File(video.path).copy(newPath);

    setState(() {
      _isRecording = false;
    });
    if(!mounted) return;
    Navigator.pop(context, newFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record a Video')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return GestureDetector(
              onDoubleTap: _recordVideo,
              child: CameraPreview(_controller),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recordVideo,
        child: Icon(_isRecording ? Icons.stop : Icons.videocam),
      ),
    );
  }
}

