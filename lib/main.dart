import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Voice',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primarySwatch: Colors.red,
            visualDensity: VisualDensity.adaptivePlatformDensity),
        home: SpeechScreen());
  }
}

class SpeechScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SpeechScreenState();
  }
}

class SpeechScreenState extends State<SpeechScreen> {
  final FlutterTts flutterTts = FlutterTts();

  final Map<String, HighlightedWord> _highlights = {
    'flutter': HighlightedWord(
      onTap: () => print('flutter'),
      textStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
    ),
    'voice': HighlightedWord(
      onTap: () => print('voice'),
      textStyle: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
    'subscribe': HighlightedWord(
      onTap: () => print('subscribe'),
      textStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
    ),
    'like': HighlightedWord(
      onTap: () => print('like'),
      textStyle: const TextStyle(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
      ),
    ),
    'comment': HighlightedWord(
      onTap: () => print('comment'),
      textStyle: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
  };
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _text = 'Olá, o que você deseja?';
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _start_interaction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Visibility(
          visible: !_isSpeaking,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              AvatarGlow(
                animate: _isListening,
                glowColor: Theme.of(context).primaryColor,
                endRadius: 75.0,
                duration: const Duration(milliseconds: 2000),
                repeat: true,
                child: FloatingActionButton(
                  onPressed: _listen,
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none),
                ),
              ),
              AvatarGlow(
                  child: FloatingActionButton(
                    onPressed: _play,
                    child: Icon(Icons.play_arrow),
                  ),
                  endRadius: 75.0)
            ],
          )),
      body: SingleChildScrollView(
        reverse: true,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
            child: TextHighlight(
              text: _text,
              words: _highlights,
              textStyle: const TextStyle(
                  fontSize: 28.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w400),
            ),
          ),
          Visibility(
            visible: _isSpeaking,
            child: SpinKitWave(
              color: Theme.of(context).primaryColor,
              size: 50.0,
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _start_interaction() async {
    await Future.delayed(Duration(seconds: 1));
    await flutterTts.setLanguage('pt-BR');
    await flutterTts.speak('Olá, o que você deseja?');
    await Future.delayed(Duration(seconds: 3));
    _listen();
  }

  void _listen() async {
    print(_isListening);
    if (!_isListening) {
      bool available = await _speech.initialize(
          onStatus: (val) => print('onStatus: $val'),
          onError: (val) {
            print('onError: ${val.errorMsg}');
            if (val.errorMsg == 'error_speech_timeout' ||
                val.errorMsg == 'error_no_match') {
              _start_interaction();
            }
          });
      if (available) {
        //setState(() => _isListening = true);
        _speech.listen(
          listenFor: Duration(minutes: 3),
          onResult: (val) async => {
            setState(() {
              _text = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                _confidence = val.confidence;
              }
            }),
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _play() async {
    setState(() {
      _isSpeaking = true;
    });

    await flutterTts.setLanguage('pt-BR');
    await flutterTts.speak(_text);

    setState(() {
      _isSpeaking = false;
    });
  }
}
