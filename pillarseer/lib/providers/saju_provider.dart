// Pillar Seer — 전역 상태 (사용자 사주 + 입력 정보).
// router extra 의존 제거: Bottom Nav 탭 이동 후에도 데이터 유지.
// Riverpod 3.x 의 Notifier 패턴 사용.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saju_result.dart';

/// Round 82 sprint 9 — 사용자 원본 성별 보존 (외부 review P0 #6).
///
/// `isMale` 은 사주 대운 순행/역행 계산 용 boolean 으로만 사용.
/// 원본 입력은 `gender` 필드에 male/female/other 그대로 store → K-POP 궁합 필터 등
/// 후속 surface 가 "기타" 사용자를 silent 로 남/여 중 하나로 분류하지 않도록 보존.
enum UserGender { male, female, other }

/// 사용자 입력 정보 (재계산 / Profile 표시용)
class UserBirthInfo {
  final String name;
  final DateTime birthDate;
  final int birthHour;
  final int birthMinute;
  final String birthCity;
  final bool isLunar;
  final bool unknownTime;

  /// 사주 대운 순행/역행 계산 기준 (양남 = 순행 / 음남 = 역행).
  /// Gender.other 사용자는 보조 모달에서 명시 선택한 기준이 들어감 (silent X).
  final bool isMale;

  /// Round 82 sprint 9 — 사용자 원본 성별. Gender.other 보존 보장.
  /// K-POP 궁합 등 후속 surface 에서 원본 의도가 필요할 때 참조.
  final UserGender gender;

  const UserBirthInfo({
    required this.name,
    required this.birthDate,
    required this.birthHour,
    required this.birthMinute,
    required this.birthCity,
    required this.isLunar,
    this.unknownTime = false,
    this.isMale = true,
    this.gender = UserGender.male,
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
