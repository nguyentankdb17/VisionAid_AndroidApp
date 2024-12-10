import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ultralytics_yolo/predict/detect/object_detector_painter.dart';

class Command {
  static final all = [describe, search];

  static const describe = 'describe';
  static const search = 'search';
}

class Utils {
  final FlutterTts _flutterTts = FlutterTts(); // Chuyển sang đối tượng không tĩnh

  // Sửa phương thức scanText thành không tĩnh và truyền painter vào
  Future<void> scanText(String rawText, ObjectDetectorPainter painter) async {
    final text = rawText.toLowerCase();
    Map<String, String> objectsInfor = painter.detectedObjects;

    if (text.contains(Command.describe)) {
      if (objectsInfor.isNotEmpty) {
        // Lặp qua các key-value trong Map
        objectsInfor.forEach((key, value) {
          // Đọc giá trị (cột 2) của mỗi đối tượng
          _flutterTts.speak(value); // Hoặc có thể làm gì đó với giá trị này
        });
      } else {
        _flutterTts.speak("I see nothing");
      }
    } else if (text.contains(Command.search)) {
      final object = _getTextAfterCommand(text: text, command: Command.search);
      // Kiểm tra xem objectToFind có trong Map không
      if (objectsInfor.containsKey(object)) {
        // Nếu có, lấy giá trị tương ứng và đọc
        String info = objectsInfor[object]!;
        _flutterTts.speak(info);
      } else {
        // Nếu không tìm thấy, phát một thông báo khác
        _flutterTts.speak(object + " not found");
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
