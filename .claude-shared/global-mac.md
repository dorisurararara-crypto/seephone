# 글로벌 지침 — Mac 전용

`uname` = `Darwin` 일 때만 적용. 양쪽 공통은 `global.md` 참고.

## Mac 인프라 위치

| 자산 | 경로 |
|---|---|
| ASC API key | `~/.appstoreconnect/private_keys/AuthKey_JSGU6J4JN4.p8` |
| ElevenLabs · OpenAI key | `~/shadow/shadowrun/.env` |
| spaceauth cookie | `~/.fastlane/spaceship/zkxmel@naver.com/cookie` (~30일 유효, 만료 시 `fastlane spaceauth -u zkxmel@naver.com` 1회) |
| Android keystore | `~/.seephone/keystores/{app}-upload.jks` |
| 메모리 (seephone 모노레포 기준) | `/Users/seunghyeon/.claude/projects/-Users-seunghyeon-seephone/memory/` (→ `.claude-shared/memory/` 심볼릭 링크) |
| 메모리 (shadowrun) | `/Users/seunghyeon/.claude/projects/-Users-seunghyeon-Documents-develop/memory/` |
| 신규 앱 폴더 | `~/devapp/{name}/` |

## Mac 전용 운영 룰

### 시뮬 PNG Read 한 턴에 1-3장 한도
큰 PNG 는 `sips -Z 600 in.png --out small.png` 후 Read.
검증 = `xcrun simctl spawn booted log stream --level=debug` 우선.

### 시뮬 debug 빌드 후 release archive 전 `flutter clean + pod install`
altool 91169 회피.

### Mac sleep 방지
`~/.claude/settings.json` SessionStart hook 이 `caffeinate -dimsu` 자동 기동.
외부 Remote Control 끊김 방지.

### Xcode 26 altool silent fail 회피
같은 팀 비슷한 prefix bundle ID 다수 시 altool 이 잘못된 app 에 attach.
`--apple-id <numerical>` 명시 필수. 자세한 내용은 `memory/feedback_xcode26_altool_bug.md`.

## TestFlight 자동 배포 (Mac 전용)

- iOS 빌드 → altool 업로드 → 외부 그룹 할당 → Beta Review 제출 = 한 번에
- 각 앱 `scripts/_helpers.rb` 의 `APP_ID` 상수 wire 완료
- 자세한 파이프라인: `memory/reference_testflight_pipeline.md`

## 글로벌 CLAUDE.md 와의 관계

이 디렉토리(`seephone/.claude-shared/`)는 git tracked. 변경 시:
1. 어느 머신에서든 `.md` 수정
2. commit + push
3. 양쪽 머신은 부트스트랩 스크립트로 `~/.claude/CLAUDE.md` 가 이 폴더로 심볼릭 링크되어 있어
   `git pull` 만 하면 자동 반영
