import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:developer' as developer;

class Speech extends StatefulWidget {
  const Speech({super.key});

  @override
  State<Speech> createState() => _SpeechState();
}

class _SpeechState extends State<Speech> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = "${result.recognizedWords}";
    });
    developer.log("Words spoken: $_wordsSpoken");
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Speech Recognition"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _speechToText.isListening
                ? "Listening..."
                : _speechEnabled
                    ? "Tap the microphone to start listening..."
                    : "Speech not available",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            _wordsSpoken,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _speechToText.isListening ? _stopListening : _startListening,
          child: Text(
            _speechToText.isNotListening ? "Start" : "Stop",
            style: const TextStyle(color: Colors.red),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Close"),
        ),
      ],
    );
  }
}
