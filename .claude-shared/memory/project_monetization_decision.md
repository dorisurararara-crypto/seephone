---
name: 수익 모델 결정 (2026-04-29 02:00 사용자 mandate)
description: 구독 X, 테마 단건 구매 / 광고 / 둘 다 — 자율 판단. 세부 코덱스 상의 후 결정.
type: project
originSessionId: 65198821-57e9-40a2-b42d-d1b65b6f5042
---
## 사용자 명시 (2026-04-29 02:00)

> "구독 요금제는 안쓸거고 직접 테마 구매하게할거야 아니면 광고로 수익을 벌거나 너가 알아서 직접 돈 벌수있는 구조로 만들어줘 상의할게 있으면 나 대신 codex랑 이야기해보고 무료티어안에서"

## 결정해야 할 것

1. **빡신**: 5 테마 (V1~V5). 기본 V5. Pro 게이트 → 어떻게 돈 받을지
   - A. 테마별 단건 구매 (각 ₩1,500 같은 식, in_app_purchase non-consumable)
   - B. 광고 시청으로 24h 잠금 해제 (rewarded ad)
   - C. 부적 발급 시 광고 (interstitial) + 광고 제거 단건 결제
   - D. A + C 혼합 (테마 단건 + 광고 제거 단건)

2. **pupil**: 무료 + 광고? 결과 카드 공유 후 광고? 진단 기능 단건 결제?

3. **anger**: 무료 + 광고? 보스 모드 단건 결제?

## 제약
- 구독 X (사용자 명시)
- in_app_purchase 패키지 wire 필요 (테마 단건 구매 시)
- ASC 에 IAP product 등록 — 자동화 가능 (`/v1/inAppPurchases` POST)
- AdMob 이미 wire 되어 있음 (테스트 ID)

## 결정 (codex 권고 채택, 2026-04-29 02:10)

**빡신**:
- 핵심: 무료 + 광고 + **올테마팩 1회 결제 (non-consumable IAP)**
- 가격: ₩2,900 (KRW) / $1.99 (USD)
- 광고: 결과 부적 생성 2~3회차부터 interstitial / 테마 미리보기·재뽑기 rewarded / **banner 없음**
- IAP product ID: `com.ganziman.bbaksin.theme_pack_all`

**pupil**:
- 핵심: 무료 + 광고 + **광고 제거 1회 결제 (non-consumable IAP)**
- 가격: ₩1,500 / $0.99
- 광고: 3초 스캔 후 결과 카드 직전 interstitial 1회 / 재측정 rewarded / banner 없음
- IAP product ID: `com.ganziman.pupil.remove_ads`

**anger**:
- 핵심: 무료 + 광고 + **광고 제거 1회 결제 (non-consumable IAP)**
- 가격: ₩1,500 / $0.99
- 광고: 측정 완료 후 결과 카드 interstitial / 특수 이펙트 rewarded / banner 없음
- IAP product ID: `com.ganziman.anger.remove_ads`

## 구현 작업 (체크리스트)

빡신:
- [ ] `in_app_purchase` 패키지 추가 (pubspec.yaml)
- [ ] `purchase_service.dart` 재작성 — 베타 모드 fallback + 실제 IAP 흐름
- [ ] settings_screen.dart Pro 시트 → "올테마팩 ₩2,900" 으로 변경
- [ ] 결과 화면 interstitial 광고 (3회마다 1회 등 빈도 제한)
- [ ] 테마 미리보기 rewarded 광고

pupil:
- [ ] `in_app_purchase` 추가
- [ ] purchase_service 신규 작성 (광고 제거 토글)
- [ ] 결과 화면 interstitial (광고 제거 미구매시)
- [ ] 설정/메뉴에 "광고 제거 ₩1,500" 항목

anger:
- [ ] 동일 패턴 (pupil 와 거의 동일)

ASC IAP product 등록:
- [ ] `/v1/inAppPurchases` API 로 등록 시도 — 가능하면 자율, 막히면 사용자 ASC 웹 UI

## 베타 vs 프로덕션
- **TestFlight 베타**: IAP product 가 ASC 에 등록만 되어 있으면 sandbox 결제 가능. 가격·로컬라이제이션 미완성도 sandbox OK.
- **프로덕션 출시**: 가격 + ko/en 로컬라이제이션 + 스크린샷 (non-consumable) + 심사 통과 필요.
- 베타 단계에선 "베타 기간 무료 체험" 처리도 OK (purchase_service 가 베타 빌드 감지 시 자동 unlock 가능). 출시 시점에 wire 정리.
