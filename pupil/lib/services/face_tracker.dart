import 'dart:io';
import 'dart:math';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// 실시간 얼굴 트래킹 v2 — 거짓말 단서 8가지 누적.
///
/// 연구 기반 (2024-2025 deception detection meta-analysis):
/// - saccade number/amplitude  : ML 모델에서 가장 강한 신호
/// - pupil dynamics            : LC-NA 시스템, cognitive load
/// - blink suppression / burst : masked emotion 시 ↑
/// - facial asymmetry          : 거짓말 시 좌우 표정 차이 ↑
/// - micro-expression leakage  : 100% 거짓말쟁이가 1회 이상 발생
/// 단일 신호 ≈ 56% (chance) / 결합 ≈ 76.92%.
class FaceTrackingResult {
  final double pupilJitter; // 동공/눈 좌표 표준편차 (정규화)
  final int saccadeBurst; // 큰 시선 점프 횟수
  final double gazeAversion; // 눈이 얼굴 중심선에서 벗어난 평균 거리
  final int blinkCount;
  final double blinkAnomaly; // 0~1, 정상 blink interval(2-4s) 에서 벗어난 정도
  final double facialAsymmetry; // 좌우 표정 비대칭 평균
  final double microFlicker; // smile prob 의 high-freq 분산
  final double headRotationSum;
  final double smileAvg;
  final int sampleCount;

  const FaceTrackingResult({
    required this.pupilJitter,
    required this.saccadeBurst,
    required this.gazeAversion,
    required this.blinkCount,
    required this.blinkAnomaly,
    required this.facialAsymmetry,
    required this.microFlicker,
    required this.headRotationSum,
    required this.smileAvg,
    required this.sampleCount,
  });

  bool get hasData => sampleCount > 0;
}

/// 매 프레임 노출하는 실시간 트래킹 상태 (HUD 시각화용).
///
/// 좌표는 face boundingBox 기준 normalized (0~1).
class LiveFaceFrame {
  final Point<double>? leftEye; // 정규화 좌표 (face box 기준)
  final Point<double>? rightEye;
  final bool eyesClosed;
  final double smileProbability;
  final bool faceLocked;

  const LiveFaceFrame({
    this.leftEye,
    this.rightEye,
    this.eyesClosed = false,
    this.smileProbability = 0,
    this.faceLocked = false,
  });

  static const empty = LiveFaceFrame();
}

class FaceTracker {
  FaceTracker({required this.cameraDescription});

  final CameraDescription cameraDescription;

  /// 매 프레임 갱신되는 실시간 상태 (UI 시각화용).
  final ValueNotifier<LiveFaceFrame> live = ValueNotifier(LiveFaceFrame.empty);

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  // 시계열 — 분석은 snapshot() 시점에서 일괄
  final List<Point<double>> _leftEyeSeries = [];
  final List<Point<double>> _rightEyeSeries = [];
  final List<double> _smileSeries = [];
  final List<double> _asymmetrySeries = [];
  final List<double> _gazeAversionSeries = [];

  // 깜빡임
  int _blinkCount = 0;
  bool _eyesClosed = false;
  final List<DateTime> _blinkTimes = [];

  // 머리 회전 변화
  double _headRotationSum = 0;
  double? _prevHeadX;
  double? _prevHeadY;
  double? _prevHeadZ;

  int _frames = 0;
  bool _busy = false;
  bool _disposed = false;

  Future<void> processFrame(CameraImage image) async {
    if (_busy || _disposed) return;
    _busy = true;
    try {
      final input = _toInputImage(image);
      if (input == null) return;
      final faces = await _detector.processImage(input);
      if (faces.isEmpty) return;
      _accumulate(faces.first);
    } catch (_) {
      // 단일 프레임 실패는 누적 신호이므로 무시
    } finally {
      _busy = false;
    }
  }

