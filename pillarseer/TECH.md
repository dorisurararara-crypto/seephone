# Pillar Seer Technical Architecture

> 2026-05-10 기준 패키지/라이브러리 버전. 새 세션 시 pub.dev/GitHub 최신 확인.

---

## 1. 기술 스택 결정

### Core Stack
| 카테고리 | 선택 | 버전 | 이유 |
|---|---|---|---|
| 프레임워크 | **Flutter** | 3.41.5+ | 1인 크로스플랫폼 (iOS/Android) |
| 언어 | **Dart** | 3.10+ | Null safety, Records, Patterns |
| 상태관리 | **Riverpod** | ^3.3.1 | 테스트 친화 + 컴파일 타임 안전 |
| 라우팅 | **go_router** | ^17.2.3 | 딥링크 친화 (마케팅 핵심) |
| 데이터 모델 | **freezed** | ^3.2.5 | 불변 + Union types |
| JSON | **json_serializable** | ^6.13.2 | freezed와 결합 |
| 빌드 | **build_runner** | ^2.15.0 | freezed 코드 생성 |
| 로컬 DB | **drift** | ^2.33.0 | SQLite + 타입 안전 쿼리 |

### Backend
| 카테고리 | 선택 | 패키지 | 이유 |
|---|---|---|---|
| 인증 | Firebase Auth | `firebase_auth ^6.4.0` | Email + Google + Apple 통합 |
| DB | Cloud Firestore | `cloud_firestore ^6.0.0` | NoSQL, Real-time, Rules |
| 스토리지 | Firebase Storage | `firebase_storage ^13.0.0` | 콘텐츠 CDN 배포 |
| 설정 | Remote Config | `firebase_remote_config ^6.0.0` | 페이월/실험 |
| 푸시 | FCM | `firebase_messaging ^16.0.0` | 데일리 운세 알림 |
| 분석 | Firebase Analytics | `firebase_analytics ^12.3.0` | MVP |
| 분석 | Amplitude (Phase 2) | `amplitude_flutter ^4.5.0` | 퍼널/리텐션 |
| 크래시 | Crashlytics | `firebase_crashlytics ^5.0.0` | 안정성 |

### Auth
| 패키지 | 버전 | 비고 |
|---|---|---|
| `firebase_auth` | ^6.4.0 | 이메일/비밀번호 |
| `google_sign_in` | ^7.2.0 | Google OAuth |
| `sign_in_with_apple` | ^8.0.0 | Apple OAuth (iOS 필수) |

### Monetization
| 패키지 | 버전 | 비고 |
|---|---|---|
| `purchases_flutter` | ^10.0.2 | RevenueCat — 환불/복원/검증 안전 |
| `google_mobile_ads` | ^8.0.0 | AdMob 배너 + 보상형 |

> **결정 근거 — RevenueCat 사용 이유**: StoreKit/Play Billing 직접 구현은 환불/복원/가족공유/구독 갱신 케이스가 복잡함. 1인 개발자에게 webhook + entitlement mirror 직접 짜는 건 시간/리스크 큼. RevenueCat이 그걸 다 해줌. MTR $10K 미만 무료.

### UX / Utility
| 패키지 | 버전 | 용도 |
|---|---|---|
| `flutter_animate` | ^4.5.0 | 애니메이션 DSL |
| `lottie` | ^3.1.2 | 별/달 애니메이션 |
| `cached_network_image` | ^3.4.1 | 이미지 캐싱 |
| `flutter_svg` | ^2.0.10 | SVG 아이콘 (8괘, 5행) |
| `shared_preferences` | ^2.3.2 | 가벼운 설정 저장 |
| `intl` | ^0.19.0 | 다국어/날짜 포맷 |
| `timezone` | ^0.9.4 | 출생지 timezone 변환 |
| `share_plus` | ^10.0.2 | 결과 카드 공유 |
| `screenshot` | ^3.0.0 | Insta Story 카드 캡처 |

---

## 2. 만세력 라이브러리 평가 + 추천

