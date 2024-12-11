import 'package:flutter_tts/flutter_tts.dart';

class Command {
  static final all = [describe, search];

  static const describe = 'describe';
  static const search = 'find the';
}

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
    // Map<String, String> objectsInfor = painter.detectedObjects;

    if (text.contains(Command.describe)) {
      // if (objectsInfor.isNotEmpty) {
      //   // Lặp qua các key-value trong Map
      //   objectsInfor.forEach((key, value) {
      //     // Đọc giá trị (cột 2) của mỗi đối tượng
      //     flutterTts.speak(value); // Hoặc có thể làm gì đó với giá trị này
      //   });
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
          await flutterTts.speak('$object is in front of you, about $distance centimeters away from you');
        } else {
          await flutterTts.speak('$object is on your $position hand, about $distance centimeters away from you ');
        }
      } else {
        await flutterTts.speak('$object not found');
      }
      // Kiểm tra xem objectToFind có trong Map không
      // if (objectsInfor.containsKey(object)) {
      //   // Nếu có, lấy giá trị tương ứng và đọc
      //   String info = objectsInfor[object]!;
      //   flutterTts.speak(info);
      // } else {
      //   // Nếu không tìm thấy, phát một thông báo khác
      //   flutterTts.speak(object + " not found");
      // }
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
