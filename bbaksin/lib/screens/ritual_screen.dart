import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import '../services/sound_service.dart';
import '../theme/theme_provider.dart';

class RitualScreen extends ConsumerStatefulWidget {
  final String question;
  const RitualScreen({super.key, required this.question});

  @override
  ConsumerState<RitualScreen> createState() => _RitualScreenState();
}

class _RitualScreenState extends ConsumerState<RitualScreen> {
  static const _shakeThreshold = 18.0; // m/s²
  static const _shakeCooldownMs = 500;
  static const _requiredShakes = 3;

  StreamSubscription<UserAccelerometerEvent>? _sub;
  int _shakeCount = 0;
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _completing = false;
  final _sfx = SoundService();

  @override
  void initState() {
    super.initState();
    _sfx.play(BbaksinSfx.bellStart);
    _startListening();
  }

  void _startListening() {
    _sub = userAccelerometerEventStream().listen((e) {
      final magnitude = e.x * e.x + e.y * e.y + e.z * e.z;
      if (magnitude > _shakeThreshold * _shakeThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastShakeAt).inMilliseconds < _shakeCooldownMs) {
          return;
        }
        _lastShakeAt = now;
        _onShake();
      }
    });
  }

  Future<void> _onShake() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 50);
    }
    _sfx.play(BbaksinSfx.drumShake);
    setState(() => _shakeCount++);
    if (_shakeCount >= _requiredShakes) {
      _sub?.cancel();
      if (!mounted) return;
      setState(() => _completing = true);
      _sfx.play(BbaksinSfx.climax);
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(pattern: [0, 100, 80, 200]);
      }
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      context.go('/result?q=${Uri.encodeComponent(widget.question)}');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sfx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: theme.buildScreenBackground(),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    theme.buildShakePrompt('흔들어'),
                    const SizedBox(height: 32),
                    theme.buildShakeCounter(_shakeCount, _requiredShakes),
                    const SizedBox(height: 32),
                    theme.buildShakeHint('위아래로 흔드시오'),
                  ],
                ),
              ),
            ),
          ),
          if (_completing)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Image.asset(
                  'assets/effects/v5_climax_shot.png',
                  fit: BoxFit.cover,
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.2, 1.2),
                    duration: 1500.ms,
                    curve: Curves.easeOutQuart,
                  ),
            ),
        ],
      ),
    );
  }
}
