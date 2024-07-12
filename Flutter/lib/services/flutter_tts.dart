import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  List<Map> _voices = [];
  Map? _currentVoice;

  TTSService() {
    _initTTS();
  }

  void _initTTS() async {
    _voices = List<Map>.from(await _flutterTts.getVoices);
    _voices = _voices.where((voice) => voice["name"].contains("en")).toList();
    if (_voices.isNotEmpty) {
      _currentVoice = _voices.first;
      setVoice(_currentVoice!);
    }
  }

  void setVoice(Map voice) {
    _flutterTts.setVoice({"name": voice["name"], "locale": voice["locale"]});
  }

  void speak(String text) {
    _flutterTts.speak(text);
  }

  List<Map> get voices => _voices;
  Map? get currentVoice => _currentVoice;
  set currentVoice(Map? voice) {
    _currentVoice = voice;
    if (_currentVoice != null) {
      setVoice(_currentVoice!);
    }
  }
}
