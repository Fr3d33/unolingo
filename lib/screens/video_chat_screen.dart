import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:deepseek/deepseek.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/duolingo_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoChatScreen extends StatefulWidget {
  const VideoChatScreen({Key? key}) : super(key: key);

  @override
  _VideoChatScreenState createState() => _VideoChatScreenState();
}

class _VideoChatScreenState extends State<VideoChatScreen> with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _isRecording = false;
  String _selectedLanguage = 'Spanish';
  bool _speechEnabled = false;
  String _lastWords = '';
  final FlutterTts _flutterTts = FlutterTts();
  bool _isProcessing = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  late AnimationController _characterAnimationController;
  late Animation<double> _characterAnimation;
  bool _hasPermission = false;
  String _status = "Warte auf Mikro-Rechte...";

  final List<String> _availableLanguages = [
    'Spanish',
    'French',
    'German',
    'Italian',
    'Japanese',
    'Mandarin',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _characterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _characterAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _characterAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _initSpeech();
    _initializeTTS();
    _initMic();
  }

  @override
  void dispose() {
    _characterAnimationController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<String> getAIResponse(String inputText) async {
    final apiKey = dotenv.env['API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return "API Key not found in .env file";
    }

    final deepSeek = DeepSeek(apiKey);

    try {
      Completion response = await deepSeek.createChat(
        messages: [
          Message(
            role: "user",
            content: 'Du bist ein Sprachassistent. Antworte mir bitte in der Sprache: $_selectedLanguage. Ich werde dir jetzt etwas sagen: "$inputText". Antworte mir bitte basierend auf diesem Text. Baue keine Anmerkungen etc ein einfach nur den Text'
          )
        ],
        model: Models.chat.name,
        options: {
          "temperature": 1.0,
          "max_tokens": 150,
        },
      );

      String aiResponse = response.text;
      if (aiResponse.isEmpty) {
        return "Empty response from AI";
      }
      
      return aiResponse;
      
    } on DeepSeekException catch (e) {
      return "API Error: ${e.message}";
    } catch (e) {
      return "Unexpected Error: $e";
    }
  }

  void _initializeTTS() async {
    await _flutterTts.setLanguage("de-DE");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    
    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
        _characterAnimationController.repeat(reverse: true);
      });
    });
    
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        _characterAnimationController.stop();
        _characterAnimationController.reset();
      });
    });
  }

  Future<void> _initMic() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      bool available = await _speechToText.initialize();
      setState(() {
        _hasPermission = true;
        _speechEnabled = available;
        _status = available ? "Bereit zum Zuhören" : "Spracherkennung nicht verfügbar";
      });
    } else {
      setState(() {
        _status = "Mikrofon-Rechte verweigert";
      });
    }
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      bool available = await _speechToText.initialize();
      if (available) {
        await _speechToText.listen(onResult: _onSpeechResult);
        setState(() {
          _isListening = true;
        });
      }
    }
  }

  void speakAIResponse(String aiResponse) async {
    if (aiResponse.isNotEmpty) {
      await _flutterTts.speak(aiResponse);
    }
  }

  void _onLanguageChanged(String? language) {
    if (language != null) {
      setState(() {
        _selectedLanguage = language;
      });
    }
  }

  void _startListening() {
    if (!_speechToText.isListening && !_isProcessing) {
      _speechToText.listen(onResult: _onSpeechResult);
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    if (_isProcessing) return; 
    setState(() {
      _lastWords = result.recognizedWords;  
    });
    if (_lastWords.isNotEmpty) {
      setState(() {
        _isProcessing = true; 
      });
      try {
        String aiResponse = await getAIResponse(_lastWords);
        aiResponse = cleanResponse(aiResponse);
        speakAIResponse(aiResponse);
        setState(() {
          _lastWords = aiResponse; 
        });
      } catch (e) {
        print("Error: $e");
      } finally {
        setState(() {
          _isProcessing = false; 
        });
      }
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  String cleanResponse(String response) {
    return response.replaceAll('ð', '').replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                style: GoogleFonts.nunito(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initMic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DuolingoTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Mikrofon-Zugriff erlauben",
                  style: GoogleFonts.nunito(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: DuolingoTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildLanguageSelector(),
            _buildLessonHeader(),
            SizedBox(
              child: Stack(
                children: [
                  _buildCharacter(),
                  _buildVideoArea(),
                ],
              ),
            ),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: DuolingoTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: DropdownButton<String>(
        value: _selectedLanguage,
        isExpanded: true,
        dropdownColor: Colors.grey[900],
        style: GoogleFonts.nunito(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(
          Icons.arrow_drop_down,
          color: DuolingoTheme.primaryColor,
        ),
        underline: Container(
          height: 2,
          color: DuolingoTheme.primaryColor,
        ),
        onChanged: _onLanguageChanged,
        items: _availableLanguages.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: DuolingoTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(value),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLessonHeader() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: DuolingoTheme.primaryColor,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: DuolingoTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPRACHÜBUNG',
                  style: GoogleFonts.nunito(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Übe $_selectedLanguage',
                  style: GoogleFonts.nunito(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(8.0),
            child: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter() {
    return Positioned(
      bottom: 0,
      left: 20,
      child: AnimatedBuilder(
        animation: _characterAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isSpeaking ? _characterAnimation.value : 1.0,
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Character avatar placeholder
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: DuolingoTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_people,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  if (_isSpeaking)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: DuolingoTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isListening || _isProcessing)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: DuolingoTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.hourglass_top,
                    color: DuolingoTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? 'Ich höre zu...' : 'Verarbeite...',
                    style: GoogleFonts.nunito(
                      textStyle: const TextStyle(
                        color: DuolingoTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (_lastWords.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: _isSpeaking 
                      ? DuolingoTheme.primaryColor 
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  if (_isSpeaking)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.volume_up,
                          color: DuolingoTheme.primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Spricht...',
                          style: GoogleFonts.nunito(
                            textStyle: const TextStyle(
                              color: DuolingoTheme.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_isSpeaking)
                    const SizedBox(height: 12),
                  Text(
                    _lastWords,
                    style: GoogleFonts.nunito(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.4,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (_lastWords.isEmpty && !_isListening)
            Column(
              children: [
                Icon(
                  Icons.mic_none,
                  color: Colors.grey[400],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Drücke auf das Mikrofon, um zu sprechen',
                  style: GoogleFonts.nunito(
                    textStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(
            icon: _isListening ? Icons.mic : Icons.mic_off,
            color: _isListening ? DuolingoTheme.primaryColor : Colors.grey[700]!,
            onPressed: () {
              _toggleMic();
            },
            label: _isListening ? 'Zuhören' : 'Mikrofon',
          ),
          _buildCircleButton(
            icon: Icons.videocam,
            color: Colors.green,
            onPressed: () {
              _startListening();
            },
            label: 'Video',
          ),
          _buildCircleButton(
            icon: Icons.call_end,
            color: Colors.red,
            onPressed: () {
              _stopListening();
              setState(() {
                _lastWords = '';
              });
            },
            label: 'Beenden',
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.nunito(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}