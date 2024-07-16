import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image/Video Upload Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Simulate an image upload failure or incorrect video type
            bool imageUploadSuccess = false; // Change this based on your logic
            bool videoTypeCorrect = false; // Change this based on your logic

            if (!imageUploadSuccess) {
              DialogBox.showErrorDialog(context, 'Image Upload Failed', 'The image could not be uploaded. Please try again.');
            } else if (!videoTypeCorrect) {
              DialogBox.showErrorDialog(context, 'Incorrect Video Type', 'The selected video type is not supported.');
            } else {
              // Proceed with the normal flow
            }
          },
          child: const Text('Upload Image/Video'),
        ),
      ),
    );
  }
}

class DialogBox {
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
