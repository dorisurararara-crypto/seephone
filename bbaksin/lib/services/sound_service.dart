import 'package:audioplayers/audioplayers.dart';

/// 빡신 SFX. 각 인스턴스는 단일 player 보유 — 동시 재생 안 됨 (의도적: SFX 겹침 방지).
/// ambient 같이 길게 가는 건 별도 player 인스턴스 권장.
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

// 빡신 SFX 이름 상수
class BbaksinSfx {
  static const tap = 'ui_tap';
  static const success = 'ui_success';
  static const share = 'ui_share';
  static const bellStart = 'kr_bell_short';
  static const drumShake = 'kr_drum_buk';
  static const climax = 'magic_burst';
  static const reveal = 'magic_chime';
  static const ambient = 'magic_drone';
}
