/// Stub for v0.2 Stage 1 (Agent C): wraps just_audio to play ayah audio
/// from the multi-CDN reciter catalog. Until populated, no-ops.
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  Future<void> playAyah(int surah, int ayah) async {
    // Agent C wires this to the AudioPlayer + reciter URL builder.
  }

  Future<void> stop() async {}

  Future<void> togglePause() async {}
}
