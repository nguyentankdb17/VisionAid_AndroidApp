import 'dart:async';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ultralytics_yolo/speech/speech_to_text_api.dart';


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
  bool _isListening = false;
  String _text = 'Press the button and start speaking';

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: 10,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
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

  Future toggleRecording() => SpeechToTextApi.toggleRecording(
    onResult: (text) => setState(() => _text = text),
    onListening: (isListening) {
      setState(() => _isListening = isListening);
    });
}




