import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
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

  @override
  void initState() {
    super.initState();
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
    setState(() => _shakeCount++);
    if (_shakeCount >= _requiredShakes) {
      _sub?.cancel();
      if (!mounted) return;
      context.go(
        '/result?q=${Uri.encodeComponent(widget.question)}',
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
      body: Container(
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
    );
  }
}
