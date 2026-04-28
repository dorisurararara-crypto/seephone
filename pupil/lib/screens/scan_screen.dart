import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/lie_detector.dart';

/// 전면 카메라로 3초간 스캔.
///
/// MVP: ML Kit FaceDetector 로 매 프레임 얼굴 분석 → 깜빡임/회전/웃음 누적.
/// 3초 후 LieDetector.compute() → 결과 화면.
///
/// TODO: ML Kit 카메라 stream image → InputImage 변환 (플랫폼별 처리).
/// 현재는 카운트다운만 보여주고 fallback 점수 사용. 실 트래킹은 v1.1.
class ScanScreen extends StatefulWidget {
  final String question;
  const ScanScreen({super.key, required this.question});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _camera;
  Timer? _countdownTimer;
  int _remaining = 3;

  // 누적 신호 (실제 트래킹 추가 시 채움)
  final int _blinkCount = 0;
  final double _headRotation = 0;
  final double _smileSum = 0;
  final int _smileSamples = 0;

  late final FaceDetector _faceDetector;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // 웃음 detection
        enableLandmarks: true,
        enableTracking: true,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _camera = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _camera!.initialize();
      if (!mounted) return;
      setState(() {});
      _startCountdown();
    } catch (e) {
      // 카메라 실패 → fallback 점수로 결과 화면
      _navigateWithFallback();
    }
  }

  void _startCountdown() {
    setState(() => _isScanning = true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _finishScan();
      }
    });
  }

  void _finishScan() {
    if (!mounted) return;
    final smileAvg = _smileSamples > 0 ? _smileSum / _smileSamples : 0.5;
    final score = LieDetector.compute(
      blinkCount: _blinkCount,
      headRotationDelta: _headRotation,
      smileProbabilityAvg: smileAvg,
      questionHash: widget.question.hashCode,
    );
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
    _camera?.dispose();
    _faceDetector.close();
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
              'SCANNING',
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
