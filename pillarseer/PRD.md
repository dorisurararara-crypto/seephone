# Pillar Seer PRD (Product Requirements Document)

---

## 1. 제품 비전

### 비전 한 줄
> **"5,000년 한국의 사주를 글로벌 Gen Z의 손에"**

### 미션
- K-pop·K-drama로 한국 문화에 빠진 글로벌 팬들에게 **진짜 한국 사주**를 미스테리어스하고 감성적으로 전달
- Co-Star가 서양 점성술의 Gen Z 친화 인터페이스를 만든 것처럼, Pillar Seer는 한국 사주의 글로벌 Gen Z 인터페이스를 만든다

### 차별화 포지셔닝

| | Co-Star | 기존 한국 Saju 앱 5개 | **Pillar Seer** |
|---|---|---|---|
| 디자인 | 미니멀 검정/별 | 옛날 한국풍 | **미스테리어스 다크 + 보라/별** |
| 사주 깊이 | 0 (서양 점성술) | 강함 | **강함 (오픈소스 만세력)** |
| K-pop 팬 타겟 | 0 | 0 | **메인 타겟** |
| TikTok 친화 | 약함 | 0 | **자가 운영 + 50개 콘텐츠 시리즈** |
| 영어 UX | 강함 | 약함 (번역만) | **글로벌 네이티브 UX** |

---

## 2. 타겟 사용자 페르소나

### 페르소나 1: Chloe Park (21세, 미국 캘리포니아, 대학생)
- **직업**: UCLA 사회학 전공
- **소득**: 부모 용돈 + 알바, 월 $200 가용
- **관심사**: BTS (Jimin 최애), K-drama, J-Hope vlog 시청
- **통증**: 본인의 운세 + 최애와의 궁합이 너무 궁금함
- **돈 쓰는 패턴**: BTS 굿즈에 월 $50, Spotify $10, 소액 IAP에 거부감 0
- **SNS 사용**: TikTok 4시간/일, Instagram 2시간/일
- **Pillar Seer 사용 시나리오**: TikTok에서 "Jimin's Saju" 영상 보고 다운 → 본인 사주 확인 → "Jimin과 궁합" 단건 $9.99 결제

### 페르소나 2: Elena Schmidt (32세, 독일 베를린, 마케팅 매니저)
- **직업**: 스타트업 마케팅 매니저
- **소득**: 월 €4,500, 본인 자유 가용 €1,500
- **관심사**: 자기계발, 명상, Co-Star 헤비 유저, 점성술 책 5권 보유
- **통증**: Co-Star가 진부해지기 시작, 새로운 동양 점성술 갈증
- **돈 쓰는 패턴**: 자기계발 앱에 월 €50 (Calm, Headspace 등), 심리 분석에 진심
- **SNS 사용**: Instagram 3시간/일, LinkedIn 1시간/일, TikTok 거의 안 함
- **Pillar Seer 사용 시나리오**: Instagram 광고 보고 다운 → 일생 사주 무료 후 "Wow, more accurate than Co-Star" → 월 구독 €4.99

### 페르소나 3: Mei Lin (45세, 필리핀 마닐라, 전업주부)
- **직업**: 전업주부 + 가정 사업 (홈베이킹)
- **소득**: 가족 월 ₱150,000, 본인 가용 ₱30,000
- **관심사**: K-drama 광팬 (악귀, 파묘, 환혼 시청), 가족 운세
- **통증**: 가족 건강·재물 운세, 자녀 진로 사주 궁금
- **돈 쓰는 패턴**: K-drama 굿즈, 가족 운세 사이트 단건 결제 ₱500~1,500
- **SNS 사용**: Facebook 5시간/일, YouTube 3시간/일, TikTok 1시간/일
- **Pillar Seer 사용 시나리오**: YouTube에서 "K-drama Shamanism Real" 영상 보고 다운 → 본인+자녀 사주 → 연 구독 $39.99 + 토정비결 단건 $14.99

---

## 3. 핵심 기능 명세 (5개 화면)

### 3-1. 온보딩 화면
**목적**: 사용자 출생 정보 수집 → 사주 계산 가능 상태 만들기

**입력값**:
- Name / Nickname (영문 OK, 캐릭터셋 자유)
- Birth Date (YYYY-MM-DD, 1900~2100 범위)
- Birth Time (HH:MM, "Unknown" 옵션)
- Birth City (Google Places API 또는 timezone 자유 입력)
- Calendar Type (Solar / Lunar 선택)
- Gender (Male / Female / Other / Skip — 점술 보정용 선택값)

