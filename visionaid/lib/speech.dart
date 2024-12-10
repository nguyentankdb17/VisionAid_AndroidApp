import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:visionaid/speech_to_text_api.dart';


enum TtsState { playing, stopped, paused, continued }

class Speech extends StatefulWidget {
  const Speech({super.key});
  @override
  State<Speech> createState() {
    return _SpeechState();
  }
}

class _SpeechState extends State<Speech> {
  late FlutterTts flutterTts;
  // late SpeechToText _speechToText;
  String? language;
  String? engine;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;

  ///
  // bool _speechEnabled = false;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;

  TtsState ttsState = TtsState.stopped;

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;

  @override
  initState() {
    super.initState();
    initTts();
    // initStt();
  }

  dynamic initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();
    _getDefaultEngine();
    _getDefaultVoice();

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  // void initStt() async {
  //   _speechToText = SpeechToText();
  //   // _speechEnabled = await _speechToText.initialize();
  // }
  Future<dynamic> _getLanguages() async => await flutterTts.getLanguages;

  Future<dynamic> _getEngines() async => await flutterTts.getEngines;

  ///
  // void startListening() async {
  //   microphoneIcon = Icons.mic;
  //   await flutterTts.speak("Listening.");
  //   await _speechToText.listen(
  //       onResult: onSpeechResult,
  //       listenFor: const Duration(seconds: 10),
  //       pauseFor: const Duration(seconds: 3));
  //   setState(() {
  //     confidenceLevel = 0;
  //   });
  //   if (_speechToText.isListening == false) {
  //     microphoneIcon = Icons.mic_off;
  //     await flutterTts.speak("Stop.");
  //   }
  // }

  // void stopListening() async {
  //   microphoneIcon = Icons.mic_off;
  //   await _speechToText.stop();
  //   await flutterTts.speak("Stop.");
  //   setState(() {
  //
  //     wordsSpoken = "";
  //   });
  // }

  void extractTargetObject(String spokenText) {
    String tmpText = spokenText.toLowerCase();
    String cleanedText = tmpText.replaceAll("tìm", "").trim();
    List<String> words = cleanedText.split(" ");
    setState(() {

    });
  }

  // void onSpeechResult(result){
  //   setState(() {
  //     wordsSpoken = _speechToText.isListening ? "${result.recognizedWords}" : "" ;
  //     confidenceLevel = result.confidence;
  //   });
  //   extractTargetObject(wordsSpoken);
  // }


  Future<void> _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future<void> _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future<void> _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(
      List<dynamic> engines) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

  void changedEnginesDropDownItem(String? selectedEngine) async {
    await flutterTts.setEngine(selectedEngine!);
    language = null;
    setState(() {
      engine = selectedEngine;
    });
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
      List<dynamic> languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

  void changedLanguageDropDownItem(String? selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language!);

      flutterTts
          .isLanguageInstalled(language!)
          .then((value) => isCurrentLanguageInstalled = (value as bool));

    });
  }

  @override
  // Widget build(BuildContext context) {
  //   return Stack(
  //     alignment: Alignment.center,
  //     children: [
  //       Positioned(
  //         bottom: 10,
  //           child: ElevatedButton(
  //               onPressed: () {
  //                 _speechToText.isNotListening ? startListening() : stopListening();
  //               },
  //               style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.white,
  //                   fixedSize: const Size(150, 150),
  //                   shape: const CircleBorder(eccentricity: 1)
  //               ),
  //               child: Icon(
  //                 microphoneIcon,
  //                 color: Colors.red.shade400,
  //                 size: 100,
  //               )
  //           )
  //       )
  //     ],
  //   );
  // }
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: 10,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text('Confidence: ${(_confidence * 100.0).toStringAsFixed(1) + _isListening.toString()}%'),
                AvatarGlow(
                    animate: _isListening,
                    glowColor: Theme.of(context).primaryColor,
                    duration: const Duration(seconds: 2),
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

  // void _listen() async {
  //   if (!_isListening) {
  //     bool available = await _speechToText.initialize(
  //       onStatus: (val) => print('onStatus: $val'),
  //       onError: (val) => print('onError: $val'),
  //     );
  //     if (available) {
  //       setState(() => _isListening = true);
  //       _speechToText.listen(
  //         onResult: (val) => setState(() {
  //           _text = val.recognizedWords;
  //           if (val.hasConfidenceRating && val.confidence > 0) {
  //             _confidence = val.confidence;
  //           }
  //         }),
  //       );
  //     } else {
  //       setState(() {
  //         _isListening = false;
  //       });
  //     }
  //   } else {
  //     setState(() => _isListening = false);
  //     _speechToText.stop();
  //   }
  // }

  Future toggleRecording() => SpeechToTextApi.toggleRecording(
    onResult: (text) => setState(() => _text = text),
    onListening: (isListening) {
      setState(() => _isListening = isListening);
    });
}




