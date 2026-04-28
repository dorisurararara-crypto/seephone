import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

class RitualScreen extends ConsumerStatefulWidget {
  final String question;
  const RitualScreen({super.key, required this.question});

  @override
  ConsumerState<RitualScreen> createState() => _RitualScreenState();
}

class _RitualScreenState extends ConsumerState<RitualScreen> {
  static const _shakeThreshold = 18.0; // m/s² — 흔들기 강도 임계값
  static const _shakeCooldownMs = 500; // 흔들기 1회로 카운트되는 최소 간격
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
      final magnitude = (e.x * e.x + e.y * e.y + e.z * e.z);
      if (magnitude > _shakeThreshold * _shakeThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastShakeAt).inMilliseconds < _shakeCooldownMs) return;
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
    // TODO: 디자인 변종 선택 후 굿판 애니메이션 입힘 (flutter_animate).
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('흔들어!',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
              const SizedBox(height: 32),
              Text('$_shakeCount / $_requiredShakes',
                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              const Text('위아래로 흔드시오',
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