**출력값**: `birth_profile_id`, 만세력 계산 가능 상태 → 일생 사주 진입

**로직**:
1. 입력 검증 (날짜 유효성, 도시 timezone 변환)
2. timezone 보정 (출생지 기준 → 사주 표준시)
3. 만세력 계산 (Dart 라이브러리)
4. `saju_cache` 저장 (Drift SQLite)

**주의 사항**:
- 출생 시간 모르는 경우 `unknown_time=true` → 시주(時柱) 표시 안 함
- 글로벌 타겟이므로 출생 도시 timezone 보정 필수
- 결제 트리거 없음 (이탈 방지)

### 3-2. 일생 사주 화면 (Life Reading)
**목적**: 무료 후크 — 사용자가 "와, 정확하다" 느끼게 만들어 구독/결제 유도

**입력값**: `birth_profile_id` + 사용자 사주 캐시

**출력값**:
- 4기둥 8자 (Year/Month/Day/Hour Pillars) 시각화
- 5행 분포 (목/화/토/금/수)
- 일간(Day Master) + 십성(Ten Gods)
- 카테고리별 풀이 (성격/연애/재물/직업/건강)

**로직**:
1. 만세력 → 8자 추출
2. 일간(Day Master) 결정 → 5행 balance 계산
3. 십성(十星) 분석
4. 카테고리별 콘텐츠 fragment 조합

**무료 vs 유료 분기**:
- **무료**: 성격/기질/강점/주의점 (4~6 카드, 핵심 재미)
- **유료**: 연애 상세 / 재물 / 직업 / 건강 / 10년 대운(Major Cycle) / 연운(Year Cycle)
- 결제 트리거: "Full Life Reading Unlock" — 단건 $9.99 또는 구독 포함

### 3-3. 데일리 운세 화면 (Today's Energy)
**목적**: 매일 접속 동기 → 리텐션 엔진

**입력값**: 사용자 사주 캐시 + 오늘 날짜 + locale + timezone

**출력값**:
- Today Score 0~100
- Love / Money / Work / Energy 4개 카테고리 점수
- Lucky Color (HEX 코드 + 한글 이름)
- Lucky Number (1~99)
- Lucky Direction (8방위)
- 한 줄 조언 (40~80자)

**로직**:
1. 오늘의 일진(日辰) + 월진(月辰) 계산
2. 사용자 일간/지지 vs 오늘의 천간/지지 충합형파해 분석
3. 12지 보정
4. Static text pool에서 seed 기반 fragment 조합

**무료 vs 유료 분기**:
- **무료**: 종합 점수 + 한 줄 조언 + 광고 1회
- **구독 (월 $4.99)**: 카테고리별 상세 풀이 + 내일 미리보기 + 데일리 푸시
- 결제 트리거: "상세 보기" 탭 시 페이월

**공유 기능**: 결과 카드 자동 생성 → Instagram Story/TikTok 공유 (바이럴 핵심)

### 3-4. 단건 결제 콘텐츠 (Premium Reports)
**목적**: 깊이 있는 분석 = 깊이 있는 결제

**4개 콘텐츠 타입**:

#### 4-A. 토정비결 (Annual Tojeongbigyeol) — $14.99
- **입력**: 사용자 birth profile + 연도
- **출력**: 144괘 중 1괘 + 12개월 풀이 + 연간 총평
- **분량**: 12개월 × 800자 = 약 10,000자
- **상품 ID**: `pillarseer_tojung_annual_2026`

#### 4-B. 심층 궁합 (Deep Compatibility) — $9.99
- **입력**: 사용자 birth profile + 상대 birth profile
- **출력**: 5행 궁합도 + 일간 궁합 + 지지 충합형파해 + 관계 조언
- **분량**: 약 6,000자
- **상품 ID**: `pillarseer_compatibility`

#### 4-C. 비즈니스/이벤트 택일 (Date Picking) — $9.99
- **입력**: 사용자 birth profile + 후보 날짜 5~10개 + 목적 (결혼/이사/사업/계약/여행)
- **출력**: 후보일별 길흉 점수 + 추천일 Top 3 + 회피일
- **분량**: 후보일 × 300자
- **상품 ID**: `pillarseer_datepick`

#### 4-D. 꿈해몽 (Dream Interpretation) — $4.99/회 또는 구독 무제한
- **입력**: 꿈 키워드 (영어, 자유 입력)
- **출력**: 키워드 매칭 해석 + 길흉 + 행동 조언
- **분량**: 약 500~1,000자
- **상품 ID**: `pillarseer_dream_single` / `pillarseer_dream_unlimited`

