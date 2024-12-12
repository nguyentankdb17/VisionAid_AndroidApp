import 'package:flutter_tts/flutter_tts.dart';

class Command {
  static final all = [describe, search];

  static const describe = 'describe';
  static const search = 'find the';
}

/// Set up the flutter tts
class TTS {
  static FlutterTts get flutterTts {
    final tts = FlutterTts();
    tts..setSpeechRate(0.3)
    ..awaitSpeakCompletion(true);
    return tts;
  }
}

class Utils {
  /// Text to speech
  static final FlutterTts flutterTts = TTS.flutterTts;// Chuyển sang đối tượng không tĩnh

  static Future<void> scanText(String rawText, Map<String, List<String>> objects) async {
    final text = rawText.toLowerCase();

    if (text.contains(Command.describe)) {
      if (objects.isNotEmpty) {
        await flutterTts.speak('There are ');
        for (final key in objects.keys) {
          await flutterTts.speak(key);
        }
        await flutterTts.speak('in front of you');
      }
      else {
        await flutterTts.speak("I can't detect anything in front of you");
      }
    } else if (text.contains(Command.search)) {
      final object = _getTextAfterCommand(text: text, command: Command.search);
      if (objects.containsKey(object)) {
        final distance = objects[object]![0];
        final position = objects[object]![1];
        if (position=='center') {
          await flutterTts.speak('$object is right ahead, about $distance centimeters away from you');
        } else {
          await flutterTts.speak('$object is on your $position hand, about $distance centimeters away from you ');
        }
      } else {
        await flutterTts.speak('$object not found');
      }
    }
  }

  static String _getTextAfterCommand({
    required String text,
    required String command,
  }) {
    final indexCommand = text.indexOf(command);
    final indexAfter = indexCommand + command.length;

    return text.substring(indexAfter).trim();
  }
}
