import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../providers/app_state.dart';
import 'package:flutterbasics/pages/camera_preview_screen.dart';
import 'package:flutterbasics/pages/video_recording_screen.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';

class MediaPicker {
  final ImagePicker _picker = ImagePicker(); // Pick image or video from gallery

  // Pick image or video from gallery
  // by taking the choice and parameters from the user
  Future<File> pickMedia(BuildContext context, AppState appState) async {
    //dialog to give the user an option
    //to select between an image or a video from the gallery
    final choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Media Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text('Image'),
                onTap: () => Navigator.pop(context, 'image'),
              ),
              ListTile(
                title: const Text('Video'),
                onTap: () => Navigator.pop(context, 'video'),
              ),
            ],
          ),
        );
      },
    );

    if (choice != null) {
      XFile? pickedFile;
      if (choice == 'image') {
        pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
          maxHeight: 1080,
          maxWidth: 1920,
        );
      } else if (choice == 'video') {
        pickedFile = await _picker.pickVideo(source: ImageSource.gallery);

        if (pickedFile != null) {
          final VideoPlayerController videoPlayerController =
              VideoPlayerController.file(File(pickedFile.path));
          await videoPlayerController.initialize();
          if (videoPlayerController.value.duration.inSeconds > 10) {
            videoPlayerController.dispose();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const AlertDialog(
                  content: Text(
                      'The selected video is longer than 10 seconds. Please choose a video of 10 seconds or less.'),
                );
              },
            );
            throw Exception(
                'The selected video is longer than 10 seconds. Please choose a video of 10 seconds or less.');
          }
          videoPlayerController.dispose();
        }
      }

      if (pickedFile != null) {
        return File(pickedFile.path);
      } else {
        developer.log("No file selected");
        throw Exception("No file selected");
      }
    } else {
      developer.log("No choice selected");
      throw Exception("No choice selected");
    }
  }


  Future<File> getImageCM(BuildContext context, AppState appState) async {
    final cameras = await availableCameras();
    final rearCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back);

    final CameraController controller = CameraController(
      rearCamera,
      ResolutionPreset.high,
    );

    final pickedFile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPreviewScreen(controller: controller),
      ),
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    throw Exception("No image captured");
  }

//function for getting a video from the Camera by taking the required parameters.
  Future<File> getVideoFile(BuildContext context, AppState appState) async {
    final cameras = await availableCameras();
    final rearCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back);

    final CameraController controller = CameraController(
      rearCamera,
      ResolutionPreset.high,
    );

    final pickedFile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoRecordingScreen(controller: controller),
      ),
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      developer.log("No video captured");
      throw Exception("No video captured");
    }
  }
}
