import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:developer' as developer;

class Speech extends StatefulWidget {
  final void Function(String)? onSpeechResult;

  const Speech({super.key, this.onSpeechResult});

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
    if (result.finalResult) {
      setState(() {
        _wordsSpoken = result.recognizedWords;
      });
      developer.log("Words spoken: $_wordsSpoken");

      if (widget.onSpeechResult != null) {
        widget.onSpeechResult!(_wordsSpoken);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(24), // Adjust the padding for the desired size
        ),
        onPressed: () {
          if (_speechToText.isListening) {
            _stopListening();
          } else {
            _startListening();
          }
        },
        child: Icon(
          _speechToText.isListening ? Icons.mic : Icons.mic_off,
          size: 96, // Adjust the icon size if needed
          color: Colors.white,
        ),
      ),
    );
  }
}