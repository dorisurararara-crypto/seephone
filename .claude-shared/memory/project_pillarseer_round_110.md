---
name: pillarseer-round-110
description: pillarseer R110 — 수익화 B안(첫 출시 빌드에 프리미엄팩 IAP) + App Store 정식 출시. 밤샘 자율 세션. 컨텍스트 압축 시 이 파일로 복원.
metadata: 
  node_type: memory
  type: project
  originSessionId: 13674293-ac1f-48a5-9c92-b8dc683186fd
---

# pillarseer Round 110 — 수익화 B안 + App Store 정식 출시 (밤샘 자율)

**사용자 mandate (2026-05-23 새벽)**: "알아서 앱스토어에 출시까지 해놔줘. codex랑 상의.
진짜 나만 할 수 있는 일은 검색으로 검증 후 큐로 빼고, 나머지 다 해놔." → 자는 중.

## 결정 (확정)
- **B안**: 첫 App Store 정식 출시 빌드 자체에 IAP 포함. A안(무료 먼저) fallback 자동가동 금지.
- 상품: `프리미엄팩` / Premium Pack, **non-consumable**, `com.ganziman.pillarseer.premium_pack`, **₩5,900 / $4.99**.
- 첫 출시 빌드 = **1.0.0+75**. marketing version 1.0.0 유지 (1.1.0 금지 — R101 트랩).
- 무료/프리미엄 경계 = `pillarseer/docs/operating_memory/monetization_playbook.md`.
- App Store: 전 세계 무료, 카테고리 라이프스타일+엔터테인먼트, 연령 4+.

## Sprint 진행 (codex 검수 GO 누적)
- ✅ Sprint 0 정책 문서 (commit 99a0420)
- ✅ Sprint 1 IAP 인프라 — purchase_service/premium_provider, codex 9.4 GO (commit b6ba499)
- ✅ Sprint 2 9기능 무료/프리미엄 게이트 — premium_gate, codex GO (commit 6d616f2)
- ✅ Sprint 3 프리미엄팩 paywall UX — premium_paywall, codex 9.35 GO (commit f66922f)
- ✅ Sprint 4 ASC IAP 등록 + 메타데이터 PATCH — main Claude 직접 실행, codex 검수 통과 (commit 9fc62da)
- ✅ Sprint 5 — 1.0.0+75 빌드·altool 업로드·ASC build #75 VALID·App Store version attach 완료 (commit 2b68dad). App Review 미제출.
- flutter test 1638/1638 pass / analyze 0 (info만)

## ASC 상태 (Sprint 4 완료분 — 2026-05-23 새벽)
- App Store version 1.0.0 id `2084f5bc-9577-427d-b6d7-0420cb750b31` PREPARE_FOR_SUBMISSION.
- 버전 로컬: ko + en-US — 설명/키워드/프로모/지원URL 모두 PATCH 완료.
- 앱정보 로컬: ko "필러시어 - 사주 운세 풀이" / en "Pillar Seer - Saju Fortune" + 부제 + privacyPolicyUrl.
- 카테고리 LIFESTYLE/ENTERTAINMENT. 연령등급 선언 4+ (콘텐츠 전부 NONE/false).
- **IAP id `6772283210`** com.ganziman.pillarseer.premium_pack NON_CONSUMABLE. 로컬 ko/en + 가격(USA $4.99/KOR ₩5,900, 175 territory) + availability 완료. state=MISSING_METADATA (심사 스크린샷만 남음).
- 법무 사이트 GitHub Pages 라이브: `https://dorisurararara-crypto.github.io/pillarseer-legal/` (privacy/support/terms .html).

## ⚠️ 사용자 아침 큐 (진짜 사용자만 가능 — 검색으로 확정)
1. **App Privacy**: ASC 웹 > Pillar Seer > App Privacy > Get Started > "No, we do not collect data" > Save > Publish. (API 미지원 확인됨, 웹 전용, 2분)
2. **App Store 스크린샷**: 실기기(TestFlight 1.0.0+74 설치됨)로 홈/내사주/오늘운세/궁합/전생 or paywall 캡처 → ASC App Store > 1.0.0 > 스크린샷 슬롯 업로드. (시뮬 금지 + Claude 가 앱 실측 못 봐 HTML 목업 거절리스크 → 실기기 캡처가 정답)
3. **IAP 심사 스크린샷 1장**: paywall 화면 캡처 → ASC > In-App Purchases > Premium Pack > Review Screenshot. (IAP MISSING_METADATA 해제용. API 업로드 가능 — 캡처만 주면 Claude 가 업로드)
4. **최종 제출**: 빌드 1.0.0+75 attach + 위 3개 완료 확인 후 Submit for Review.

## 워크플로
codex(GPT-5.5)=두뇌/검수, main Claude=메신저/ASC 직접 실행, 서브에이전트(opus)=코딩.
codex 호출 = /tmp 파일 Write → `codex exec --skip-git-repo-check --sandbox read-only --cd .../pillarseer < f.txt > out.txt` background.
ASC helper = `pillarseer/scripts/_helpers.rb` (APP_ID 6768096855). IAP v2 = `/v2/inAppPurchases`.
