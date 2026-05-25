import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AlphabetPage extends StatefulWidget {
  const AlphabetPage({super.key});

  @override
  State<AlphabetPage> createState() => _AlphabetPageState();
}

class _AlphabetPageState extends State<AlphabetPage> {
  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTtsAndSpeakGreeting();
  }

  Future<void> _initTtsAndSpeakGreeting() async {
    // 1. Set the language first
    await tts.setLanguage("am-ET");

    // 2. Get available voices to confirm "Mekdes" is there (optional, but good for debugging)
    List<dynamic> voices = await tts.getVoices;
    print('All available voices: $voices'); // Log all voices for confirmation

    // 3. Find and set the specific "Mekdes" voice
    Map<String, String>? mekdesVoice;
    for (var voice in voices) {
      if (voice['name'] == 'Microsoft Mekdes Online (Natural) - Amharic (Ethiopia)' && voice['locale'] == 'am-ET') {
        mekdesVoice = {
          'name': voice['name'],
          'locale': voice['locale'],
        };
        break; // Found the voice, no need to continue looping
      }
    }

    if (mekdesVoice != null) {
      await tts.setVoice(mekdesVoice);
      print('Set voice to: ${mekdesVoice['name']}');
    } else {
      print('Microsoft Mekdes voice not found. Using default voice for am-ET.');
    }

    // 4. Set speech rate
    await tts.setSpeechRate(1.0); // Optional: slower rate

    // 5. Speak the greeting
    await tts.speak("እንኳን ደህና መጣቹህ"); // Speak Amharic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn Alphabet')),
      body: const Center(
        child: Text(
          'Alphabet Learning Coming Soon!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}