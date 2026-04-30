import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/baseline_questions.dart';
import '../l10n/app_localizations.dart';
import '../services/face_tracker.dart';
import '../services/lie_detector.dart';
import '../services/sound_service.dart';

/// 거짓말 탐지 스캔 화면.
///
/// 5 phase 진행:
///   INIT       — 카메라 부팅
///   BASELINE_ASK — 1.5초 "이름 말해보세요" 안내
///   BASELINE   — 4초 평소 신호 측정 (진실 답변)
///   ASK        — 2초 "이제 진짜 질문하세요"
///   ANALYZE    — 8초 본 측정 + 분석 HUD
///   DONE       — 결과 화면으로
///
/// baseline 차감으로 개인 편차 보정 → 정확도 향상.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _Phase { initializing, baselineAsk, baseline, ask, analyze, done }

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin {
  CameraController? _camera;
  FaceTracker? _tracker;
  Timer? _phaseTimer;

  _Phase _phase = _Phase.initializing;
  int _remaining = 8;
  BaselineSignals _baseline = BaselineSignals.empty;
  String _baselineQuestion = '';

  bool _streaming = false;
  final _sfx = SoundService();

  // 분석 중 HUD 펄스 애니메이션
  late final AnimationController _pulse;
  // 스캔라인 위→아래 이동
  late final AnimationController _scanline;
  // 실시간 신호 ticker (ML Kit 부분 결과 노출용)
  Timer? _hudTicker;
  FaceTrackingResult? _liveSnapshot;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scanline = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
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
      _startBaselineAskPhase();
    } catch (_) {
      _navigateWithFallback();
    }
  }

  Future<void> _startStream() async {
    if (_camera == null || _tracker == null) return;
    try {
      await _camera!.startImageStream((image) {
        _tracker!.processFrame(image);
      });
      _streaming = true;
    } catch (_) {}
  }

  // === Phase 1: Baseline Ask (2.5초) ===
  void _startBaselineAskPhase() {
    setState(() {
      _phase = _Phase.baselineAsk;
      _remaining = 4;
      _baselineQuestion = BaselineQuestions.pick(Localizations.localeOf(context));
    });
    _sfx.play(PupilSfx.scanStart);
    // 2.5초 — 사용자가 질문 읽고 친구가 인지할 시간
    _phaseTimer = Timer(const Duration(milliseconds: 2500), _startBaselinePhase);
  }

  // === Phase 2: Baseline 측정 (4초, 진실 신호) ===
  void _startBaselinePhase() {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.baseline;
      _remaining = 4;
    });
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _remaining--);
      _sfx.play(PupilSfx.tick);
      if (_remaining <= 0) {
        t.cancel();
        _captureBaseline();
        _startAskPhase();
      }
    });
  }

  void _captureBaseline() {
    final r = _tracker?.snapshot();
    if (r != null && r.hasData) {
      _baseline = BaselineSignals(
        pupilJitter: r.pupilJitter,
        saccadeBurst: r.saccadeBurst,
        gazeAversion: r.gazeAversion,
        blinkCount: r.blinkCount,
        facialAsymmetry: r.facialAsymmetry,
        microFlicker: r.microFlicker,
        headRotationDelta: r.headRotationSum,
        smileProbabilityAvg: r.smileAvg,
      );
    }
    // 누적 시계열 비우고 본 측정 준비
    _tracker?.reset();
  }

  // === Phase 3: Ask (사용자 탭 대기 — 자동 진행 X) ===
  void _startAskPhase() {
    if (!mounted) return;
    setState(() => _phase = _Phase.ask);
    _sfx.play(PupilSfx.scanStart);
    // 자동 timer 없음. 사용자가 진짜 질문 만든 후 "탭하면 시작".
  }

  void _onUserTapStart() {
    if (_phase != _Phase.ask) return;
    _startAnalyzePhase();
  }

  // === Phase 4: Analyze (8초 본 측정) ===
  void _startAnalyzePhase() {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.analyze;
      _remaining = 8;
    });
    _hudTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      setState(() => _liveSnapshot = _tracker?.snapshot());
    });
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (t) {
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
    _hudTicker?.cancel();
    if (_streaming) {
      try {
        await _camera?.stopImageStream();
      } catch (_) {}
      _streaming = false;
    }

    // 질문 hash 가 없으니 timestamp + frame count 로 noise seed
    final seed =
        DateTime.now().millisecondsSinceEpoch ^ (_tracker?.snapshot().sampleCount ?? 0);

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
        questionHash: seed,
        baseline: _baseline,
      );
    } else {
      score = LieDetector.fallback(seed.toString());
    }
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
    context.go('/result?score=${score.magnitude}');
  }

  void _navigateWithFallback() {
    final score = LieDetector.fallback(
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
    if (!mounted) return;
    context.go('/result?score=${score.magnitude}');
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _hudTicker?.cancel();
    _pulse.dispose();
    _scanline.dispose();
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
        child: Stack(
          children: [
            // 카메라 프리뷰 (전체)
            Positioned.fill(
              child: _camera != null && _camera!.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _camera!.value.previewSize?.height ?? 1,
                        height: _camera!.value.previewSize?.width ?? 1,
                        child: CameraPreview(_camera!),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF3D5A),
                      ),
                    ),
            ),

            // 분석 단계: 어두운 vignette + HUD + 실시간 눈알 트래킹
            if (_phase == _Phase.analyze && _tracker != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<LiveFaceFrame>(
                    valueListenable: _tracker!.live,
                    builder: (context, frame, _) => AnimatedBuilder(
                      animation: Listenable.merge([_pulse, _scanline]),
                      builder: (context, _) => CustomPaint(
                        painter: _AnalyzeHudPainter(
                          pulse: _pulse.value,
                          scanline: _scanline.value,
                          frame: frame,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 상단 바
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(phase: _phase),
            ),

            // BASELINE_ASK phase: 랜덤 진실 질문 표시
            if (_phase == _Phase.baselineAsk)
              _BaselineAskOverlay(
                pulse: _pulse,
                question: _baselineQuestion,
              ),

            // BASELINE phase: 카운트 + 진실 신호 측정 중
            if (_phase == _Phase.baseline)
              _BaselineMeasureOverlay(remaining: _remaining),

            // ASK phase: "이제 진짜 질문" + 탭하면 시작
            if (_phase == _Phase.ask)
              _AskOverlay(pulse: _pulse, onTap: _onUserTapStart),

            // ANALYZE phase: HUD 신호 게이지 + 카운트
            if (_phase == _Phase.analyze)
              _AnalyzeOverlay(
                remaining: _remaining,
                snapshot: _liveSnapshot,
              ),
          ],
        ),
      ),
    );
  }
}

