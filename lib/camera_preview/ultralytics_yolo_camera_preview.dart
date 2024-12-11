import 'dart:collection';
import 'dart:math';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultralytics_yolo/speech/speech_to_text_api.dart';
import 'package:ultralytics_yolo/speech/utils.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/ultralytics_yolo_platform_interface.dart';

const String _viewType = 'ultralytics_yolo_camera_preview';

/// A widget that displays the camera preview and run inference on the frames
/// using a Ultralytics YOLO model.
class UltralyticsYoloCameraPreview extends StatefulWidget {
  /// Constructor to create a [UltralyticsYoloCameraPreview].
  const UltralyticsYoloCameraPreview({
    required this.predictor,
    required this.controller,
    required this.onCameraCreated,
    this.boundingBoxesColorList = const [Colors.lightGreenAccent],
    // this.classificationOverlay,
    this.loadingPlaceholder,
    super.key,
  });

  /// The predictor used to run inference on the camera frames.
  final Predictor? predictor;

  /// The list of colors used to draw the bounding boxes.
  final List<Color> boundingBoxesColorList;

  // /// The classification overlay widget.
  // final BaseClassificationOverlay? classificationOverlay;

  /// The controller for the camera preview.
  final UltralyticsYoloCameraController controller;

  /// The callback invoked when the camera is created.
  final VoidCallback onCameraCreated;

  /// The placeholder widget displayed while the predictor is loading.
  final Widget? loadingPlaceholder;

  /// The voice widget.

  @override
  State<UltralyticsYoloCameraPreview> createState() =>
      _UltralyticsYoloCameraPreviewState();
}

