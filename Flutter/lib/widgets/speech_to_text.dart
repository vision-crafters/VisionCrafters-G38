import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:developer' as developer;
import 'dart:async';

class Speech extends StatefulWidget {
  final void Function(String)? onSpeechResult;

  const Speech({super.key, this.onSpeechResult});

  @override
  State<Speech> createState() => _SpeechState();
}

class _SpeechState extends State<Speech> {
  final SpeechToText _speechToText = SpeechToText();
  String _wordsSpoken = "";
  bool _speechEnabled = false;
  final ValueNotifier<bool> _isListeningNotifier = ValueNotifier(false);
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    initSpeech();
    _startStatusTimer(); // Start the timer to check listening status
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _isListeningNotifier.dispose();
    super.dispose();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (_speechEnabled) {
      _startListening(); // Automatically start listening if initialization is successful
    }
  }

  void _startStatusTimer() {
    _statusTimer?.cancel(); // Cancel any previous timer
    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _isListeningNotifier.value = _speechToText.isListening;
    });
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    _isListeningNotifier.value = true;
  }

  void _stopListening() async {
    await _speechToText.stop();
    _isListeningNotifier.value = false;
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
      child: ValueListenableBuilder<bool>(
        valueListenable: _isListeningNotifier,
        builder: (context, isListening, child) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(
                  24), // Adjust the padding for the desired size
            ),
            onPressed: () {
              if (isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            },
            child: Icon(
              isListening ? Icons.mic : Icons.mic_off,
              size: 144, // Adjust the icon size if needed
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}