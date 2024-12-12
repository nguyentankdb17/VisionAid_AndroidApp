import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ultralytics_yolo/predict/detect/detected_object.dart';

/// A painter used to draw the detected objects on the screen.

class ObjectDetectorPainter extends CustomPainter {

  final FlutterTts _flutterTts = FlutterTts();
  /// Creates a [ObjectDetectorPainter].
  ObjectDetectorPainter(
      this._detectionResults, [
        this._colors,
        this._strokeWidth = 2.5,
      ]);

  /// Estimate distance from camera to object
  double estimateDistance({
    required double screenHeightPx,
    required double boundingBoxSizePx,
    required int expectedObjectSizeCm,
    required double focalLengthCm,
    double sensorHeightMm = 4.55, // Default 1/2.3 inch
  }) {
    // Convert focal length to pixel
    final focalLengthPx = focalLengthCm * (screenHeightPx / sensorHeightMm);
    // Estimate the distance
    final distanceCm = (expectedObjectSizeCm * focalLengthPx) / boundingBoxSizePx;
    return distanceCm;
  }

  /// Find the relative position on the screen
  String determinePosition(double objectX, double objectWidth, double objectLeft, double objectRight, double screenWidth) {
    final screenWidthHalf = screenWidth / 2;

    // if the whole object is on the left
    if (objectRight < screenWidthHalf) {
      return 'left';
    }

    // If the whole object is on the right
    if (objectLeft > screenWidthHalf) {
      return 'right';
    }

    // If object occupies more than half of screen width
    if (objectWidth > 0.5 * screenWidth) {
      return 'center';
    }

    // Compare the center of bounding box to center of screen
    if (objectX < screenWidthHalf) {
      return 'left';
    } else if (objectX > screenWidthHalf) {
      return 'right';
    } else {
      return 'center';
    }
  }

  final List<DetectedObject> _detectionResults;
  final List<Color>? _colors;
  final double _strokeWidth;

  /// Map để lưu trữ các đối tượng đã phát hiện, dùng tên hoặc id của đối tượng làm key
  final Map<String, String> _previousDetectedObjects = {};

  /// Getter trả về Map chứa các đối tượng đã phát hiện
  Map<String, String> get detectedObjects => _previousDetectedObjects;

  /// Set để lưu các đối tượng đã được cảnh báo
  final List<String> _warnedObjects = [];

  /// Average focal length for mobile devices
  final double focalLength = 2.6;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    final colors = _colors ?? Colors.primaries;

    //Screen of canvas boxes in pixels
    final screenHeight = size.height ;

    String allDetectedText = ''; // Chuỗi để lưu trữ tất cả mô tả

    for (final detectedObject in _detectionResults) {
      final left = detectedObject.boundingBox.left;
      final top = detectedObject.boundingBox.top;
      final right = detectedObject.boundingBox.right;
      final bottom = detectedObject.boundingBox.bottom;
      final width = detectedObject.boundingBox.width;
      final height = detectedObject.boundingBox.height;
      final expectedSize = int.parse(detectedObject.size);

      if (left.isNaN ||
          top.isNaN ||
          right.isNaN ||
          bottom.isNaN ||
          width.isNaN ||
          height.isNaN ) return;

      final estimatedDistance = estimateDistance(
        screenHeightPx: screenHeight,
        boundingBoxSizePx: height,
        expectedObjectSizeCm: expectedSize,
        focalLengthCm: focalLength,
      );

      final centerX = (left + right) / 2;

      final opacity = (detectedObject.confidence - 0.2) / (1.0 - 0.2) * 0.9;

      // DRAW
      // Rect
      final index = detectedObject.index % colors.length;
      final color = colors[index];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, width, height),
          const Radius.circular(8),
        ),
        borderPaint..color = color.withOpacity(opacity),
      );

      // ADD TEXT
      final objectInfo = ' ${detectedObject.label} '
          '${(detectedObject.confidence * 100).toStringAsFixed(1)} '
          '${determinePosition(centerX, width, left, right, size.width)} '
          '${estimatedDistance.toStringAsFixed(1)}cm \n';

      // Đọc nội dung qua Text-to-Speech
      //_flutterTts.speak(text);

      // if (estimatedDistance < 30) {
      //   // Tạo một key duy nhất cho mỗi đối tượng
      //   final objectKey = detectedObject.label;
      //
      //   // Chỉ cảnh báo nếu đối tượng chưa được cảnh báo
      //   if (!_warnedObjects.contains(objectKey)) {
      //     _warnedObjects.add(objectKey); // Đánh dấu đã cảnh báo
      //     _flutterTts.speak("Warning: ${detectedObject.label} is too close! It's only ${estimatedDistance.toStringAsFixed(1)}} centimeters away from you");
      //   }
      // }
      // Kiểm tra xem đối tượng này đã được phát hiện trước đó chưa
      if (_previousDetectedObjects.containsKey(detectedObject.label)) {
        // Nếu đã tồn tại và thông tin thay đổi, thì cập nhật lại
        if (_previousDetectedObjects[detectedObject.label] != objectInfo) {
          // Cập nhật thông tin mới
          _previousDetectedObjects[detectedObject.label] = objectInfo;
          // Đọc lại thông tin mới
          //_flutterTts.speak(objectInfo);
        }
      } else {
        // Nếu đối tượng chưa được phát hiện trước đó, thêm vào map và đọc thông tin
        _previousDetectedObjects[detectedObject.label] = objectInfo;
        //_flutterTts.speak(objectInfo);
      }

      // Gom tất cả các mô tả vào chuỗi
      allDetectedText += objectInfo;

      // Label
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: 16,
          textDirection: TextDirection.ltr,
        ),
      )
        ..pushStyle(
          ui.TextStyle(
            color: Colors.white,
            background: Paint()..color = color.withOpacity(opacity),
          ),
        )
        ..addText(objectInfo)
        ..pop();
      canvas.drawParagraph(
        builder.build()..layout(ui.ParagraphConstraints(width: right - left)),
        Offset(max(0, left), max(0, top)),
      );
    }
    // Đọc tất cả các đối tượng một lần
    if (allDetectedText.isNotEmpty) {
      //_flutterTts.speak(allDetectedText);
      //print(allDetectedText);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}