### 비교
| 라이브러리 | 언어 | 라이선스 | 범위 | 활성도 | 통합 |
|---|---|---|---|---|---|
| `manseryeok-js` (urstory) | TypeScript | MIT | 1000~2050 | v1.0.8 (꾸준한 버그 수정) | JS bridge or 포팅 |
| `sajupy` | Python | MIT | 1900~2100 | 활성 (옵션 풍부) | 백엔드 only |
| `manseryeok` (yhj1024) | TypeScript | MIT | 1900~2100 | 낮은 stars | 포팅 가능 |

### **추천: `manseryeok-js` 기준 → Dart 포팅**

**이유**:
1. KASI(한국천문연구원) 데이터 기반 + 절기 버그 수정 이력
2. Pure JS (DB 없음) → Dart 포팅 단순
3. MIT 라이선스 (상업 사용 OK)
4. 테스트 케이스 풍부 (검증 자료)

### 통합 절차 (Week 1)
```
Day 1-2: manseryeok-js 코드 분석 + 핵심 함수 식별
Day 3-4: Dart 패키지 생성 (`packages/pillarseer_calendar`)
         - 양력↔음력 변환
         - 60갑자 계산
         - 4기둥 8자 추출
         - 절기 계산
         - timezone 보정
Day 5: Golden test 1,000개 (manseryeok-js + sajupy 결과 비교)
Day 6: 경계 케이스 테스트 (절기 경계일, 23시 자시, leap month)
Day 7: 통합 + 첫 사주 결과 화면 연결
```

### Golden Test 전략
```dart
// test/saju_golden_test.dart
final goldenCases = [
  GoldenCase(
    birth: '1990-04-15T14:30:00',
    timezone: 'Asia/Seoul',
    expected: SajuPillars(
      year: '庚午', month: '庚辰', day: '丙戌', hour: '乙未',
      // ...
    ),
  ),
  // ... 1,000개
];

test('All golden cases match', () {
  for (final c in goldenCases) {
    final actual = SajuCalculator.calculate(c.birth, c.timezone);
    expect(actual, equals(c.expected), reason: 'Case ${c.id}');
  }
});
```

---

## 3. 프로젝트 구조

```
pillarseer/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── theme/        # 컬러 팔레트, 타이포
│   │   ├── router/       # go_router 설정
│   │   └── services/     # Firebase, RevenueCat 초기화
│   ├── features/
│   │   ├── onboarding/
│   │   │   ├── ui/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   ├── life_reading/
│   │   ├── daily_fortune/
│   │   ├── compatibility/
│   │   ├── tojung/
│   │   ├── date_pick/
│   │   ├── dream/
│   │   ├── profile/
│   │   └── paywall/
│   ├── shared/
│   │   ├── widgets/      # 재사용 UI
│   │   ├── animations/   # Lottie, flutter_animate
│   │   └── analytics/    # Firebase + Amplitude wrapper
│   └── data/
│       ├── content/      # JSON 콘텐츠 (asset)
│       └── models/       # freezed 모델
├── packages/
│   └── pillarseer_calendar/   # 만세력 Dart 패키지 (사내 라이브러리)
├── assets/
│   ├── images/
│   ├── fonts/
│   ├── animations/       # Lottie JSON
│   └── content/          # 사주 콘텐츠 JSON
├── test/
│   ├── golden/           # Saju 골든 테스트
│   ├── unit/
│   └── widget/
├── android/
├── ios/
└── pubspec.yaml
```

---

## 4. 데이터 모델

### 4-1. 사용자 모델
```dart
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String userId,
    String? email,
    String? displayName,
    required SubscriptionStatus subscription,
    required List<BirthProfile> birthProfiles, // 본인 + 가족/친구
    required PushPreferences pushPrefs,
    required DateTime createdAt,
  }) = _UserProfile;
}

@freezed
class BirthProfile with _$BirthProfile {
  const factory BirthProfile({
    required String id,
    required String name,
    required DateTime birthDateTime, // UTC 기준
    required String birthTimezone,   // e.g., 'Asia/Seoul'
    required String birthCity,
    String? gender, // 'M' | 'F' | 'O' | null
    required CalendarType calendarType, // solar | lunar
    bool? unknownTime,
  }) = _BirthProfile;
}
```