class _UltralyticsYoloCameraPreviewState
    extends State<UltralyticsYoloCameraPreview> {
  final _ultralyticsYoloPlatform = UltralyticsYoloPlatform.instance;

  double _currentZoomFactor = 1;

  final double _zoomSensitivity = 0.05;

  final double _minZoomLevel = 1;

  final double _maxZoomLevel = 5;

  List<DetectedObject> _resultDetections = [];

  //Screen of canvas boxes in pixels
  double _screenHeight = 0;

  /// Map để lưu trữ các đối tượng đã phát hiện, dùng tên hoặc id của đối tượng làm key
  final Map<String, List<String>> _previousDetectedObjects = {};

  // Getter trả về Map chứa các đối tượng đã phát hiện
  Map<String, List<String>> get detectedObjects => _previousDetectedObjects;

  /// Average focal length for mobile devices
  final double focalLength = 2.6;

  /// Find the relative position on the screen
  String determinePosition(double objectX, double objectWidth, double screenWidth) {
    final screenWidthHalf = screenWidth / 2;
    if (objectWidth > 0.5 * screenWidth) {
      return 'center';
    }
    if (objectX < screenWidthHalf) {
      return 'left';
    } else if (objectX > screenWidthHalf) {
      return 'right';
    } else {
      return 'center';
    }
  }

  bool _isListening = false;

  String _text = 'Press the button and start speaking';


  void _onPlatformViewCreated(_) {
    widget.onCameraCreated();
    _ultralyticsYoloPlatform.setConfidenceThreshold(0.4);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UltralyticsYoloCameraValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        return Stack(
          children: [
            // Camera preview
            () {
              final creationParams = <String, dynamic>{
                'lensDirection': widget.controller.value.lensDirection,
                'format': widget.predictor?.model.format.name,
              };

              switch (defaultTargetPlatform) {
                case TargetPlatform.android:
                  return AndroidView(
                    viewType: _viewType,
                    onPlatformViewCreated: _onPlatformViewCreated,
                    creationParams: creationParams,
                    creationParamsCodec: const StandardMessageCodec(),
                  );
                case TargetPlatform.iOS:
                  return UiKitView(
                    viewType: _viewType,
                    creationParams: creationParams,
                    onPlatformViewCreated: _onPlatformViewCreated,
                    creationParamsCodec: const StandardMessageCodec(),
                  );
                case TargetPlatform.fuchsia ||
                      TargetPlatform.linux ||
                      TargetPlatform.windows ||
                      TargetPlatform.macOS:
                  return Container();
              }
            }(),

            // Results
            () {
              if (widget.predictor == null) {
                return widget.loadingPlaceholder ?? Container();
              }

              switch (widget.predictor.runtimeType) {
                case ObjectDetector:
                   return StreamBuilder(
                    stream: (widget.predictor! as ObjectDetector)
                        .detectionResultStream,
                    builder: (
                        BuildContext context,
                        AsyncSnapshot<List<DetectedObject?>?> snapshot,
                        ) {
                      if (snapshot.data == null) return Container();

                      _resultDetections = snapshot.data! as List<DetectedObject>;
                      _screenHeight = MediaQuery.of(context).size.height;

                      return SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: CustomPaint(
                          painter: ObjectDetectorPainter(
                            snapshot.data! as List<DetectedObject>,
                            widget.boundingBoxesColorList,
                            widget.controller.value.strokeWidth,
                          ),
                        ),
                      );
                    },
                  );
                // case ImageClassifier:
                //   return widget.classificationOverlay ??
                //       StreamBuilder(
                //         stream: (widget.predictor! as ImageClassifier)
                //             .classificationResultStream,
                //         builder: (context, snapshot) {
                //           final classificationResults = snapshot.data;
                //
                //           if (classificationResults == null ||
                //               classificationResults.isEmpty) {
                //             return Container();
                //           }
                //
                //           return ClassificationResultOverlay(
                //             classificationResults: classificationResults,
                //           );
                //         },
                //       );
                default:
                  return Container();
              }
            }(),

            // Zoom detector
            GestureDetector(
              onScaleUpdate: (details) {
                if (details.pointerCount == 2) {
                  // Calculate the new zoom factor
                  var newZoomFactor = _currentZoomFactor * details.scale;

                  // Adjust the sensitivity for zoom out
                  if (newZoomFactor < _currentZoomFactor) {
                    newZoomFactor = _currentZoomFactor -
                        (_zoomSensitivity *
                            (_currentZoomFactor - newZoomFactor));
                  } else {
                    newZoomFactor = _currentZoomFactor +
                        (_zoomSensitivity *
                            (newZoomFactor - _currentZoomFactor));
                  }

                  // Limit the zoom factor to a range between
                  // _minZoomLevel and _maxZoomLevel
                  final clampedZoomFactor =
                      max(_minZoomLevel, min(_maxZoomLevel, newZoomFactor));

                  // Update the zoom factor
                  _ultralyticsYoloPlatform.setZoomRatio(clampedZoomFactor);

                  // Update the current zoom factor for the next update
                  _currentZoomFactor = clampedZoomFactor;
                }
              },
              child: Container(
                height: double.infinity,
                width: double.infinity,
                color: Colors.transparent,
                child: const Center(child: Text('')),
              ),
            ),
            () {
              final estimator = DistanceEstimator();

              for (final detectedObject in _resultDetections) {
                final left = detectedObject.boundingBox.left;
                final right = detectedObject.boundingBox.right;
                final width = detectedObject.boundingBox.width;
                final height = detectedObject.boundingBox.height;
                final expectedSize = int.parse(detectedObject.size);
                final centerX = (left + right) / 2;

                final estimatedDistance = estimator.estimateDistance(
                  screenHeightPx: _screenHeight,
                  boundingBoxSizePx: height,
                  expectedObjectSizeCm: expectedSize,
                  focalLengthCm: focalLength,
                );

                final objectInfo = '${detectedObject.label}'
                    ' and ${estimatedDistance.toStringAsFixed(0)}';

                // // Kiểm tra xem đối tượng này đã được phát hiện trước đó chưa
                // if (_previousDetectedObjects.containsKey(detectedObject)) {
                //   // Nếu đã tồn tại và thông tin thay đổi, thì cập nhật lại
                //   if (_previousDetectedObjects[detectedObject.label] != objectInfo) {
                //     // Cập nhật thông tin mới
                //     _previousDetectedObjects[detectedObject.label] = objectInfo;
                //     // Đọc lại thông tin mới
                //     //_flutterTts.speak(objectInfo);
                //   }
                // } else {
                //   // Nếu đối tượng chưa được phát hiện trước đó, thêm vào map và đọc thông tin
                //   _previousDetectedObjects[detectedObject.label] = objectInfo;
                //   //_flutterTts.speak(objectInfo);
                // }

                // Gom tất cả các mô tả vào chuỗi
                detectedObjects[detectedObject.label] = [estimatedDistance.toStringAsFixed(0), determinePosition(centerX, width, MediaQuery.of(context).size.width)];
              }

              Utils.scanText(_text, detectedObjects);
              return speech();
            }
            (),
          ],
        );
      });
  }
  Widget speech() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
            bottom: 10,
            child: Column(
              children: [
                AvatarGlow(
                    animate: _isListening,
                    glowColor: Theme.of(context).primaryColor,
                    duration: const Duration(seconds: 3),
                    repeat: _isListening,
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: FittedBox(
                        child: FloatingActionButton(
                          shape: const CircleBorder(),
                          onPressed: toggleRecording,
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            size: 50,
                          ),
                        ),
                      ),
                    )
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                  height: 200,
                  child: Text(
                    _text,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ],
            )
        )
      ],
    );
  }

  Future<void> toggleRecording() => SpeechToTextApi.toggleRecording(
      onResult: (text) {
        setState(() {
          _text = text;
        });
      },
      onListening: (isListening) {
        setState((){
          _isListening = isListening;
          if (isListening) {
            _text = '';
          }
        });
      });
}

/// Estimate distance from camera to object
class DistanceEstimator {
  /// Result
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
}
