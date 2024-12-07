import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/predict/detect/detected_object.dart';

/// A painter used to draw the detected objects on the screen.

class ObjectDetectorPainter extends CustomPainter {
  /// Creates a [ObjectDetectorPainter].
  ObjectDetectorPainter(
    this._detectionResults, [
    this._colors,
    this._strokeWidth = 2.5,
  ]);

  /// Estimate distance from camera to object
  double estimateDistance({
    required int screenHeightPx,
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

  final List<DetectedObject> _detectionResults;
  final List<Color>? _colors;
  final double _strokeWidth;
  final double focalLength = 2.6; //Average focal length for mobile devices

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    final colors = _colors ?? Colors.primaries;

    //Screen of canvas boxes in pixels
    const screenHeight = 800;

    for (final detectedObject in _detectionResults) {
      final left = detectedObject.boundingBox.left;
      final top = detectedObject.boundingBox.top;
      final right = detectedObject.boundingBox.right;
      final bottom = detectedObject.boundingBox.bottom;
      final width = detectedObject.boundingBox.width;
      final height = detectedObject.boundingBox.height;
      final expectedSize = int.parse(detectedObject.size);

      final estimatedDistance = estimateDistance(
        screenHeightPx: screenHeight,
        boundingBoxSizePx: height,
        expectedObjectSizeCm: expectedSize,
        focalLengthCm: focalLength,
      );

      if (left.isNaN ||
          top.isNaN ||
          right.isNaN ||
          bottom.isNaN ||
          width.isNaN ||
          height.isNaN ) return;

      final opacity = (detectedObject.confidence - 0.2) / (1.0 - 0.2) * 0.9;

      //
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
        ..addText(' ${detectedObject.label} '
            '${(detectedObject.confidence * 100).toStringAsFixed(1)} '
            '${estimatedDistance.toStringAsFixed(1)}cm \n')
        ..pop();
      canvas.drawParagraph(
        builder.build()..layout(ui.ParagraphConstraints(width: right - left)),
        Offset(max(0, left), max(0, top)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