### 4-2. 사주 캐시 모델
```dart
@freezed
class SajuCache with _$SajuCache {
  const factory SajuCache({
    required String birthProfileId,
    required SajuPillars pillars,        // 4기둥 8자
    required FiveElements elements,      // 5행 분포
    required String dayMaster,           // 일간
    required List<String> tenGods,       // 십성
    required String saju60ji,            // 60갑자 (일주)
    required int algorithmVersion,       // 재계산용
    required DateTime computedAt,
  }) = _SajuCache;
}

@freezed
class SajuPillars with _$SajuPillars {
  const factory SajuPillars({
    required Pillar year,
    required Pillar month,
    required Pillar day,
    Pillar? hour, // unknownTime이면 null
  }) = _SajuPillars;
}

@freezed
class Pillar with _$Pillar {
  const factory Pillar({
    required String chunGan,  // 천간 (甲乙丙丁戊己庚辛壬癸)
    required String jiJi,     // 지지 (子丑寅卯辰巳午未申酉戌亥)
  }) = _Pillar;
}
```

### 4-3. 콘텐츠 모델
```dart
@freezed
class SajuFragment with _$SajuFragment {
  const factory SajuFragment({
    required String id,
    required String saju60ji,           // 일주 (e.g., '甲辰')
    required Category category,         // personality | love | money | career | health | yearly
    required Depth depth,               // basic | medium | deep
    required Map<String, String> texts, // 'ko' | 'en' | 'ja' | ...
    required int contentVersion,
  }) = _SajuFragment;
}

enum Category { personality, love, money, career, health, yearly }
enum Depth { basic, medium, deep }
```

### 4-4. 결제 리포트 모델 (paid_reports/{id})
```dart
@freezed
class PaidReport with _$PaidReport {
  const factory PaidReport({
    required String reportId,
    required String userId,
    required ReportType type,           // tojung | compatibility | datepick | dream
    required Map<String, dynamic> input, // birthProfile, partner, dates, etc
    required Map<String, dynamic> result, // 전체 결과
    required String contentSnapshot,    // 생성 당시 텍스트 고정
    required int contentVersion,
    required DateTime purchasedAt,
    required String productId,          // RevenueCat product ID
    required double pricePaid,
    required String currency,
  }) = _PaidReport;
}
```

### 4-5. Firestore 컬렉션 구조
```
/users/{userId}
  /profile/{birthProfileId}
  /paid_reports/{reportId}

/content/{contentVersion}
  /life_fragments/{60ji_category_depth}
  /daily_fragments/{ilji_category}
  /tojung/{gwa_month}
  /dream_keywords/{keyword}

/leaderboard (optional)
  /streaks/{userId}

/pricing/{region}
  → Remote Config로 대체 가능
```

---

## 5. 콘텐츠 데이터 구조 + 작성 계획

### 5-1. 분량 추정
| 콘텐츠 | 단위 | 수량 | 글자 수 (한국어 원문) |
|---|---|---|---|
| 일생 사주 | 60일주 × 6카테고리 × 3깊이 | 1,080개 | 1,080 × 500자 = 54만자 |
| 오행 보정 | 5오행 × 3상태 × 6카테고리 | 90개 | 90 × 200자 = 1.8만자 |
| 십성 보정 | 10십성 × 5상황 | 50개 | 50 × 300자 = 1.5만자 |
| 데일리 운세 | 10일간 × 60일진 × 4카테고리 | 2,400개 | 2,400 × 100자 = 24만자 |
| 12지 zodiac | 12지 × 365일 (선택) | 4,380개 | 4,380 × 50자 = 21.9만자 |
| 토정비결 | 144괘 × 12개월 + 144 총론 | 1,872개 | 1,872 × 400자 = 74.9만자 |
| 궁합 | 5행 × 5행 × 관계톤 4 | 100개 | 100 × 400자 = 4만자 |
| 택일 | 5목적 × 5단계 | 25개 | 25 × 200자 = 5천자 |
| 꿈해몽 | 키워드 (MVP 200, 풀 1,000) | 1,000개 | 1,000 × 300자 = 30만자 |
| **합계 (한국어)** | | **약 11,000개** | **약 213만자** |
| **영어 번역** | | | **약 280만 chars (1.3x)** |

