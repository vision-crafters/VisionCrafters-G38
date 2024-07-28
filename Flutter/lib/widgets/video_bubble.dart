import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final File video;

  const VideoPlayerWidget({super.key, required this.video});

  @override
  VideoPlayerWidgetState createState() => VideoPlayerWidgetState();
}

class VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.video)
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(() {
      if (_controller.value.position == _controller.value.duration) {
        setState(() {
          _controller.seekTo(Duration.zero);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class VideoBubble extends StatelessWidget {
  final String video;
  final bool isMe;

  const VideoBubble({super.key, required this.video, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final videoWidth = MediaQuery.of(context).size.width * 0.7;
    final alignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Row(
      mainAxisAlignment: alignment,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: videoWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: VideoPlayerWidget(video: File(video)),
          ),
        ),
      ],
    );
  }
}
