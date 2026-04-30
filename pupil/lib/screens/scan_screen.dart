import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/face_tracker.dart';
import '../services/lie_detector.dart';
import '../services/sound_service.dart';

/// 전면 카메라로 3초간 스캔 + ML Kit 얼굴 분석.
///
/// 카메라 stream → FaceTracker.processFrame → 4 가지 신호 누적
/// (깜빡임 / 머리 회전 / 웃음 / 동공 흔들림) → 3초 후 LieDetector.compute
class ScanScreen extends StatefulWidget {
  final String question;
  const ScanScreen({super.key, required this.question});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _camera;
  FaceTracker? _tracker;
  Timer? _countdownTimer;
  int _remaining = 3;

  bool _isScanning = false;
  bool _streaming = false;
  final _sfx = SoundService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _tracker = FaceTracker(cameraDescription: front);
      _camera = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      await _camera!.initialize();
      if (!mounted) return;
      setState(() {});
      await _startStream();
      _startCountdown();
    } catch (e) {
      _navigateWithFallback();
    }
  }

  Future<void> _startStream() async {
    if (_camera == null || _tracker == null) return;
    try {
      await _camera!.startImageStream((image) {
        // tracker 가 busy 면 자체적으로 skip — backpressure 처리
        _tracker!.processFrame(image);
      });
      _streaming = true;
    } catch (_) {
      // 스트림 실패해도 fallback 점수로 계속 진행
    }
  }

  void _startCountdown() {
    setState(() => _isScanning = true);
    _sfx.play(PupilSfx.scanStart);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _remaining--);
      _sfx.play(PupilSfx.tick);
      if (_remaining <= 0) {
        t.cancel();
        _sfx.play(PupilSfx.scanDone);
        _finishScan();
      }
    });
  }

  Future<void> _finishScan() async {
    if (!mounted) return;
    // 스트림 멈추고 마지막 in-flight 프레임이 끝나길 살짝 기다림
    if (_streaming) {
      try {
        await _camera?.stopImageStream();
      } catch (_) {}
      _streaming = false;
    }

    final result = _tracker?.snapshot();
    final LieScore score;
    if (result != null && result.hasData) {
      score = LieDetector.compute(
        pupilJitter: result.pupilJitter,
        saccadeBurst: result.saccadeBurst,
        gazeAversion: result.gazeAversion,
        blinkCount: result.blinkCount,
        blinkAnomaly: result.blinkAnomaly,
        facialAsymmetry: result.facialAsymmetry,
        microFlicker: result.microFlicker,
        headRotationDelta: result.headRotationSum,
        smileProbabilityAvg: result.smileAvg,
        questionHash: widget.question.hashCode,
      );
    } else {
      score = LieDetector.fallback(widget.question);
    }
    if (!mounted) return;
    context.go(
      '/result?q=${Uri.encodeComponent(widget.question)}&score=${score.magnitude}',
    );
  }

  void _navigateWithFallback() {
    final score = LieDetector.fallback(widget.question);
    if (!mounted) return;
    context.go(
      '/result?q=${Uri.encodeComponent(widget.question)}&score=${score.magnitude}',
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    if (_streaming) {
      _camera?.stopImageStream().catchError((_) {});
    }
    _camera?.dispose();
    _tracker?.dispose();
    _sfx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.question,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_camera != null && _camera!.value.isInitialized)
                    CameraPreview(_camera!)
                  else
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF3D5A),
                      ),
                    ),
                  // 얼굴 가이드 박스
                  Center(
                    child: Container(
                      width: 240,
                      height: 320,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFF3D5A),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (_isScanning)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_remaining',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF3D5A),
                            fontSize: 96,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).scanning,
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 12,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
