import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
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
  int _interaction = 0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _startInteraction('start');
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

  Future<void> _startInteraction(String status) async {
    if (status == 'start') {
      _text = 'Olá, sou Asimov. Como posso te ajudar?';
    } else if (status == 'error') {
      _text = 'Não entendi o que você disse, poderia repetir?';
      _interaction = 0;
    }

    if ((status == 'start' || status == 'error') && _interaction == 0) {
      setState(() {
        _isListening = false;
        _isSpeaking = true;
      });

      await Future.delayed(const Duration(seconds: 1));
      await flutterTts.setLanguage('pt-BR');
      await flutterTts.speak(_text);

      flutterTts.setCompletionHandler(() {
        setState(() {
          _isSpeaking = false;
        });
        _listen();
      });
    } else if (status == 'repeat') {
      _isListening = false;
      await Future.delayed(const Duration(seconds: 1));
      _listen();
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) {
          if (val.errorMsg == 'error_speech_timeout' ||
              val.errorMsg == 'error_no_match') {
            _startInteraction('error');
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
            if (val.finalResult) {
              _play();
            }
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

    List<int> latin1Bytes = latin1.encode(_voice);
    String textUtf8 = utf8.decode(latin1Bytes);
    await flutterTts.speak(textUtf8);

    flutterTts.setCompletionHandler(() {
      setState(() async {
        _isSpeaking = false;
        _isListening = true;
        _interaction++;
        _text = 'Posso te ajudar em algo mais?';
        _startInteraction('repeat');
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
