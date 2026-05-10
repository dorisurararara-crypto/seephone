---
name: 야간 작업 큐 (2026-04-29 02:00 시점)
description: compact + 세션 교체 시점에 진행 중이던 우선순위 작업 큐. 새 세션은 이거부터 이어받기.
type: project
originSessionId: 65198821-57e9-40a2-b42d-d1b65b6f5042
---
## 우선순위 (App Store reject 위험 큰 순)

1. **빡신 Pro 가짜 가격 제거** (`bbaksin/lib/screens/settings_screen.dart:122`, `purchase_service.dart`)
   - 현재: "월 2,900원으로 시작" 버튼 → 실제 IAP 없이 SharedPreferences flag 만 토글 → Apple/Google 100% reject
   - 베타 기간엔 가격 노출 빼고 "베타 기간 무료 활성화" 로 교체. 출시 시 in_app_purchase 패키지 + ASC product 등록은 사용자 손 필요한 작업이라 별도.

2. **anger / pupil Pro 화면 점검** — 같은 패턴 가짜 가격 있으면 동일 처리.

3. **Android release 서명 분리** (`{app}/android/app/build.gradle.kts:33`)
   - 3앱 모두 release 빌드가 debug 키 사용 중. release keystore 생성 + key.properties (gitignore) + signingConfigs 분리.

4. **ritual fallback 버튼** (`bbaksin/lib/screens/ritual_screen.dart:37`)
   - 100% 가속도계 의존. 5초 경과 시 "탭으로 진행" fade-in 버튼.

5. **3앱 영어 i18n + 설정 언어 토글**
   - `flutter_localizations` + arb (ko/en). 기본 시스템 언어 → 설정 강제 토글.
   - 빡신 멘트 1000개 ko-only → UI 문구만 영문화 (멘트 영문화는 v1.1).
   - pupil / anger 는 멘트도 영문 추가.

6. **bbaksin/anger Apple 빌드 처리 — ⚠️ 이상 상태**
   - pupil: VALID ✅ (build 1, 2026-04-28T09:16:51-07:00)
   - **bbaksin/anger: ASC API `check_build_status.rb` 에서 "빌드 없음"** — 업로드 자체 실패 또는 매우 지연. 02:00 시점 확인.
   - 새 세션 우선 액션:
     1. `bbaksin/scripts/deploy_testflight.sh` 로그 다시 확인 (altool 업로드 성공/실패 메시지)
     2. ASC 웹 UI 또는 `/v1/apps/{appId}/builds?include=preReleaseVersion` 직접 호출로 invisible 상태 빌드 검색
     3. 실패였으면 재업로드. 성공이었으면 그냥 처리 큐 대기 (24h 까지)
   - VALID 되면 → `submit_external_beta.rb` 로 Beta Review 제출.

## "출시" 트리거 (사용자 명령 대기)

사용자가 "출시" 라고 하면 즉시:
- 3앱 모두 외부 베타 그룹 ganzitester 에 빌드 할당 + Beta Review 제출
- 메타데이터 (앱 설명, 키워드, 스크린샷) 는 사용자 직접 ASC 웹 UI 로 입력 필요 (자동화 가능 영역은 다 셋업됨)

**Why:** 야간 작업이 길어서 세션 교체 / compact 발생 시 새 세션이 이 큐를 즉시 이어받아야 함.

**How to apply:** 새 세션 시작하면 이 메모리 + `HANDOFF.md` + `feedback_overnight_test_and_release.md` 읽고 1번부터 진행.
