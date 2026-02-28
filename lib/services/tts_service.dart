import 'package:flutter_tts/flutter_tts.dart';
import '../constants/app_constants.dart';

/// Text-to-speech playback wrapper using flutter_tts.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  double _speechRate = AppConstants.ttsSpeechRate;

  Future<void> _init() async {
    if (_initialized) return;
    await _tts.setLanguage(AppConstants.ttsLanguage);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(AppConstants.ttsVolume);
    await _tts.setPitch(AppConstants.ttsPitch);
    _initialized = true;
  }

  /// Update speech rate dynamically. Called when user changes settings.
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    if (_initialized) {
      await _tts.setSpeechRate(_speechRate);
    }
  }

  Future<void> speak(String text) async {
    try {
      await _init();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // TTS failure is non-critical; silently ignore
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore stop errors
    }
  }
}