// ============ 상단 바 ============

class _TopBar extends StatelessWidget {
  final _Phase phase;
  const _TopBar({required this.phase});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = switch (phase) {
      _Phase.initializing => l.statusInit,
      _Phase.baselineAsk => l.statusBaseline,
      _Phase.baseline => l.statusBaseline,
      _Phase.ask => l.statusAsk,
      _Phase.analyze => l.statusAnalyze,
      _Phase.done => l.statusDone,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFFFF3D5A).withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3D5A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'PUPIL v2.0',
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ ASK overlay (질문하세요) ============

// ============ BASELINE ASK overlay (랜덤 진실 질문) ============

class _BaselineAskOverlay extends StatelessWidget {
  final AnimationController pulse;
  final String question;
  const _BaselineAskOverlay({required this.pulse, required this.question});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) => Transform.scale(
          scale: 1.0 + pulse.value * 0.04,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00E0FF), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.baselineCalibration,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00E0FF),
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  question,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l.baselineHint,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.4,
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

// ============ BASELINE MEASURE overlay (카운트) ============

class _BaselineMeasureOverlay extends StatelessWidget {
  final int remaining;
  const _BaselineMeasureOverlay({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        // 가운데 큰 카운트
        Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00E0FF).withValues(alpha: 0.7),
                width: 2,
              ),
            ),
            child: Text(
              '$remaining',
              style: GoogleFonts.inter(
                color: const Color(0xFF00E0FF),
                fontSize: 80,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
        // 아래 라벨
        Positioned(
          left: 0,
          right: 0,
          bottom: 60,
          child: Column(
            children: [
              Text(
                l.statusBaseline,
                style: GoogleFonts.inter(
                  color: const Color(0xFF00E0FF),
                  fontSize: 11,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.baselineHintShort,
                style: GoogleFonts.notoSansKr(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AskOverlay extends StatelessWidget {
  final AnimationController pulse;
  final VoidCallback onTap;
  const _AskOverlay({required this.pulse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        // 상단 안내문
        Positioned(
          top: 80,
          left: 24,
          right: 24,
          child: Column(
            children: [
              Text(
                l.askNow,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFF3D5A).withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.askHint,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        // 하단 거대 시작 버튼 (펄스)
        Positioned(
          left: 24,
          right: 24,
          bottom: 50,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              final glow = 8 + pulse.value * 14;
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3D5A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3D5A).withValues(alpha: 0.5),
                        blurRadius: glow,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 28 + pulse.value * 4,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.tapToStart,
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        l.tapToStartHint,
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============ ANALYZE overlay ============

class _AnalyzeOverlay extends StatelessWidget {
  final int remaining;
  final FaceTrackingResult? snapshot;
  const _AnalyzeOverlay({required this.remaining, this.snapshot});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = snapshot;
    return Stack(
      children: [
        // 좌측: 실시간 신호 게이지
        Positioned(
          left: 12,
          top: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Gauge(
                label: l.metricBlink,
                value: (s?.blinkCount ?? 0) / 6.0,
                rawText: '${s?.blinkCount ?? 0}',
              ),
              const SizedBox(height: 10),
              _Gauge(
                label: l.metricGaze,
                value: (s?.gazeAversion ?? 0) / 0.3,
                rawText: ((s?.gazeAversion ?? 0) * 100).toStringAsFixed(0),
              ),
              const SizedBox(height: 10),
              _Gauge(
                label: l.metricAsym,
                value: (s?.facialAsymmetry ?? 0) / 0.06,
                rawText: ((s?.facialAsymmetry ?? 0) * 100).toStringAsFixed(0),
              ),
              const SizedBox(height: 10),
              _Gauge(
                label: l.metricStress,
                value: (s?.headRotationSum ?? 0) / 60.0,
                rawText: ((s?.headRotationSum ?? 0)).toStringAsFixed(0),
              ),
            ],
          ),
        ),

        // 우측: 추가 메트릭
        Positioned(
          right: 12,
          top: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Metric(label: l.metricFrames, value: '${s?.sampleCount ?? 0}'),
              const SizedBox(height: 6),
              _Metric(
                label: l.metricSaccade,
                value: '${s?.saccadeBurst ?? 0}',
              ),
              const SizedBox(height: 6),
              _Metric(
                label: l.metricFlicker,
                value: ((s?.microFlicker ?? 0) * 100).toStringAsFixed(0),
              ),
              const SizedBox(height: 6),
              _Metric(label: 'FACE LOCK', value: (s?.sampleCount ?? 0) > 5 ? '✓' : '...'),
            ],
          ),
        ),

        // 중앙 하단: 큰 카운트다운
        Positioned(
          left: 0,
          right: 0,
          bottom: 50,
          child: Column(
            children: [
              Text(
                l.statusAnalyze,
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF3D5A),
                  fontSize: 11,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$remaining',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFF3D5A).withValues(alpha: 0.7),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============ 작은 컴포넌트 ============

class _Gauge extends StatelessWidget {
  final String label;
  final double value; // 0-1
  final String rawText;
  const _Gauge({required this.label, required this.value, required this.rawText});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final color = v > 0.66
        ? const Color(0xFFFF3D5A)
        : v > 0.33
            ? Colors.orange
            : Colors.greenAccent;
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                rawText,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              widthFactor: v,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 9,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: const Color(0xFFFF3D5A),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ============ HUD painter (corner brackets + scanline + grid + vignette) ============

class _AnalyzeHudPainter extends CustomPainter {
  final double pulse; // 0-1
  final double scanline; // 0-1
  final LiveFaceFrame frame;
  _AnalyzeHudPainter({
    required this.pulse,
    required this.scanline,
    required this.frame,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 어두운 vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.1,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.55),
        ],
        stops: const [0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignette,
    );

    // 중앙 분석 영역 (얼굴 추정 박스)
    final boxW = size.width * 0.7;
    final boxH = boxW * 1.25;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final boxRect = Rect.fromCenter(center: Offset(cx, cy), width: boxW, height: boxH);

    // 코너 브래킷
    final bracketLen = 28.0;
    final bracketColor = const Color(0xFFFF3D5A).withValues(alpha: 0.6 + pulse * 0.4);
    final bracketPaint = Paint()
      ..color = bracketColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    void corner(Offset c, double dx, double dy) {
      canvas.drawLine(c, c.translate(dx * bracketLen, 0), bracketPaint);
      canvas.drawLine(c, c.translate(0, dy * bracketLen), bracketPaint);
    }

    corner(boxRect.topLeft, 1, 1);
    corner(boxRect.topRight, -1, 1);
    corner(boxRect.bottomLeft, 1, -1);
    corner(boxRect.bottomRight, -1, -1);

    // 십자선
    final crossPaint = Paint()
      ..color = const Color(0xFFFF3D5A).withValues(alpha: 0.25)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(cx - 16, cy),
      Offset(cx + 16, cy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(cx, cy - 16),
      Offset(cx, cy + 16),
      crossPaint,
    );

    // 스캔라인 (위→아래)
    final lineY = boxRect.top + (boxRect.height * scanline);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          const Color(0xFFFF3D5A).withValues(alpha: 0.7),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(boxRect.left, lineY, boxRect.width, 2));
    canvas.drawRect(
      Rect.fromLTWH(boxRect.left, lineY, boxRect.width, 2),
      scanPaint,
    );

    // 미세 그리드 점
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.05);
    final step = 24.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.6, dot);
      }
    }

    // ── 실시간 눈알 트래킹 점
    // ML Kit landmark 는 face boundingBox 기준 정규화 좌표 (0~1).
    // 분석 박스 내부에 매핑하면서 전면 카메라 mirror 보정 (좌우 반전).
    final left = frame.leftEye;
    final right = frame.rightEye;
    if (left != null || right != null) {
      Offset map(Point<double> p) {
        // 전면 카메라는 셀카 미러링 — x 를 1-x 로 뒤집어야 사용자 시선과 일치
        final nx = 1 - p.x;
        final ny = p.y;
        return Offset(
          boxRect.left + nx * boxRect.width,
          boxRect.top + ny * boxRect.height,
        );
      }

      // 깜빡임 시 색을 빨강으로 (강조)
      final eyeColor = frame.eyesClosed
          ? const Color(0xFFFF3D5A)
          : const Color(0xFF00E0FF);

      // 눈 사이 연결선 (faint)
      if (left != null && right != null) {
        final lp = map(left);
        final rp = map(right);
        final linePaint = Paint()
          ..color = eyeColor.withValues(alpha: 0.25)
          ..strokeWidth = 1;
        canvas.drawLine(lp, rp, linePaint);
      }

      void drawEye(Point<double> p) {
        final c = map(p);
        // 외곽 펄스 링
        final ringPaint = Paint()
          ..color = eyeColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(c, 14 + pulse * 6, ringPaint);
        // 내부 채운 원
        final fillPaint = Paint()..color = eyeColor;
        canvas.drawCircle(c, 5, fillPaint);
        // 십자 미세선
        final cross = Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 1;
        canvas.drawLine(c.translate(-8, 0), c.translate(8, 0), cross);
        canvas.drawLine(c.translate(0, -8), c.translate(0, 8), cross);
      }

      if (left != null) drawEye(left);
      if (right != null) drawEye(right);
    }
  }

  @override
  bool shouldRepaint(covariant _AnalyzeHudPainter old) =>
      old.pulse != pulse ||
      old.scanline != scanline ||
      old.frame != frame;
}
