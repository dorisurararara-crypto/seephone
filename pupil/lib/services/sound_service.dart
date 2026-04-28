import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final _player = AudioPlayer();

  Future<void> play(String name) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sfx/$name.mp3'));
    } catch (_) {}
  }

  void dispose() => _player.dispose();
}

class PupilSfx {
  static const tap = 'ui_tap';
  static const share = 'ui_share';
  static const scanStart = 'tech_scan_beep';
  static const tick = 'tech_tick';
  static const scanDone = 'tech_scan_done';
  static const lieDetected = 'alert_siren';
  static const truthConfirmed = 'tech_confirm';
  static const dramaReveal = 'drama_stinger';
}
