// fidel/service/phonetic.dart

import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform; // Make sure this import is present if using Platform.is...

enum TtsVoiceStyle { friendlyChild, excitedTeacher, storytelling }

class TtsService {
  final FlutterTts _tts = FlutterTts();
  TtsVoiceStyle _currentStyle = TtsVoiceStyle.friendlyChild;

  Map<String, String>? _mekdesVoiceConfig; // Stores Mekdes voice config
  Map<String, String>? _englishVoiceConfig; // Stores a suitable English voice config
  Map<String, String>? _currentDefaultVoice; // Stores the currently active default voice
  bool _isInitialized = false;

  TtsService() {
    // No direct init here
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _tts.awaitSpeakCompletion(true);

    List<dynamic> voices = [];
    // Try to get voices a few times, as they might load asynchronously
    for (int i = 0; i < 20; i++) {
      voices = await _tts.getVoices;
      if (voices.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (voices.isEmpty) {
      print("⚠️ No voices available after multiple attempts.");
      _isInitialized = true;
      return;
    }

    // --- Find and Store Mekdes Voice (Amharic) ---
    for (var voice in voices) {
      if (voice is Map) {
        if (voice['name'] == 'Microsoft Mekdes Online (Natural) - Amharic (Ethiopia)' && voice['locale'] == 'am-ET') {
          _mekdesVoiceConfig = {
            'name': voice['name'],
            'locale': voice['locale'],
          };
          print('✅ Found and stored Mekdes voice config.');
          break;
        }
      }
    }

    // --- Find and Store a suitable English Voice ---
    for (var voice in voices) {
      if (voice is Map) {
        final name = voice['name']?.toString().toLowerCase() ?? '';
        final locale = voice['locale']?.toString().toLowerCase() ?? '';

        if (locale.startsWith('en')) { // Look for any English locale
          // Prioritize female English voices if available
          if (name.contains('female') || name.contains('zira') || name.contains('siri')) { // Common female voice names
            _englishVoiceConfig = {'name': voice['name'], 'locale': voice['locale']};
            break; // Found a good English voice
          }
          // If no specific female, take the first general English voice
          if (_englishVoiceConfig == null) {
            _englishVoiceConfig = {'name': voice['name'], 'locale': voice['locale']};
          }
        }
      }
    }

    // Set the initial default voice to Amharic (Mekdes if found, otherwise system default)
    if (_mekdesVoiceConfig != null) {
      _currentDefaultVoice = _mekdesVoiceConfig;
      await _tts.setVoice(_mekdesVoiceConfig!);
      print('✅ Set initial default voice to Mekdes.');
    } else if (_englishVoiceConfig != null) {
      // Fallback to English if no Amharic voice is found (unlikely if am-ET is available)
      _currentDefaultVoice = _englishVoiceConfig;
      await _tts.setVoice(_englishVoiceConfig!);
      print('✅ Set initial default voice to English (Amharic not found).');
    } else {
      // Last resort: just set language to Amharic and hope for the best
      await _tts.setLanguage("am-ET");
      print('❌ No specific Amharic or English voice found. Using system default for am-ET.');
    }


    await _setVoiceStyle(_currentStyle);
    _isInitialized = true;
  }

  /// Main speak method with optional language and specific voice override.
  Future<void> speak(String text, {TtsVoiceStyle style = TtsVoiceStyle.friendlyChild, String? languageCode, Map<String, String>? specificVoice}) async {
    if (!_isInitialized) {
      print("TTS Service not initialized. Waiting for initialization...");
      await initialize();
    }

    // Store the current voice before potentially changing it
    Map<String, String>? voiceToRevertTo = _currentDefaultVoice;
    try {
      // Attempt to get the current voice from the TTS engine for more robust revert
      final currentVoiceMap = await _tts.getVoices as Map?;
      if (currentVoiceMap != null && currentVoiceMap.isNotEmpty) {
        voiceToRevertTo = {'name': currentVoiceMap['name'], 'locale': currentVoiceMap['locale']};
      }
    } catch (e) {
      print("Could not get current voice for revert: $e");
    }


    // 1. Determine which voice to use for this specific speak call
    Map<String, String>? voiceToUse;
    if (specificVoice != null) {
      voiceToUse = specificVoice;
    } else if (languageCode == 'am-ET' && _mekdesVoiceConfig != null) {
      voiceToUse = _mekdesVoiceConfig;
    } else if (languageCode == 'en-US' && _englishVoiceConfig != null) {
      voiceToUse = _englishVoiceConfig;
    } else if (languageCode == 'am-ET') {
      // If am-ET requested but Mekdes not found, try to use current default (which should be Amharic)
      // or explicitly set am-ET language
      await _tts.setLanguage("am-ET");
    } else if (languageCode == 'en-US') {
      // If en-US requested but English voice not found, try to use current default (which should be English)
      // or explicitly set en-US language
      await _tts.setLanguage("en-US");
    } else {
      // Fallback to the current default voice set during initialization
      if (_currentDefaultVoice != null) {
        voiceToUse = _currentDefaultVoice;
      } else {
        // Last resort: set language to Amharic if nothing else
        await _tts.setLanguage("am-ET");
      }
    }

    if (voiceToUse != null) {
      try {
        await _tts.setVoice(voiceToUse);
        print('Using voice: ${voiceToUse['name']} for "$text"');
      } catch (e) {
        print('Error setting voice ${voiceToUse['name']}: $e. Falling back to language only.');
        await _tts.setLanguage(voiceToUse['locale'] ?? 'am-ET'); // Fallback to language
      }
    }


    // 2. Apply style settings
    if (style != _currentStyle) {
      await _setVoiceStyle(style);
    }

    // 3. Speak the text
    final pacedText = _addSpeechPauses(text);
    await _tts.speak(pacedText);

    // 4. Revert to the original default voice after speaking
    if (voiceToRevertTo != null && voiceToUse != voiceToRevertTo) {
      try {
        await _tts.setVoice(voiceToRevertTo);
        print('Reverted voice to: ${voiceToRevertTo['name']}');
      } catch (e) {
        print('Error reverting voice to default: $e');
      }
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  String _addSpeechPauses(String text) {
    return text
        .replaceAll(':', ', ')
        .replaceAll('.', '. ')
        .replaceAll('  ', ' ');
  }

  Future<void> _setVoiceStyle(TtsVoiceStyle style) async {
    _currentStyle = style;
    switch (style) {
      case TtsVoiceStyle.friendlyChild:
        await _tts.setSpeechRate(0.75);
        await _tts.setPitch(1.3);
        await _tts.setVolume(1.0);
        break;
      case TtsVoiceStyle.excitedTeacher:
        await _tts.setSpeechRate(0.5);
        await _tts.setPitch(1.1);
        await _tts.setVolume(0.9);
        break;
      case TtsVoiceStyle.storytelling:
        await _tts.setSpeechRate(0.4);
        await _tts.setPitch(0.95);
        await _tts.setVolume(0.85);
        break;
    }
  }

  Map<String, String>? get mekdesVoiceConfig => _mekdesVoiceConfig;
  Map<String, String>? get englishVoiceConfig => _englishVoiceConfig;
}