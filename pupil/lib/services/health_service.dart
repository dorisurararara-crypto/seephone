import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// HealthKit (iOS) / Health Connect (Android) 통합 — Apple Watch / AirPods Pro 3 /
/// Galaxy Watch 등에서 들어온 심박수 데이터 접근.
///
/// 우선 v1: 권한 요청 + 가장 최근 BPM + source 식별만.
/// 추후 v2: 측정 직전·직후 BPM 비교를 LieDetector 점수에 반영.
class HealthDeviceStatus {
  /// 표시용 라벨 — "Apple Watch 연동됨" / "AirPods Pro 연동됨" / "Galaxy Watch 연동됨" / "iPhone 데이터" / "연동 안 됨"
  final String label;

  /// 가장 최근 BPM 샘플 (없으면 null)
  final double? bpm;

  /// 권한 받았는지
  final bool authorized;

  /// 마지막 데이터 source name (디버그용)
  final String? rawSource;

  const HealthDeviceStatus({
    required this.label,
    required this.authorized,
    this.bpm,
    this.rawSource,
  });

  static const notLinked =
      HealthDeviceStatus(label: '연동 안 됨', authorized: false);
}

class HealthService {
  HealthService._();
  static final instance = HealthService._();

  final Health _health = Health();
  bool _configured = false;

  static const _types = [HealthDataType.HEART_RATE];
  static const _permissions = [HealthDataAccess.READ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// 권한 요청 + 가장 최근 BPM 샘플 + source 식별.
  /// 권한 거부됐으면 notLinked 반환.
  Future<HealthDeviceStatus> probe() async {
    try {
      await _ensureConfigured();
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      if (!granted) return HealthDeviceStatus.notLinked;

      // 최근 24시간 데이터 → 가장 최근 1개
      final now = DateTime.now();
      final from = now.subtract(const Duration(hours: 24));
      final points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: from,
        endTime: now,
      );
      if (points.isEmpty) {
        return const HealthDeviceStatus(
          label: '권한 OK · 최근 데이터 없음',
          authorized: true,
        );
      }
      // dateFrom 기준 최신 정렬
      points.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final latest = points.first;
      final source = latest.sourceName;
      final bpm = (latest.value as NumericHealthValue).numericValue.toDouble();
      return HealthDeviceStatus(
        label: _labelForSource(source),
        authorized: true,
        bpm: bpm,
        rawSource: source,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('HealthService.probe error: $e');
      return HealthDeviceStatus.notLinked;
    }
  }

  /// 측정 시점 직후 BPM 1개 — 본 측정 직전·직후 비교용 (build 9 에서 사용).
  Future<double?> latestBpmInLastMinutes(Duration window) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final from = now.subtract(window);
      final points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: from,
        endTime: now,
      );
      if (points.isEmpty) return null;
      points.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      return (points.first.value as NumericHealthValue)
          .numericValue
          .toDouble();
    } catch (_) {
      return null;
    }
  }

  /// source name 으로 디바이스 추정. Apple 의 source.name 은 보통:
  /// - Apple Watch 의 사용자 이름 ("승현의 Apple Watch")
  /// - "AirPods Pro" / "AirPods Pro 3"
  /// - "iPhone" / "Health" 등 fallback
  /// - Android: "Galaxy Watch", "Samsung Health" 등
  String _labelForSource(String source) {
    final s = source.toLowerCase();
    if (s.contains('apple watch') || s.contains('watch')) {
      if (s.contains('galaxy')) return 'Galaxy Watch 연동됨';
      return 'Apple Watch 연동됨';
    }
    if (s.contains('airpods')) return 'AirPods Pro 연동됨';
    if (s.contains('galaxy') || s.contains('samsung')) {
      return 'Galaxy Watch 연동됨';
    }
    if (s.contains('iphone')) return 'iPhone 데이터';
    return '$source 연동됨';
  }
}