### 5-2. MVP 콘텐츠 (Week 1)
- **일생 사주만**: 60일주 × 4카테고리 (personality/love/money/career) = **240개, 약 12만자 한국어 원문**
- 영어 번역 약 16만 chars
- 작성 방법: AI 초안 + 사용자 검수 (사주 전문가 리뷰는 Phase 2)

### 5-3. 작성 프로세스
```
Stage 1: 한국어 원문 (AI 초안)
   ↓
Stage 2: 사용자 검수 (사주 톤 + 정확성)
   ↓
Stage 3: DeepL 1차 영어 번역
   ↓
Stage 4: 영어 원어민 톤 에디팅 (Co-Star 톤 참고)
   ↓
Stage 5: JSON 변환 + 앱 통합
```

### 5-4. 톤 가이드
- **금지**: "확정 예언" — "당신은 X할 것이다"
- **권장**: "tendency", "timing", "watch for", "lean towards"
- **예시**:
  - ❌ "You will lose money this month."
  - ✅ "Watch for impulsive spending mid-month. Energy favors saving over investing."

### 5-5. 콘텐츠 배포
- **MVP (Week 1)**: 앱 내장 JSON (assets/content/)
- **Week 2+**: Firebase Storage CDN + Remote Config `content_version`
- 사용자 앱이 시작될 때 `content_version` 비교 → 새 버전 있으면 다운로드
- 본문은 압축 JSON (gzip), Firestore에는 인덱스만 (비용 절감)

---

## 6. 사주 계산 엔진 설계

### 6-1. Public API
```dart
class SajuCalculator {
  /// 사주 4기둥 계산 (메인 함수)
  static SajuResult calculate({
    required DateTime birthDateTime,
    required String birthTimezone,
    required CalendarType calendarType,
    bool unknownTime = false,
  });

  /// 일진 계산 (데일리 운세용)
  static IljinResult calculateIljin(DateTime date);

  /// 토정비결 괘 계산
  static int calculateTojungGwa({
    required SajuPillars userPillars,
    required int year,
  });

  /// 궁합 점수 계산
  static CompatibilityScore calculateCompatibility({
    required SajuPillars personA,
    required SajuPillars personB,
  });

  /// 택일 점수 계산
  static List<DateScore> calculateDatePicks({
    required SajuPillars userPillars,
    required List<DateTime> candidates,
    required DatePickPurpose purpose,
  });
}
```

### 6-2. 정확도 검증
- **Golden test 1,000개** (manseryeok-js + sajupy 교차 검증)
- 경계 케이스:
  - 절기 경계일 (입춘 시각 정확도)
  - 23:00~01:00 자시(子時) 처리 (조자시/야자시)
  - Leap month (윤달)
  - 1900년 이전 / 2100년 이후 (지원 범위 명시)
  - 출생지 timezone (UTC -12 ~ +14)

---

## 7. 인프라 비용 추정

### Firebase (월 비용)
| 서비스 | DAU 1K | DAU 10K | DAU 100K |
|---|---|---|---|
| Firestore (read/write) | $5 | $50 | $400 |
| Storage (CDN) | $1 | $10 | $80 |
| Auth | 무료 | 무료 | $20 |
| FCM | 무료 | 무료 | 무료 |
| Analytics | 무료 | 무료 | 무료 |
| Remote Config | 무료 | 무료 | 무료 |
| **합계** | **$6** | **$60** | **$500** |

