import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/yolo_model.dart';
import 'package:visionaid/text_to_speech.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:visionaid/globals.dart' as globals;
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = UltralyticsYoloCameraController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String wordsSpoken = "";
  double confidenceLevel = 0;
  bool _isModeActive = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech(); // Gọi hàm bất đồng bộ
  }

  Future<void> _initializeSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {}); // Cập nhật trạng thái nếu cần
  }

  Widget _voiceButton(BuildContext context) => Stack(
    children: [
      // Nút mic được định vị chính xác
      Positioned(
        bottom: 10, // Cách cạnh dưới 50px
        left: MediaQuery.of(context).size.width / 2 - 75, // Căn giữa theo chiều ngang (75 = 150/2)
        child: RawMaterialButton(
          onPressed: () {
            _speechToText.isListening ? stopListening() : startListening();
            if (_isModeActive) {
              globals.targetSearch = "";
            }
            setState(() {
              _isModeActive = !_isModeActive;
            });
          },
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(75),
                  ),
                ),
                Icon(
                  _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
                  size: 80,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  void extractTargetObject(String spokenText) {
    String tmpText = spokenText.toLowerCase();
    String cleanedText = tmpText.replaceAll("tìm", "").trim();
    List<String> words = cleanedText.split(" ");
    setState(() {
      globals.targetSearch = words.join("");
    });
  }

  void onSpeechResult(result){
    setState(() {
      wordsSpoken = _speechToText.isListening ? "${result.recognizedWords}" : "" ;
      confidenceLevel = result.confidence;
    });
    extractTargetObject(wordsSpoken);
  }

  void startListening() async{
    await _speechToText.listen(onResult: onSpeechResult);
    await speak("Listening");
    setState(() {
      confidenceLevel = 0;
    });
  }

  void stopListening() async{
    await _speechToText.stop();
    await speak("Stop listening, tap the microphone to start listening");
    setState(() {
      // globals.targetSearch = "";
      wordsSpoken = "";
    });
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder<bool>(
          future: _checkPermissions(),
          builder: (context, snapshot) {
            final allPermissionsGranted = snapshot.data ?? false;

            return !allPermissionsGranted
                ? const Center(
              child: Text("Error requesting permissions"),
            )
                : FutureBuilder<ObjectDetector>(
              future: _initObjectDetectorWithLocalModel(),
              builder: (context, snapshot) {
                final predictor = snapshot.data;

                return predictor == null
                    ? Container()
                    : Stack(
                  children: [
                    UltralyticsYoloCameraPreview(
                      controller: controller,
                      predictor: predictor,
                      onCameraCreated: () {
                        predictor.loadModel(useGpu: true);
                      },
                    ),
                    _voiceButton(context),
                    // StreamBuilder<double?>(
                    //   stream: predictor.inferenceTime,
                    //   builder: (context, snapshot) {
                    //     final inferenceTime = snapshot.data;
                    //
                    //     return StreamBuilder<double?>(
                    //       stream: predictor.fpsRate,
                    //       builder: (context, snapshot) {
                    //         final fpsRate = snapshot.data;
                    //
                    //         return Times(
                    //           inferenceTime: inferenceTime,
                    //           fpsRate: fpsRate,
                    //         );
                    //       },
                    //     );
                    //   },
                    // ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<ObjectDetector> _initObjectDetectorWithLocalModel() async {
    // final modelPath = await _copy('assets/yolov8n.mlmodel');
    // final model = LocalYoloModel(
    //   id: '',
    //   task: Task.detect,
    //   format: Format.coreml,
    //   modelPath: modelPath,
    // );
    final modelPath = await _copy('assets/yolov8n_int8.tflite');
    final metadataPath = await _copy('assets/metadata.yaml');
    final model = LocalYoloModel(
      id: '',
      task: Task.detect,
      format: Format.tflite,
      modelPath: modelPath,
      metadataPath: metadataPath,
    );
    return ObjectDetector(model: model);
  }

  Future<ImageClassifier> _initImageClassifierWithLocalModel() async {
    final modelPath = await _copy('assets/yolov8n-cls.mlmodel');
    final model = LocalYoloModel(
      id: '',
      task: Task.classify,
      format: Format.coreml,
      modelPath: modelPath,
    );

    // final modelPath = await _copy('assets/yolov8n-cls.bin');
    // final paramPath = await _copy('assets/yolov8n-cls.param');
    // final metadataPath = await _copy('assets/metadata-cls.yaml');
    // final model = LocalYoloModel(
    //   id: '',
    //   task: Task.classify,
    //   modelPath: modelPath,
    //   paramPath: paramPath,
    //   metadataPath: metadataPath,
    // );

    return ImageClassifier(model: model);
  }

  Future<String> _copy(String assetPath) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(dirname(path)).create(recursive: true);
    final file = io.File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  Future<bool> _checkPermissions() async {
    List<Permission> permissions = [];

    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) permissions.add(Permission.camera);

    var storageStatus = await Permission.photos.status;
    if (!storageStatus.isGranted) permissions.add(Permission.photos);

    if (permissions.isEmpty) {
      return true;
    } else {
      try {
        Map<Permission, PermissionStatus> statuses = await permissions.request();
        return statuses.values.every((status) => status == PermissionStatus.granted);
      } on Exception catch (_) {
        return false;
      }
    }
  }
}

// class Times extends StatelessWidget {
//   const Times({
//     super.key,
//     required this.inferenceTime,
//     required this.fpsRate,
//   });
//
//   final double? inferenceTime;
//   final double? fpsRate;
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Align(
//         alignment: Alignment.bottomCenter,
//         child: Container(
//             margin: const EdgeInsets.all(20),
//             padding: const EdgeInsets.all(20),
//             decoration: const BoxDecoration(
//               borderRadius: BorderRadius.all(Radius.circular(10)),
//               color: Colors.black54,
//             ),
//             child: Text(
//               '${(inferenceTime ?? 0).toStringAsFixed(1)} ms  -  ${(fpsRate ?? 0).toStringAsFixed(1)} FPS',
//               style: const TextStyle(color: Colors.white70),
//             )),
//       ),
//     );
//   }
// }
