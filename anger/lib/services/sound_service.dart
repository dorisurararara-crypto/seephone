import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final _player = AudioPlayer();
  final _ambient = AudioPlayer();

  Future<void> play(String name) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sfx/$name.mp3'));
    } catch (_) {}
  }

  Future<void> playAmbient(String name, {bool loop = true}) async {
    try {
      await _ambient.stop();
      _ambient.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _ambient.play(AssetSource('sfx/$name.mp3'));
    } catch (_) {}
  }

  Future<void> stopAmbient() async {
    try {
      await _ambient.stop();
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
    _ambient.dispose();
  }
}

class AngerSfx {
  static const tap = 'ui_tap';
  static const share = 'ui_share';
  static const measureStart = 'elec_surge';
  static const buzzLow = 'elec_buzz_low';
  static const buzzHigh = 'elec_buzz_high';
  static const zap = 'elec_zap';
  static const buzzer = 'drama_buzzer';
}