### RevenueCat
- MTR $10K 미만 → 무료
- $10K 초과 → MTR의 1% (DAU 100K 시 매출 $150K → $1,500/월)

### AdMob 비용
- 무료 (광고 수익 100% 또는 70/30 split)

### 총 인프라 비용 (DAU 100K 기준)
- Firebase $500 + RevenueCat $1,500 = **$2,000/월**
- 매출 $150K 대비 1.3% (매우 저렴)

---

## 8. 핵심 기술 위험 + 완화책

### 위험 1: 만세력 정확도
**문제**: 절기 경계, 자시 처리, timezone, 태양시 보정 오류 → 사용자 신뢰 즉시 깨짐
**완화책**:
- Golden test 1,000개 (manseryeok-js + sajupy 교차)
- 경계일 별도 케이스 테스트
- 사용자 리포트 시 즉시 수정 (algorithm_version bump)
- 출시 후 1개월 사주 전문가 1명에게 검수 의뢰 ($500)

### 위험 2: 결제 entitlement 불일치
**문제**: iOS/Android 구독 갱신, 환불, 복원, 가족공유 케이스 복잡
**완화책**:
- RevenueCat 사용 (직접 구현 X)
- Firebase Function webhook으로 Firestore mirror
- 앱 시작 시 항상 entitlement 재조회
- "Restore Purchase" 버튼 항상 노출

### 위험 3: 콘텐츠 버전 관리 실패
**문제**: 같은 사용자에게 어제와 오늘 해석 로직이 달라지면 CS 증가
**완화책**:
- `algorithm_version`, `content_version` 항상 저장
- 유료 리포트는 생성 당시 텍스트 고정 저장 (`content_snapshot`)
- 무료 결과는 최신 버전으로 갱신 (사용자에게 명시)

### 위험 4: 점술 앱 정책/광고 심사
**문제**: "의학/투자/법률 결정" 같은 문구 차단 가능
**완화책**:
- 모든 카피 "조언형" 톤 (단정 X)
- 건강/재물 카테고리는 disclaimers 추가
- App Store/Play Store 심사 전 카피 사전 검토
- Apple/Google 점술 앱 가이드라인 정독

### 위험 5: 데이터 프라이버시 (출생정보)
**문제**: 출생정보 = 민감정보 → GDPR/CCPA 위반 시 벌금
**완화책**:
- Firestore Rules 엄격 (사용자 본인만 read/write)
- 계정 삭제 시 즉시 모든 데이터 삭제 (GDPR right to be forgotten)
- 익명 사용 옵션 (게스트 모드)
- 개인정보처리방침 명확

---

## 9. CI/CD

### Mac mini (빌드 머신)
- Flutter build → fastlane → ASC/Play Store
- 기존 shadowrun 인프라 재활용 (`scripts/asc/_helpers.rb`)

### Windows + RTX 5070 Ti (이미지 생성)
- ComfyUI / SDXL → 앱 아이콘, Splash, 별/달 일러스트
- HANDOFF.md로 Mac과 협업

### 자동화
- `git push` → GitHub Actions → Flutter test → Crashlytics 로그
- 1주 컷 우선이라 CI/CD는 Phase 2

---

## 10. 다국어 (i18n)

### Phase 1 (Week 1~4): 영어 only
- `flutter_localizations` + `intl`
- ARB 파일 (`lib/l10n/app_en.arb`)
- 콘텐츠 JSON에도 `texts.en` 키만

### Phase 2 (Month 2~3): 다국어 확장
- 우선순위: en → ko → ja → es → zh-CN → pt-BR
- 콘텐츠 JSON에 추가 언어 키 (`texts.ja`, `texts.es` 등)
- DeepL API 자동 번역 + 원어민 검수
- Store 메타데이터 현지화

### 다국어 Phase 2 비용
- DeepL Pro: $25/월 (50만 chars)
- 원어민 검수: 언어당 $500~1,000 (1회성)
