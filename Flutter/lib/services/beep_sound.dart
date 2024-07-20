import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:developer' as developer;

class BeepSound {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  BeepSound() {
    _init();
  }

  void _init() async {
    await _player.openPlayer();
  }

  Future<void> makeDangerAlert() async {
    try {
      final ByteData data = await rootBundle.load('assets/danger-alert.mp3');
      final buffer = data.buffer.asUint8List();
      await _player.startPlayer(
        fromDataBuffer: buffer,
        codec: Codec.mp3,
      );

      // Assuming the beep sound is 2 seconds long, we wait for 2 seconds
      await Future.delayed(const Duration(seconds: 2));

    } catch (e) {
      developer.log('Error: $e');
    }
  }

  void dispose() {
    _player.closePlayer();
  }
}
