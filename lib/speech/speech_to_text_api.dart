import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextApi {
  static final _speechToText = SpeechToText();

  static Future<bool> toggleRecording({
    required Function(String text) onResult,
    required ValueChanged<bool> onListening,
  }) async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      return true;
    }

    final isAvailable = await _speechToText.initialize(
      onStatus: (status) => onListening(_speechToText.isListening),
      onError: (e) => print('Error: $e'),
    );

    if (isAvailable) {
      await _speechToText.listen(onResult: (value) => onResult(value.recognizedWords));
    }

    return isAvailable;
  }
}