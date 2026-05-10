# 사용자 글로벌 지침 — OS 무관 (Mac + Windows 공통)

이 파일은 모든 프로젝트·모든 머신에서 항상 로드됩니다. OS-specific 항목은 같은 폴더의
`global-mac.md` / `global-windows.md` 를 함께 보세요.

## 사용자

- 이름: dorisurararara (Flutter 1인 개발자, 한국어 대화)
- GitHub: `dorisurararara-crypto`
- 연락 이메일: `dorisurararara@gmail.com`
- **Apple Developer Apple ID: `zkxmel@naver.com`** (spaceship/fastlane 인증 — 일반 이메일과 다름)

## 운영 모드

**자율 진행** — 묻기 전에 로컬 탐색·웹 검색 먼저. 진짜 사용자만 가능한 영역(Apple 2FA·신규
가입 등)만 사용자 대기 큐. 그 외 모두 자율.

막히면 codex 무료 한도 안에서 상의 (`codex exec resume --last "..."`).

## 머신 식별 (필수 — 세션 시작 시)

새 세션에서 첫 번째로:

- `uname` 출력에 `Darwin` → **Mac mini** (Flutter 빌드·iOS·TestFlight 담당)
- `$env:OS` 가 `Windows_NT` 또는 `uname` 이 없거나 `MINGW`/`MSYS` → **Windows + RTX 5070 Ti**
  (이미지 생성·로컬 AI 담당)

머신에 따라 추가 룰은 `global-mac.md` 또는 `global-windows.md` 참고.

## 앱 공장 (zero-gate factory)

신규 앱은 모두 `~/devapp/{name}/` (Mac) 또는 `%USERPROFILE%\devapp\{name}\` (Windows)
단독 폴더. 어느 디렉토리에서든:

```
/appfty <아이디어 한 줄>
```

내부 동작은 `~/.claude/commands/appfty.md` + 메모리 파일 자동 로드. 신규 앱 6분 사이클.

> 참고: `/appfty` 자체는 Mac 의 fastlane/ASC 인프라에 의존하므로 **빌드는 Mac 에서**.
> Windows 는 이미지 생성·콘텐츠 큐레이션·HANDOFF 처리 담당.

## 핵심 운영 룰 (양쪽 공통)

### 1. "불가" 단정 전 WebSearch 먼저
"안 됨/제한/실기에서만" 표현이 답변 초안에 있으면 정지 → 조사.

### 2. 서브에이전트 호출 시 "건성 금물·완전 조사·증거 첨부" 명시.

### 3. TestFlight = 항상 외부 그룹 `ganzitester`
내부 테스트 X. 사용자 "출시" = 외부 그룹 + Beta Review 자동 제출. (실제 실행은 Mac 에서)

### 4. TestFlight 외부 베타 첫 제출 메타 3종
신규 앱 첫 제출 시 빌드 VALID 라도 메타 비면 ASC 가 "제출 준비 완료"에서 멈추고 422 거절.
다음 3개 모두 채워야 심사 진입:

- `POST /v1/betaAppLocalizations` (locale ko + en-US): description, feedbackEmail
- `PATCH /v1/betaAppReviewDetails/{APP_ID}`: contactFirstName/Last/Phone/Email
  (`Seunghyeon Lee` / `+821000000000` / `dorisurararara@gmail.com` 재사용)
- `POST /v1/betaBuildLocalizations` (locale ko + en-US, 빌드별 매번): whatsNew

레퍼런스: `~/devapp/protagonist/scripts/seed_beta_meta.rb` + `seed_review_detail.rb` (Mac).
신규 앱은 APP_ID/BUILD_ID만 교체해서 그대로 사용.

### 5. 서브 머신 협업
Mac ↔ Windows 메시지 큐는 **`HANDOFF.md`**. 자세한 프로토콜은 `seephone/CLAUDE.md` 참고.
세션 시작 시 항상 `git pull` → `HANDOFF.md` 의 "## 최신" 블록에 자기 앞으로 온 요청 확인.

## 현재 살아있는 앱들

| 앱 위치 (Mac) | 상태 |
|---|---|
| `~/seephone/bbaksin` (디지털 무당) | TestFlight 외부 베타 통과, 출시 대기 |
| `~/seephone/pupil` (동공지진) | 동일 |
| `~/seephone/anger` (분노 발전소) | 동일 |
| `~/devapp/protagonist` (POV 나는 주인공, 8 모드 효과음) | 외부 베타 자동 제출 큐 |
| `~/devapp/memereport` (급식실 속보, 밈 카드 생성기) | 동일 |
| `~/devapp/initialexpert` (이니셜전문가) | 데이터 + Flutter 시뮬 작동, AdMob/풀크롤 남음 |
| `~/shadow/shadowrun` (Shadow Run 러닝 앱) | TestFlight 외부 베타, 별도 진행 |

> **GitHub repo 정책**: 앱별 단독 private repo (`dorisurararara-crypto/{name}`). 모노레포 X.
> 시크릿(.p8/.json/.jks/.env) 절대 push X.

## 이어서 하기

새 세션 시작 시 사용자가 **"체크해줘"** 또는 **"이어서"** 한 마디 → 자동으로:
1. 머신 식별 (Mac/Windows)
2. `git pull`
3. `HANDOFF.md` 확인
4. 진행 중 작업 폴링·보고 (Mac: ASC 처리 상태 / Windows: 이미지 batch 큐)

## 새 앱 트리거

```
/appfty <아이디어>
```

cookie 만료 시 fastlane 이 알아서 fail 하고 사용자에게 spaceauth 1회 안내. (Mac 측)
