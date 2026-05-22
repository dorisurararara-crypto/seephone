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
진짜 나만 할 수 있는 일은 검색으로 검증 후 큐로 빼고, 나머지 다 해놔." → 자고 있음.

## 결정 (확정)
- **B안**: 첫 App Store 정식 출시 빌드 자체에 IAP 포함. A안(무료 먼저) fallback 자동가동 금지.
- 상품: `프리미엄팩` / Premium Pack, **non-consumable**, `com.ganziman.pillarseer.premium_pack`, **₩5,900 / $4.99**.
- 첫 출시 빌드 = **1.0.0+75**. marketing version 1.0.0 유지 (1.1.0 금지 — R101 트랩).
- 무료/프리미엄 경계 = `pillarseer/docs/operating_memory/monetization_playbook.md` (ground truth).
  무료 5카테고리·전생1편·오늘운세·궁합1개·신년총평·셀럽Top30. 프리미엄 12카테고리·전생66편·궁합심화·신년12개월 등.
  본문 절단 금지 = 카테고리 단위 잠금. "준비중 193명" paywall 금지.
- App Store: 전 세계 무료, 카테고리 라이프스타일+엔터테인먼트.

## Sprint 진행 상태
- ✅ Sprint 0 — 정책 문서화 `monetization_playbook.md` (commit `99a0420`)
- 🔄 Sprint 1 — IAP 인프라 (purchase_service.dart / premium_provider.dart / r110_purchase_service_test.dart / app.dart 부팅훅 / pubspec in_app_purchase ^3.2.3). codex 검수 7.4→8.4→9.2, REWORK 3회차(restore overlap) 진행 중. 미커밋.
- ⬜ Sprint 2 — 9기능 무료/프리미엄 게이트 적용
- ⬜ Sprint 3 — paywall UX/문구/restore 진입점
- ⬜ Sprint 4 — ASC IAP 등록 + 메타데이터/연령등급/App Privacy/카테고리 PATCH
- ⬜ Sprint 5 — 1.0.0+75 빌드 → altool 업로드 → App Review 제출

## 진짜 사용자만 가능 (큐 — 검색으로 확정)
- **Paid Applications Agreement + 은행계좌 + 세금서류** — IAP 판매 필수, ASC 웹에서 Account Holder 법적 서명. API 불가.
  계정에 이미 IAP 생성된 앱 있음(SHADOW RUN 5/이니셜전문가 1, READY_TO_SUBMIT) → 계약 한 번은 활성. 현 유효성·은행/세금 완료는 Sprint 4 IAP 생성 시도로 판정.
- Apple 2FA / 법적 실명·세금번호 입력.
- (codex 분기) IAP API 403/409/422 = 계약/은행/세금 문제면 즉시 제출 중단 + 큐 작성. 성공이면 제출까지.

## 비큐 (자율 가능) — API/자동화
IAP product 생성·메타데이터 PATCH·App Privacy·연령등급·카테고리·빌드 업로드·IAP attach·제출 실행.

## 스크린샷
codex 결정 = HTML 목업으로 실제 앱 화면 충실 재현(2.3.3 리스크 완화: 실제 구조·문구·색상, 마케팅 포스터 금지,
가짜 기능 금지). 실제 앱과 의미있게 다르면 업로드 말고 사용자 큐. 기존 실기기 캡처 있으면 우선.

## 산출물 위치
- `pillarseer/docs/operating_memory/monetization_playbook.md` — 정책 ground truth
- `pillarseer/docs/release/app_store_metadata.md` — 설명/키워드/부제 ko·en 초안
- 법무 사이트 GitHub Pages 라이브: `https://dorisurararara-crypto.github.io/pillarseer-legal/`
  privacy.html / support.html / terms.html (repo `dorisurararara-crypto/pillarseer-legal` public)

## 워크플로
codex(GPT-5.5) = 두뇌/검수, main Claude = 메신저, 서브에이전트(opus) = 코딩.
각 Sprint 후 codex 검수 (Go ≥9.3·blocker0 / Rework 자동수정 / Stop 사용자-only).
codex 호출 = /tmp 파일 Write → `codex exec --skip-git-repo-check --sandbox read-only --cd .../pillarseer < /tmp/f.txt > /tmp/out.txt` run_in_background.
ASC helper = `pillarseer/scripts/_helpers.rb` (APP_ID 6768096855). 빌드 파이프라인 = submit_b*.rb 패턴.
