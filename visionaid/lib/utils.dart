import 'package:flutter/material.dart';

class Command {
  static final all = [describe, search];

  static const describe = 'describe';
  static const search = 'search';
}

class Utils {
  static String scanText(String rawText) {
    final text = rawText.toLowerCase();

    if (text.contains(Command.describe)) {
      return "There is one item";
    } else if (text.contains(Command.search)) {
      final object = _getTextAfterCommand(text: text, command: Command.describe);
      double distance = 100;
      String direction = "direction";
      return "Found 1 $object in the $direction, about $distance";
    }
    return "None";
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