**공통 로직**:
- 결과 미리보기 15~20% 무료 공개 → 단건 결제로 전체 잠금 해제
- 결제 후 결과 영구 저장 (`paid_reports/{report_id}`) → 마이페이지에서 재열람
- 콘텐츠 fragment + 사용자 사주 + 동적 변수 조합

### 3-5. 마이페이지 (Profile)
**목적**: 구독 관리 + 결제 내역 + 설정

**기능**:
- 구독 상태 표시 (활성/만료, 다음 결제일)
- 구매 내역 (단건 결제 영구 보관)
- Birth Profile 수정 (재계산 트리거)
- 다중 프로필 (가족/친구) — Premium 한정
- 푸시 설정 (데일리 운세 시간 / 주간 요약 / 마케팅 opt-in 분리)
- 로그아웃 / 계정 삭제 / 개인정보 삭제 (GDPR/CCPA)

**로직**:
- RevenueCat entitlement 조회 → Firestore mirror 비교 → 로컬 캐시 갱신

---

## 4. 사용자 플로우

```
[앱 첫 실행]
    ↓
[Splash + Brand Animation 3초]
    ↓
[Onboarding: 이름/생년월일/시간/도시] (튜토리얼 0초)
    ↓
[일생 사주 무료 결과 — 4~6 카드]
    ↓
[탭하면 결과 카드 펼침 + 공유 버튼]
    ↓
[데일리 운세 무료 카드] ← 매일 푸시
    ↓
[상세 보기 탭] → [페이월: 월 $4.99 / 연 $39.99]
    ↓
[궁합/토정비결 진입] → [미리보기 20% + 단건 $9.99]
    ↓
[결제 후 결과 영구 보관 → 마이페이지에서 재열람]
```

---

## 5. MVP / 풀 / 글로벌 스코프

### Week 1 MVP (1주 컷, iOS/Android)
**포함**:
- 온보딩 (이름/생년월일시/도시)
- 만세력 핵심 (Dart 포팅)
- 무료 일생 사주 (4~6 카드, 60일주 × 4카테고리)
- 데일리 운세 1개 화면 (오늘만)
- 로컬 JSON 콘텐츠
- Firebase Analytics
- Splash + Brand Logo

**제외**:
- 인증 (게스트만)
- 구독/결제
- 단건 결제 콘텐츠
- 꿈해몽 대량 DB
- 다국어 (영어 only)
- 푸시 알림
- 광고

### Week 2~4 풀 (1개월)
- Firebase Auth (Email + Google + Apple)
- Firestore user profile
- RevenueCat 구독 (월/연)
- 단건 결제 4종 (토정비결/궁합/택일/꿈해몽)
- AdMob (무료 사용자 한정)
- FCM 데일리 운세 푸시
- 콘텐츠 CDN 동기화 (Firebase Storage + Remote Config)
- Crashlytics
- Amplitude 퍼널 (Week 4)
- 결과 카드 공유 기능 (Instagram Story/TikTok)

### Month 2~3 글로벌
- 영어 카피 전면 교정 (원어민 검수)
- TikTok/Insta deep link → K-pop 랜딩 플로우
- Referral code (친구 초대 시 무료 1주)
- 다국어: 영어 → 스페인어 → 일본어 → 중국어
- 지역별 가격 (US/UK/EU/JP/SEA)
- App Store/Play Store 현지화

---

## 6. 핵심 성공 지표

| 지표 | Week 4 목표 | Month 3 목표 |
|---|---|---|
| 다운로드 | 5,000 | 100,000 |
| DAU | 1,500 | 30,000 |
| D1 Retention | 35% | 40% |
| D7 Retention | 12% | 18% |
| D30 Retention | 5% | 8% |
| 월 구독 전환율 | 3% | 6% |
| 단건 결제 ARPU | $0.50 | $1.20 |
| ARPDAU | $0.10 | $0.25 |
| 월 매출 | $5K | $150K |

---

## 7. 비기능 요구사항

- **성능**: 콜드 스타트 < 2초, 사주 계산 < 500ms, 데일리 운세 로드 < 1초
- **오프라인**: 일생 사주 + 데일리 운세 캐시 (Drift SQLite)
- **개인정보**: 출생정보는 로컬 + Firestore (사용자 동의 후), GDPR/CCPA 준수
- **보안**: HTTPS only, Firestore Rules 엄격, 결제 entitlement 서버 검증 (RevenueCat webhook)
- **접근성**: WCAG 2.1 AA, 다크 모드 우선
- **다국어**: 초기 영어, Phase 2부터 다국어