  void _accumulate(Face face) {
    _frames++;
    final box = face.boundingBox;
    final w = box.width;
    final h = box.height;
    if (w <= 0 || h <= 0) return;

    // ── 1) 깜빡임 + 간격 추적
    final l = face.leftEyeOpenProbability;
    final r = face.rightEyeOpenProbability;
    if (l != null && r != null) {
      final avg = (l + r) / 2;
      if (!_eyesClosed && avg < 0.4) {
        _eyesClosed = true;
      } else if (_eyesClosed && avg > 0.6) {
        _eyesClosed = false;
        _blinkCount++;
        _blinkTimes.add(DateTime.now());
      }
    }

    // ── 2) 머리 회전 변화량 (긴장 척도)
    final hx = face.headEulerAngleX;
    final hy = face.headEulerAngleY;
    final hz = face.headEulerAngleZ;
    if (hx != null && _prevHeadX != null) {
      _headRotationSum += (hx - _prevHeadX!).abs();
    }
    if (hy != null && _prevHeadY != null) {
      _headRotationSum += (hy - _prevHeadY!).abs();
    }
    if (hz != null && _prevHeadZ != null) {
      _headRotationSum += (hz - _prevHeadZ!).abs();
    }
    _prevHeadX = hx;
    _prevHeadY = hy;
    _prevHeadZ = hz;

    // ── 3) 눈 좌표 시계열 (정규화) — saccade / jitter / gaze aversion 계산용
    final le = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final re = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;

    Point<double>? leN;
    Point<double>? reN;
    if (le != null) {
      leN = Point<double>((le.x - box.left) / w, (le.y - box.top) / h);
      _leftEyeSeries.add(leN);
    }
    if (re != null) {
      reN = Point<double>((re.x - box.left) / w, (re.y - box.top) / h);
      _rightEyeSeries.add(reN);
    }

    // ── 4) 시선 회피 — 두 눈 중점이 얼굴 가로 중심(0.5)에서 벗어난 정도
    if (leN != null && reN != null) {
      final mx = (leN.x + reN.x) / 2;
      _gazeAversionSeries.add((mx - 0.5).abs());
    }

    // ── 5) 웃음 시계열 (micro-expression flicker 분석용)
    final smile = face.smilingProbability;
    if (smile != null) _smileSeries.add(smile);

    // ── 6) 얼굴 비대칭 — 좌/우 입꼬리·뺨·눈을 코 중심으로 mirror 후 차이
    if (nose != null) {
      final cx = (nose.x - box.left) / w;
      double sum = 0;
      int count = 0;

      void compare(FaceLandmarkType lt, FaceLandmarkType rt) {
        final lp = face.landmarks[lt]?.position;
        final rp = face.landmarks[rt]?.position;
        if (lp == null || rp == null) return;
        final lx = (lp.x - box.left) / w;
        final ly = (lp.y - box.top) / h;
        final rx = (rp.x - box.left) / w;
        final ry = (rp.y - box.top) / h;
        // 좌측 점을 코 기준으로 mirror → 우측과 비교
        final mirroredX = 2 * cx - lx;
        sum += sqrt(pow(mirroredX - rx, 2) + pow(ly - ry, 2));
        count++;
      }

      compare(FaceLandmarkType.leftMouth, FaceLandmarkType.rightMouth);
      compare(FaceLandmarkType.leftCheek, FaceLandmarkType.rightCheek);
      compare(FaceLandmarkType.leftEye, FaceLandmarkType.rightEye);
      compare(FaceLandmarkType.leftEar, FaceLandmarkType.rightEar);

      if (count > 0) _asymmetrySeries.add(sum / count);
    }

    // ── 7) 실시간 트래킹 상태 노출 (UI 시각화용)
    if (!_disposed) {
      live.value = LiveFaceFrame(
        leftEye: leN,
        rightEye: reN,
        eyesClosed: _eyesClosed,
        smileProbability: face.smilingProbability ?? 0,
        faceLocked: true,
      );
    }
  }

  FaceTrackingResult snapshot() {
    final pupilJitter = (_stdev(_leftEyeSeries) + _stdev(_rightEyeSeries)) / 2;
    final saccadeBurst = _countSaccades(_leftEyeSeries) +
        _countSaccades(_rightEyeSeries);
    final gazeAversion = _seriesAvg(_gazeAversionSeries);
    final asymmetry = _seriesAvg(_asymmetrySeries);
    final flicker = _highFreqVar(_smileSeries);
    final blinkAnomaly = _blinkAnomaly();
    final smileAvg = _seriesAvg(_smileSeries);

    return FaceTrackingResult(
      pupilJitter: pupilJitter,
      saccadeBurst: saccadeBurst,
      gazeAversion: gazeAversion,
      blinkCount: _blinkCount,
      blinkAnomaly: blinkAnomaly,
      facialAsymmetry: asymmetry,
      microFlicker: flicker,
      headRotationSum: _headRotationSum,
      smileAvg: smileAvg,
      sampleCount: _frames,
    );
  }

  // ── 통계 헬퍼

  double _stdev(List<Point<double>> series) {
    if (series.length < 2) return 0;
    final n = series.length;
    final mx = series.map((p) => p.x).reduce((a, b) => a + b) / n;
    final my = series.map((p) => p.y).reduce((a, b) => a + b) / n;
    var sum = 0.0;
    for (final p in series) {
      final dx = p.x - mx;
      final dy = p.y - my;
      sum += dx * dx + dy * dy;
    }
    return sqrt(sum / n);
  }

