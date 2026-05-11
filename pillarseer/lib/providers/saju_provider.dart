// Pillar Seer — 전역 상태 (사용자 사주 + 입력 정보).
// router extra 의존 제거: Bottom Nav 탭 이동 후에도 데이터 유지.
// Riverpod 3.x 의 Notifier 패턴 사용.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saju_result.dart';

/// 사용자 입력 정보 (재계산 / Profile 표시용)
class UserBirthInfo {
  final String name;
  final DateTime birthDate;
  final int birthHour;
  final int birthMinute;
  final String birthCity;
  final bool isLunar;
  final bool unknownTime;

  const UserBirthInfo({
    required this.name,
    required this.birthDate,
    required this.birthHour,
    required this.birthMinute,
    required this.birthCity,
    required this.isLunar,
    this.unknownTime = false,
  });
}

class SajuResultNotifier extends Notifier<SajuResult?> {
  @override
  SajuResult? build() => null;

  void set(SajuResult? value) => state = value;
  void clear() => state = null;
}

class UserBirthInfoNotifier extends Notifier<UserBirthInfo?> {
  @override
  UserBirthInfo? build() => null;

  void set(UserBirthInfo? value) => state = value;
  void clear() => state = null;
}

/// 사용자 사주 결과 (전역). null = 아직 입력 안 함 → /input 으로 redirect.
final sajuResultProvider =
    NotifierProvider<SajuResultNotifier, SajuResult?>(SajuResultNotifier.new);

/// 사용자 입력 정보 (전역).
final userBirthInfoProvider =
    NotifierProvider<UserBirthInfoNotifier, UserBirthInfo?>(
        UserBirthInfoNotifier.new);
