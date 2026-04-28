import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import '../services/anger_calc.dart';
import '../services/sound_service.dart';

class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key});

  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen> {
  static const _durationSec = 10;
  Timer? _ticker;
  StreamSubscription<UserAccelerometerEvent>? _sub;

  int _remainingMs = _durationSec * 1000;
  double _accelSum = 0;
  int _touchCount = 0;
  bool _running = false;

  // 실시간 시각 효과용
  double _instantMagnitude = 0;
  final _sfx = SoundService();
  bool _highBuzz = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() async {
    if (await Vibration.hasVibrator()) Vibration.vibrate(duration: 80);
    _sfx.play(AngerSfx.measureStart);
    await Future.delayed(const Duration(milliseconds: 600));
    _sfx.playAmbient(AngerSfx.buzzLow, loop: true);
    setState(() => _running = true);

    final start = DateTime.now();
    _sub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 16),
    ).listen((e) {
      final m = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      _accelSum += m * 0.016; // dt
      // 강도에 따라 ambient 전환
      final shouldBeHigh = m > 15;
      if (shouldBeHigh != _highBuzz) {
        _highBuzz = shouldBeHigh;
        _sfx.playAmbient(shouldBeHigh ? AngerSfx.buzzHigh : AngerSfx.buzzLow);
      }
      if (mounted) setState(() => _instantMagnitude = m);
    });

    _ticker = Timer.periodic(const Duration(milliseconds: 50), (t) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final remaining = (_durationSec * 1000) - elapsed;
      if (remaining <= 0) {
        t.cancel();
        _finish();
        return;
      }
      if (mounted) setState(() => _remainingMs = remaining);
    });
  }

  void _finish() async {
    _sub?.cancel();
    _sfx.stopAmbient();
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
    final watts =
        AngerCalc.computeWatts(accelMagnitudeSum: _accelSum, touchCount: _touchCount);
    if (!mounted) return;
    context.go('/result?w=$watts');
  }

  void _onTap() {
    if (!_running) return;
    _touchCount++;
    if (_touchCount % 3 == 0) _sfx.play(AngerSfx.zap);
    if (_instantMagnitude < 5) {
      if (_touchCount % 3 == 0) Vibration.vibrate(duration: 20);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sub?.cancel();
    _sfx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = (_instantMagnitude / 30).clamp(0.0, 1.0);
    final secondsLeft = (_remainingMs / 1000).ceil();

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _onTap(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Color.lerp(Colors.black, const Color(0xFFFFB800),
                    intensity * 0.6)!,
                Colors.black,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$secondsLeft',
                        style: GoogleFonts.blackHanSans(
                          fontSize: 240,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '흔들어 두드려',
                        style: GoogleFonts.blackHanSans(
                          fontSize: 32,
                          color: const Color(0xFFFFB800),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 32,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      Text(
                        '실시간 ${(_instantMagnitude * 5).toStringAsFixed(0)}W · 누적 ${(AngerCalc.computeWatts(accelMagnitudeSum: _accelSum, touchCount: _touchCount)).toStringAsFixed(0)}W',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '두드림 $_touchCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