  double _seriesAvg(List<double> s) {
    if (s.isEmpty) return 0;
    return s.reduce((a, b) => a + b) / s.length;
  }

  /// 직전 프레임 대비 정규화 좌표 점프가 임계값 이상이면 saccade 1회.
  int _countSaccades(List<Point<double>> series) {
    if (series.length < 2) return 0;
    var count = 0;
    for (var i = 1; i < series.length; i++) {
      final dx = series[i].x - series[i - 1].x;
      final dy = series[i].y - series[i - 1].y;
      final d = sqrt(dx * dx + dy * dy);
      if (d > 0.025) count++; // 얼굴 너비의 2.5% 이상 점프 = saccade
    }
    return count;
  }

  /// micro-expression flicker — smile prob 의 high-freq 분산.
  /// 평균 제거 후 1차 차분 표준편차 (느린 baseline drift 제거).
  double _highFreqVar(List<double> s) {
    if (s.length < 3) return 0;
    final diffs = <double>[];
    for (var i = 1; i < s.length; i++) {
      diffs.add(s[i] - s[i - 1]);
    }
    final mean = diffs.reduce((a, b) => a + b) / diffs.length;
    var sum = 0.0;
    for (final d in diffs) {
      sum += (d - mean) * (d - mean);
    }
    return sqrt(sum / diffs.length);
  }

  /// 정상 blink interval 2-4초. 그보다 짧으면 (burst) 또는 길면 (suppression) 의심.
  double _blinkAnomaly() {
    if (_blinkTimes.length < 2) {
      // 3초간 한 번도 안 깜빡 → suppression 의심 (0.5)
      return _blinkCount == 0 && _frames > 30 ? 0.5 : 0;
    }
    final intervals = <double>[];
    for (var i = 1; i < _blinkTimes.length; i++) {
      final dt = _blinkTimes[i].difference(_blinkTimes[i - 1]).inMilliseconds;
      intervals.add(dt / 1000.0);
    }
    final avg = intervals.reduce((a, b) => a + b) / intervals.length;
    // 0.5s 이하 burst 또는 >4s suppression 둘 다 anomaly
    if (avg < 0.5) return ((0.5 - avg) / 0.5).clamp(0.0, 1.0);
    if (avg > 4.0) return ((avg - 4.0) / 6.0).clamp(0.0, 1.0);
    return 0;
  }

  // ── CameraImage → InputImage

  InputImage? _toInputImage(CameraImage image) {
    final rotation = _rotationForCamera(cameraDescription);
    if (rotation == null) return null;

    if (Platform.isIOS) {
      if (image.format.group != ImageFormatGroup.bgra8888) return null;
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } else {
      Uint8List bytes;
      int bytesPerRow;
      if (image.format.group == ImageFormatGroup.nv21) {
        bytes = image.planes.first.bytes;
        bytesPerRow = image.planes.first.bytesPerRow;
      } else if (image.format.group == ImageFormatGroup.yuv420) {
        bytes = _yuv420ToNv21(image);
        bytesPerRow = image.width;
      } else {
        return null;
      }
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: bytesPerRow,
        ),
      );
    }
  }

  InputImageRotation? _rotationForCamera(CameraDescription cam) {
    switch (cam.sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
    }
    return null;
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final w = image.width;
    final h = image.height;
    final ySize = w * h;
    final uvSize = w * h ~/ 2;
    final out = Uint8List(ySize + uvSize);

    final yPlane = image.planes[0];
    int dst = 0;
    final yRowStride = yPlane.bytesPerRow;
    for (var row = 0; row < h; row++) {
      out.setRange(dst, dst + w, yPlane.bytes, row * yRowStride);
      dst += w;
    }

    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    for (var row = 0; row < h ~/ 2; row++) {
      for (var col = 0; col < w ~/ 2; col++) {
        final uvIdx = row * uvRowStride + col * uvPixelStride;
        out[dst++] = vPlane.bytes[uvIdx];
        out[dst++] = uPlane.bytes[uvIdx];
      }
    }
    return out;
  }

  /// 누적 시계열 초기화 — baseline 측정 끝난 후 본 측정 시작 시 호출.
  void reset() {
    _leftEyeSeries.clear();
    _rightEyeSeries.clear();
    _smileSeries.clear();
    _asymmetrySeries.clear();
    _gazeAversionSeries.clear();
    _blinkTimes.clear();
    _blinkCount = 0;
    _eyesClosed = false;
    _headRotationSum = 0;
    _prevHeadX = null;
    _prevHeadY = null;
    _prevHeadZ = null;
    _frames = 0;
  }

  Future<void> dispose() async {
    _disposed = true;
    live.dispose();
    await _detector.close();
  }
}
