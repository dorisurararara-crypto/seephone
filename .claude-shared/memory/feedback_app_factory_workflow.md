---
name: 앱 공장 운영 방식 — zero-gate factory + codex 협업
description: "아이디어 → 자동 빌드 → 사용자 '출시' 한 줄 = 배포" 흐름. 막히면 codex 무료 한도 내 상의. 빌드 후 시뮬 사용자 테스트 의무.
type: feedback
originSessionId: 57bec09c-255a-4306-954d-87a055d0688c
---
사용자가 2026-04-29 명시: **"아이디어만 주면 알아서 다 만들고 사용자가 출시만 하면 바로 출시하는 거"** + **"너가 판단하는대로 가고 물어볼게 생기면 codex에게 물어보고 둘이 같이 판단해줘 (codex 무료 사용량 안에서)"** + **"앱을 다 만들었으면 codex랑 같이 오류 테스트와 사용자 입장에서 직접 시뮬레이터로 테스트"** + **"새 앱 만들 때마다 새 폴더(`~/devapp/{name}/`)"**.

**Why:** 사용자는 "아이디어 한 줄 + '출시' 한마디" 만 입력. 그 사이는 전부 자동. Apple/Google 정책상 진짜 자동 못 하는 영역(Apple 가입·2FA·AdMob 첫 권한)은 이미 1회 셋업 끝났으니, 이후 모든 신규 앱은 게이트 0개 가능 (fastlane produce + ASC API + AdMob API).

**How to apply:**

## 1. 새 앱 부팅 흐름 (zero-gate factory)

```
SPEC → SCAFFOLD → INFRA → CONTENT → ASSETS → WIRE → METADATA →
BUILD → SCREENSHOTS → E2E → SHIP-PREP → ⏸ "출시" 대기
```

- **SPEC**: LLM 으로 아이디어 → 구조화 (앱이름, 화면 3~5개, 메커닉, 수익모델 분류[컬렉션형/도구형])
- **SCAFFOLD**: `~/devapp/{name}/` 에 Flutter 보일러플레이트 + 14단계 표준 디렉토리
- **INFRA**: `fastlane produce` (ASC App 자동 생성) + ASC API (Bundle ID/외부 베타 그룹) + AdMob API (앱+광고단위 자동 생성). 모든 ID 자동 wire.
- **CONTENT**: LLM 멘트/verdict 생성
- **ASSETS**: Windows image batch (HANDOFF.md) + ElevenLabs SFX (sfx-shared 매칭 또는 신규 생성)
- **WIRE**: Flutter 코드에 자산 + 콘텐츠 + 수익모델(베타 무료 토글) 연결
- **METADATA**: LLM 으로 ASO-optimized 한/영 텍스트 + 키워드
- **BUILD**: flutter clean + pub get + pod install + 시뮬 빌드
- **SCREENSHOTS**: Maestro 자동 5사이즈(6.9"/6.5"/5.5"/12.9"/13") × 5장 = 25장 + LLM 캡션
- **E2E**: Maestro pass 까지 자동 수정 루프
- **SHIP-PREP**: IPA 빌드 + xcodebuild exportArchive + altool 업로드 + fastlane deliver(메타+스크린샷)
- **⏸ "출시" 대기**: VALID 폴링 후 트리거 대기

사용자 "출시" 트리거 → 외부 그룹 할당 + Beta Review 제출 + public link + ASC URL 보고.

## 2. codex 협업 (무료 한도 내)

- 첫 호출로 잔량 가늠. 잔량 0 이면 Claude 단독 진행.
- 같은 이슈 반복 질의는 `codex exec resume --last "..."` 또는 `codex exec resume <SESSION_ID>` (파일 재읽기 방지)
- **텍스트 only**: 스크린샷·대용량 로그 X. Mac이 1-3문장으로 요약해서 전달.
- 프롬프트에 "최소 N건 제시" 강제 (안 하면 "이슈 없음" 만 반환)
- 키 위치: `~/shadow/shadowrun/.env` `OPENAI_API_KEY`
- 로그인: `printenv OPENAI_API_KEY | codex login --with-api-key`
- sandbox 기본 read-only, 필요 시 `-c sandbox_mode="workspace-write"` + git diff 검수

## 3. 빌드 완료 후 검증 의무 (필수)

빌드가 통과해도 그것만으로 끝 아님. **반드시**:

1. **코드 리뷰** (codex 협업): diff 또는 핵심 파일 요약 → "최소 N건의 잠재 이슈 + 수정 제안" 강제
2. **시뮬 사용자 테스트**: `xcrun simctl boot` + 앱 launch + 핵심 흐름 (홈→메인 동작→결과→저장/공유) 직접 클릭 시뮬
3. **발견 이슈 자동 수정 → 재테스트 반복** (이슈 0 까지, max N회)
4. 사용자 입장에서 "이 흐름이 자연스러운가" 판단 — 어색하면 UX 수정.

## 4. 🚨 시뮬 테스트 컨텍스트 폭발 방지 (절대 룰)

이미지 token 폭발로 세션이 죽는 사고가 반복됨. 다음 룰 엄격 준수:

- **한 턴에 PNG Read 1-3장 한도** (시작·종료·결정적 장면만)
- 그 외 스크린샷은 `xcrun simctl io booted screenshot /tmp/X.png` 로 저장만 하고 **경로·md5·존재 여부만 보고** (Read 안 함)
- **검증은 텍스트 로그 우선**: `xcrun simctl spawn booted log stream --level=debug --predicate 'process == "Runner"' > log.txt 2>&1 &` → grep 으로 핵심 이벤트 추출
  - `--level=debug` 필수 (`default` 는 debugPrint 누락 — 3시간 삽질 함정 메모리)
- **큰 PNG 필요 시 다운스케일**: `sips -Z 800 input.png --out small.png` 후 Read
- 시각 검증이 정말 필요하면 사용자에게 경로 주고 직접 확인 부탁
- 긴 작업 전 **핵심 상태를 메모리에 저장**해서 세션 터져도 이어받기 가능하게

참조 메모리:
- `feedback_screenshot_token_explosion.md` (seephone)
- shadowrun develop 메모리 `feedback_simulator_screenshots.md`

## 5. 자율성 한계 (사용자 대기 큐)

진짜 사용자만 할 수 있는 일은 즉시 묻지 말고 "사용자 대기" 항목에 기록 + 그 외 작업 모두 진행 후 종합 보고. (자율 모드 메모리 `feedback_autonomous_mode.md` 따름)

진짜 사용자 액션 영역:
- Apple ID 2FA / 본인인증 (1회/평생, 이미 셋업)
- AdMob OAuth 첫 동의 + monetization scope 권한 요청 (1회)
- 큰 디렉션 변경 (앱 컨셉 자체 변경)
- AdMob `accounts.apps.create` 권한 거부 시 fallback (1회 issue)

## 6. 4~5일 셋업 → 그 뒤 영원 자동

zero-gate factory 만드는 데 4~5일:
1. Fastlane 환경 + spaceship 인증 (반나절)
2. `/ship` 슬래시 (반나절)
3. `/new-app` (`fastlane produce` + ASC + AdMob) (하루)
4. 메타데이터·스크린샷 자동화 (하루)
5. `/factory <idea>` 오케스트레이터 (2~3일)

그 뒤 신규 앱 = "아이디어 한 줄 + 출시 한마디".
