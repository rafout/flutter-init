import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
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
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SpeechScreenState();
  }
}

class SpeechScreenState extends State<SpeechScreen>
    with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();

  final apiUrl = 'https://api.openai.com/v1/chat/completions';

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _text = 'Olá, o que você deseja?';
  String _voice = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _startInteraction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asimov GPT'),
        backgroundColor: Colors.blue[600],
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
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
              endRadius: 75.0,
              child: FloatingActionButton(
                onPressed: _play,
                child: const Icon(Icons.play_arrow),
              ),
            ),
          ],
        ),
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                visible: _isSpeaking,
                child: const Image(
                  image: AssetImage("assets/talking.gif"),
                ),
              ),
              Visibility(
                visible: _isListening,
                child: const Image(
                  image: AssetImage("assets/listening.gif"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startInteraction() async {
    setState(() {
      _isSpeaking = true;
      _isListening = false;
    });

    await Future.delayed(const Duration(seconds: 1));
    await flutterTts.setLanguage('pt-BR');
    await flutterTts.speak(_text);

    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    await Future.delayed(const Duration(seconds: 3));
    _listen();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) {
          if (val.errorMsg == 'error_speech_timeout' ||
              val.errorMsg == 'error_no_match') {
            _startInteraction();
          }
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) async {
            setState(() {
              _text = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _play() async {
    _voice = await getChatGptResponse(_text);

    setState(() {
      _isListening = false;
      _isSpeaking = true;
    });

    await flutterTts.setLanguage('pt-BR');
    await flutterTts.speak(_text);

    flutterTts.setCompletionHandler(() {
      setState(() async {
        _isSpeaking = false;
        _isListening = true;
        await Future.delayed(const Duration(seconds: 3));
        _text = 'Posso te ajudar em algo mais?';
        _startInteraction();
      });
    });
  }

  Future<String> getChatGptResponse(String message) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization':
          'Bearer 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',
    };

    final data = {
      'model': 'gpt-3.5-turbo',
      'messages': [
        {"role": "user", "content": message}
      ],
      'max_tokens': 50,
    };

    final response = await http.post(Uri.parse(apiUrl),
        headers: headers, body: jsonEncode(data));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final chatGptResponse = jsonResponse['choices'][0]['message']['content'];
      return chatGptResponse;
    } else {
      throw Exception('Failed to get ChatGPT response');
    }
  }
}
