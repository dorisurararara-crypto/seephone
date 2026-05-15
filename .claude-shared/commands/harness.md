---
description: GAN-style 3-agent harness (planner + generator + evaluator). codex 감독 9.9+ 까지 반복. 풀스택 앱 / 기능 추가 / 콘텐츠 정제 모두 대응.
---

# /harness — GAN-style 3-agent harness 발동

> **사용법**: `/harness <작업 idea 1-4문장>` — 풀스택 앱 / 큰 기능 추가 / 콘텐츠 정제 모두 OK.
> 예: `/harness pillarseer 60일주 phrase 변주 Round 71` / `/harness 한국 MZ 중학생용 K-POP 미니게임 앱`

**입력 idea:** $ARGUMENTS

(1-4 문장. 비면 사용자에게 한 줄 요청. 4 문장 초과면 그대로 planner 에 넘김.)

### 실행 순서 (high-level)

```
$ARGUMENTS empty check
   │
   ├─ empty → 사용자 한 줄 질문 ("어떤 작업 / 어떤 앱? 1-4 문장 부탁드려요.") → STOP (재호출 대기)
   │
   └─ 있음 → §0 환경 인식 → §1 planner → §2 generator (§3 evaluator 내부 호출) → §4 보고 → §5 메모리
```

empty check 통과 못 하면 §0 절대 시작 X.

> **하네스 단순화 원칙 (Anthropic)**: 모델 강해질수록 비계 제거. 이 스킬은 Opus 4.7 (1M context) 기준. context anxiety 적음 → 분해보다 일관 세션, compaction-only 으로 충분.

### 데이터 흐름 (한 줄 다이어그램)

```
user idea
   │
   ▼
[main agent] (배분만, 코드 X)
   │ spawn
   ▼
[planner Opus] ──spec→ /tmp/plan_<slug>.md
   │
   ▼
[main agent] (path 만 전달, full read X)
   │ spawn
   ▼
[generator Opus] ──contract→ /tmp/sprint_<n>_contract.md
   │            ──code→ <repo files> + git commit
   │            ──audit prompt→ /tmp/audit_<round>.txt
   │            ▼
   │       [codex evaluator] ──PASS/FAIL→ stdout
   │            ▲
   │            └─ FAIL → FIX → 재호출 (최대 7 round)
   │
   ▼ final dict
[main agent] ──요약→ user
              ──memory→ ~/.claude/.../project_<slug>_round_<N>.md
```

파일이 에이전트 간 ground truth. 메인은 path 만 옮긴다 (컨텍스트 절약).

---

## 사용자 mandate (절대 룰)

1. **사용자 = 의사 결정자** (구현 X — 결정만)
2. **메인 에이전트 (Claude main) = orchestration 만** — task 배분 / 환경 확인 (§0 shell) / 사용자 보고 (§4) / 메모리 기록 (§5) OK. **앱 코드/구현/파일 직접 작성 X** (그건 generator 책임)
3. **서브에이전트 (Opus 4.7) = 실제 구현** (planner spec 작성 + generator 앱 코드 작성)
4. **codex CLI = evaluator 감독관, 매 task 9.9+ 받을 때까지 반복**
5. **TestFlight = 사용자 명시 X 면 절대 배포 X**

이 5개 위반 = 작업 abort.

---

## 0. 환경 인식 (5초 — 첫 단계, skip 금지)

다음 순서로 확인:

```bash
# 1. 머신 식별
uname            # Darwin → Mac (Flutter/iOS/TestFlight) / 그 외 → Windows

# 2. cwd 가 seephone 안이면 git pull + HANDOFF 확인
[[ -d /Users/seunghyeon/seephone/.git ]] && git -C /Users/seunghyeon/seephone pull --rebase 2>&1 | tail -5
[[ -f /Users/seunghyeon/seephone/HANDOFF.md ]] && head -40 /Users/seunghyeon/seephone/HANDOFF.md

# 3. codex 인증 mode (필수)
cat ~/.codex/auth.json | head -3
#   "auth_mode": "chatgpt"  → OK
#   "auth_mode": "apikey"   → 즉시 사용자에게 알리고 codex 호출 STOP. 사용자 한 줄: codex logout && codex login
```

### 메모리 빠른 스캔 (10초)

`~/.claude/projects/-Users-seunghyeon-seephone/memory/MEMORY.md` 인덱스만 Read. 작업 idea 와 keyword 매치되는 1-3개만 추가 Read. (한 번에 PNG 1-3장 한도 — 메모리는 텍스트라 OK.)

### Aborting (사용자 알림 필요)

- `codex auth_mode` 가 `apikey` → "ChatGPT Pro 모드 X. `codex logout && codex login` 후 재실행" 한 줄 보고 후 STOP.
- `uname` Windows + 작업이 Flutter iOS → "이건 Mac 에서. HANDOFF.md 로 넘겨드릴까요?" 한 줄.
- `cwd` 가 seephone 안인데 git 충돌 → 사용자 한 줄.

그 외 모두 자율 진행.

---

## 1. 단계 1 — Planner (Opus 서브에이전트 spawn)

### 호출 방식

`Agent` tool (Task tool) 로 `subagent_type=general-purpose`, `model=opus` 호출. **메인 에이전트는 코드 X — 배분만.**

### Planner 에게 전달할 prompt 전체

```
당신은 product spec planner. 사용자 idea 를 받아 완전 명세로 확장.

## 사용자 idea (1-4 문장)
{$ARGUMENTS}

## 사용자 페르소나 (서비스 사용자 = 디폴트)
- 한국 MZ 중학생 K-POP 팬
- 직설 친근 해요체, 한자 jargon X
- 의료·법률 단정 X, 점 보는 듯한 mystic 톤 X
- "당신은 X 같은 사람이에요" 패턴 OK
- 금지 패턴: "본인의 결은" / "흐름이" / "K팝 센터처럼" / 직장인 jargon

## 사용자 환경 (개발자 = 1인 Flutter)
- Mac mini (Darwin) Flutter 빌드·iOS·TestFlight 담당
- 신규 앱: `~/devapp/{name}/` 단독 (monorepo X)
- 기존 앱: `~/seephone/{bbaksin,pupil,anger}` / `~/devapp/{protagonist,memereport,initialexpert,pillarseer}`
- Bundle prefix: `com.ganziman.{name}`
- ASC Team: `Q6H9HCTK6W` / ASC API key: `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8` (실제 KEY_ID 는 메모리 `reference_seephone_ids.md` 참고 — placeholder 로 처리, 스킬 prompt 안에 평문 노출 X)

## 결과 제약 (Anthropic 패턴 — 경로는 generator 결정)
- 제품 컨텍스트 (무엇·왜·누구)
- 높은 수준 기술 설계 (Flutter / Dart / 데이터 구조 / 패키지 후보)
- 결과 제약 (산출물 list, 테스트 가능한 행동 = user story)
- AI 기능 자연 녹임 기회 (있으면 — gemini/openai 호출 또는 룰베이스 LLM-like)
- 디자인 톤 (한국 MZ K-POP 팬 페르소나에 맞는 색·타이포·레이아웃 hint)
- NON-GOAL list (이번 라운드에서 안 하는 것)

## 결과물
`/tmp/plan_<slug>.md` 에 저장 (slug = idea 영문 식별자).
파일 끝에 "Sprint Outline (5-10)" 섹션 — generator 가 sprint 단위로 쪼개 작업할 수 있게 testable user story 형태로.

## 절대 금지
- 코드 작성 (planner 단계는 명세만)
- 구현 경로 (파일명·함수명) 강제 — generator 가 작업하며 찾는다
- 사용자 페르소나 위반 톤

저장 끝나면 spec 파일 path 만 반환. 한 줄 요약 (60자 이내) 추가.
```

### Planner 결과 처리

- planner 반환값에서 spec 파일 path 추출
- 메인 에이전트는 spec full read X (컨텍스트 절약)
- 사용자에게 한 줄 보고: "✅ planner: spec 작성됨 ({path}) / {요약}"

### Planner 실패

- spec 파일 부재 / 60자 요약 부재 → 사용자에게 한 줄 묻기 ("idea 가 너무 추상? 1-2 문장 추가 부탁드려요.")
- 자동 재시도 X (사용자 확인 후 재호출).

---

## 2. 단계 2 — Generator (Opus 서브에이전트 별도 spawn)

### 호출 방식

`Agent` tool 로 **새로운 spawn** (planner 와 분리). `subagent_type=general-purpose`, `model=opus`.

### Generator 에게 전달할 prompt 전체

```
당신은 product implementer. spec 파일을 읽고 sprint 단위로 구현. 매 sprint 끝마다 codex evaluator 호출 → 9.9+ PASS 까지 반복.

## 입력
- spec 파일: {planner 가 반환한 path}
- 사용자 idea: {$ARGUMENTS}

## 사용자 mandate (절대 룰)
1. 한 번에 일관 세션 (Opus 4.7 — 분해 X, compaction 만 사용)
2. 매 sprint 전 **스프린트 계약 (Sprint Contract)** 작성:
   - 사용자 스토리 1줄 ("X 가 Y 할 수 있다")
   - testable 행동 1-3개 (`flutter analyze` 0 error / `flutter test` N/N pass / **이미 부팅된 시뮬에서만 launch 확인 — 새 시뮬·에뮬 부팅 금지**)
   - 산출물 list (변경 파일 path)
   - 계약 → `/tmp/sprint_<n>_contract.md` 저장 (**파일 저장만 — codex pre-audit X**)
   - 계약 = generator 의 self-binding (코드 작성 중 scope creep 방지 용)
   - codex audit 은 sprint 끝 (staged diff 후) 1회만. 계약은 그때 audit prompt 에 첨부 (codex 가 "계약 vs 실제 변경" 일치 확인)
3. 코드 작성 (Flutter / Dart, 필요시 Python/script) — **변경된 파일은 stage 만, commit X (아직)**
4. 자체 검증: `flutter analyze` 0 error, `flutter test` (있으면)
5. **stage 단계 시크릿 가드 — 2단 (commit 전 필수)**:
   ```bash
   # 박을 파일만 명시적으로 stage (`git add -A` 절대 X)
   git add <specific files>

   # 1단: 파일명 가드 (staged 한 파일들)
   git diff --cached --name-only | tee /tmp/staged_names_<sprint>.txt
   grep -E "asc_api_key|\.p8$|\.jks$|key\.properties|\.env|AuthKey_|service_account" /tmp/staged_names_<sprint>.txt && echo "SECRET FILE LEAK — STOP" && exit 1

   # 2단: 콘텐츠 가드 (staged diff 안에 시크릿 string)
   git diff --cached | grep -E "AuthKey_[A-Z0-9]{10}|sk-[A-Za-z0-9]{20,}|BEGIN (RSA |EC )?PRIVATE KEY|service_account.*private_key|aws_secret|ghp_[A-Za-z0-9]{30,}" && echo "SECRET STRING LEAK — STOP" && exit 1
   ```
   1단 + 2단 둘 다 통과 = OK. 한쪽이라도 hit = STOP + secret_leak halt dict 반환.
   의도와 무관한 파일 (`build/` `ios/Pods/` `.DS_Store` 등) 도 stage X.

6. **codex evaluator 호출 (staged diff 기반 — commit 전)** — § 3 패턴
7. evaluator FAIL → FIX 적용 → 재 stage → 재 audit. PASS 9.9+ 까지 (최대 7 라운드).
8. **PASS 후 비로소 `git commit -m "..."`** — 실패 history 가 commit log 에 남지 X.
9. 모든 sprint 끝나면 최종 보고 (위 dict schema 반환)

> **commit-audit 순서 핵심**: stage → 가드 → audit (staged diff) → PASS 면 commit. FAIL 면 staged 상태에서 FIX 적용 (commit 미생성). 운영 risk = git history 오염 X.

## 톤 (한국어 콘텐츠일 때)
- 직설 친근 해요체, 한자 jargon X
- 페르소나 = 한국 MZ 중학생 K-POP 팬
- 금지 패턴: "본인의 결은" / "흐름이" / "K팝 센터처럼" / 시적 모호함 / 의료 단정

## 사용자 환경 (검증된 패턴)
- 신규 앱: `flutter create --org com.ganziman --project-name {name} --platforms ios,android {name}` (cwd `~/devapp/`)
- 기존 앱 수정: 해당 디렉토리 (`~/seephone/...` 또는 `~/devapp/...`)
- 시크릿 commit X: `.p8` `.env` `*.jks` `key.properties` `fastlane/asc_api_key.json`
- 검증 = `flutter analyze` + (있으면) `flutter test`
- 시뮬 launch 는 사용자 명시 X 면 자동 X (이미 부팅된 시뮬은 OK)

## 절대 금지 (이 룰 위반 = abort)
- **TestFlight 배포 X** (사용자가 명시적으로 "배포해" / "출시" 말 안 했으면 절대 X)
- 시뮬·에뮬레이터 새로 부팅 X (사용자 환경 freeze 위험)
- 시크릿 push X
- 사용자 페르소나·톤 위반

## codex evaluator 호출 패턴 (stdin pipe — 검증된 방식)
```bash
python3 << 'PY' > /tmp/audit_sprint_<n>.txt
print("""<§ 3 의 template 중 작업 유형에 맞는 거 copy>""")
PY
cat /tmp/audit_sprint_<n>.txt | codex exec - 2>&1 | tail -60
```
> 큰 prompt 를 `$(cat ...)` 로 codex 에 넘기면 hang. 반드시 stdin pipe.

## 결과 형식
각 sprint 끝마다 다음 line 한 줄 append `/tmp/sprint_log.md`:
`Sprint <n>: PASS 9.9+ (A X / B X / C X / D X) — <변경 파일 수>개, commit <hash>`

전체 끝나면 다음 dict 반환 (메인 에이전트가 path 만 옮기는 path-only 원칙 준수 — spec full read X 위해 memory_why/remaining_non_goals 포함):

```yaml
sprints_total: <int>
codex_audits_total: <int>              # 전체 codex audit 호출 횟수
avg_codex_rounds: <float>              # sprint 당 평균 audit 라운드
final_codex_score:                     # 마지막 sprint
  overall: <float>                     # ≥9.9
  A: <float>
  B: <float>
  C: <float>
  D: <float>
changed_files: [<path>, ...]           # 10개 이내, 초과 시 "...외 N개"
verification:
  flutter_analyze: "0 error" | "<n> error"
  flutter_test: "<n>/<n> pass" | "테스트 없음"
commits: [<hash>, ...]
screenshots: [<path>, ...]             # 있으면, 없으면 []
testflight_status: "미배포 (mandate)"
memory_why: "<spec 의 제품 컨텍스트 1-2 문장 — generator 가 spec 읽어 요약>"
remaining_non_goals: [<항목>, ...]    # spec 의 NON-GOAL 중 이번에 안 한 것
hero_line: "<핵심 결과 한 줄 — 사용자 화면용>"
```

> 이 schema 덕분에 메인 에이전트는 spec/코드 직접 read 없이 §4 보고 + §5 메모리 작성 가능.

### 실패 / 중단 dict schema — main halt / generator halt 분리

**main halt (§0~§1 단계 — generator spawn 전 또는 직후 spec 검증 실패)** — generator 가 sprint 진입 못 하고 중단:
- `codex_auth_apikey` (codex login 모드 확인 실패)
- `git_pull_conflict` (seephone monorepo pull 실패)
- `wrong_machine` (Mac 작업인데 Windows 또는 반대)
- `arguments_empty` (사용자 idea 미입력)
- `planner_spec_invalid` — 검증 주체 분리:
  - **main 검증 (path-only)**: 파일 존재 + path 반환 + 60자 요약 반환. 셋 중 하나라도 부재 → 이 단계에서 halt
  - **generator 검증 (형식)**: spec 본문 형식 (Sprint Outline / Result Constraint / NON-GOAL 섹션 존재 여부) — generator 가 첫 sprint 진입 직후 spec 읽고 검증, 위반 시 같은 halt_reason 으로 dict 반환

이 경우 generator sprint 진입 X. 메인이 사용자에게 한 줄 보고 후 STOP.

**generator halt (§2 sprint 진행 중)** — generator 가 dict 반환:

```yaml
status: "halted"
halt_reason: "sprint_same_round_max_fail" | "sprint_accumulated_block" | "new_direction_detected" | "spaceauth_expired" | "secret_leak" | "git_conflict_mid_sprint"
halted_at_sprint: <int>                # 어디까지 갔나
codex_audits_total: <int>
last_codex_score:
  overall: <float>
  A: <float>
  B: <float>
  C: <float>
  D: <float>
remaining_fix: [<str>, ...]            # 마지막 라운드 의 FIX list (사용자가 결정)
changed_files: [<path>, ...]           # 부분 작업 했으면
commits: [<hash>, ...]                 # 부분 commit 있으면
testflight_status: "미배포 (mandate)"
next_action_for_user: "<한 줄 — 사용자가 결정해야 하는 것>"
```

**중단 조건 분리 (사용자 mandate 정합)**:
- `sprint_same_round_max_fail` = 동일 sprint 안에서 evaluator 가 7 라운드 모두 FAIL (sprint 자체 막힘)
- `sprint_accumulated_block` = 서로 다른 sprint 가 누적 5개 진행됐는데 1 sprint 도 PASS 못 함 (방향 자체 문제)
- 두 조건 OR — 어느 쪽이든 hit 하면 generator halt 반환

메인 에이전트는 generator halt dict 받으면 §4 보고 형식을 "halt" 모드로 출력 (남은 FIX list + next_action_for_user 노출).

## 한계 처리 (둘 중 하나 hit = halt dict 반환)
- **sprint_same_round_max_fail**: 동일 sprint 안에서 evaluator 7 라운드 모두 FAIL — sprint 번호와 무관하게 즉시 halt
- **sprint_accumulated_block**: 5 sprint 누적 진행했는데 1 sprint 도 PASS 못 함 (방향 자체 문제)
- spec 의 NON-GOAL 침범 발견 시 → `new_direction_detected` halt
```

### Generator 결과 처리

- 반환 dict 받아 사용자 보고 (다음 § 4 참고)
- 메인 에이전트는 generator 가 만든 파일 직접 Read X — 사용자에게 path 만 전달

---

## 3. 단계 3 — Evaluator (codex CLI, generator 내부에서 호출)

### 채점 기준 3 template (작업 유형별)

**[A] 풀스택 앱 빌드 / 큰 기능 추가**

```
당신은 한국 MZ 중학생 K-POP 팬 페르소나의 codex 감독관. 다음 산출물을 4 dimensions 로 평가:

## A. 디자인 품질 (가중치 高, 0-10, hard ≥9.0)
- 일관성 (색/타이포/간격 시스템)
- 분위기 (페르소나 적합)
- Anthropic Aesop 패턴 (미감 의식적 결정)

## B. 독창성 (가중치 高, 0-10, hard ≥9.0)
- AI 슬롭 피함 ("흰 카드 + 보라 그라데이션" / 등록 X 폰트 + 회색 placeholder / 무의미 emoji 등)
- 맞춤 디자인 (1등 앱 단순 복제 X)
- 차별화 시그니처

## C. 기술 완성도 (가중치 中, 0-10, hard ≥8.5)
- 타이포 계층 (1-3 level)
- 간격 (4/8/12/16 등 system)
- 대비 (WCAG AA 이상)
- 상태 처리 (loading/empty/error)

## D. 기능성 (가중치 中, 0-10, hard ≥8.5)
- 사용성 (페르소나가 추측 없이 작업 완료)
- spec NON-GOAL 침범 X
- 검증 통과 (analyze/test)

## 평가 대상
{generator 가 변경한 파일 list + key snippet}

## 결과 형식
PASS 9.9+ (A {x} / B {x} / C {x} / D {x})
또는
FAIL {종합점수}, FIX:
1. ...
2. ...

종합 = A*0.3 + B*0.3 + C*0.2 + D*0.2 (가중평균, 디자인+독창성 高).
**PASS 조건 (둘 다 충족)**: (1) 모든 dimension 의 hard threshold 통과 (2) 종합 가중평균 ≥9.9. 둘 중 하나라도 미달 = FAIL.
```

**[B] 콘텐츠 정제 (사주/한국어 본문/멘트)**

```
당신은 한국 MZ 중학생 K-POP 팬 페르소나의 codex 감독관. 다음 콘텐츠를 4 dimensions 로 평가:

## A. 직설 친근 톤 (가중치 高, 0-10, hard ≥9.5)
- 해요체 일관
- 한자 jargon X (예: "본질" / "결" / "정수" / "운기" / "기운" 등 점쟁이체 X)
- 의료 단정 X
- 가독성 (한 호흡에 읽힘)

## B. AI 어색 표현 없음 (가중치 高, 0-10, hard ≥9.5)
- 반복 phrase X ("X 처럼 Y 한 사람" 패턴 5회 이상 X)
- 시적 모호함 X ("흐름이" / "결이" / "센터처럼" 등)
- 비유 남용 X (K-POP 비유 1회/문단 이상 X)
- "본인의" / "당신의 흐름은" 류 AI tic X

## C. 페르소나 적합 (가중치 中, 0-10, hard ≥9.0)
- 중학생이 봐도 이해
- 직장인 jargon X ("PT" / "리텐션" / "퍼포먼스" 등)
- K-POP 팬 어휘 자연 (강요 X)

## D. 종합 (가중치 中, 0-10, hard ≥9.0)
- 사용자 mandate 만족 ("PASS 9.9+ 라운드 누적" 패턴)
- 일관성 (앞뒤 모순 X)

## 평가 대상
{변경 phrase list — 최대 30개 sample}

## 결과 형식
PASS 9.9+ (A {x} / B {x} / C {x} / D {x})
또는
FAIL {종합점수}, FIX:
1. line {N}: "..." → "..." 류
2. ...

종합 = A*0.35 + B*0.35 + C*0.15 + D*0.15 (가중평균, 톤·AI 어색 없음 핵심).
**PASS 조건 (둘 다 충족)**: (1) 모든 dimension 의 hard threshold 통과 (2) 종합 가중평균 ≥9.9. 둘 중 하나라도 미달 = FAIL.
```

**[C] 기능 추가 (UI + 로직 — pillarseer / protagonist 패턴)**

```
당신은 codex 감독관. 다음 기능 변경을 4 dimensions 로 평가:

## A. 차별화 (가중치 高, 0-10, hard ≥9.0)
- 단순 1등 앱 복제 X
- 시그니처 보존 (예: pillarseer 60일주 deep slice 840 / 자미두수 융합 / 6각 radar)

## B. 깊은 데이터 보존 + UI 압축 (가중치 高, 0-10, hard ≥9.0)
- 백엔드 fields 손실 X
- UI 는 핵심 1-3개 그룹화 (over-load X)

## C. codex 9.9+ PASS 톤 유지 (가중치 中, 0-10, hard ≥9.5)
- 직설 친근 해요체
- AI 슬롭 X
- 페르소나 일관

## D. 검증 (가중치 中, 0-10, hard ≥9.0)
- analyze 0 error
- test N/N pass (있으면)
- git commit log clean (변경 의도 명확)

## 평가 대상
{변경 파일 diff + key snippet}

## 결과 형식
PASS 9.9+ (A {x} / B {x} / C {x} / D {x})
또는
FAIL {종합점수}, FIX:
1. ...

종합 = A*0.3 + B*0.3 + C*0.2 + D*0.2 (가중평균, 차별화·데이터 보존 高).
**PASS 조건 (둘 다 충족)**: (1) 모든 dimension 의 hard threshold 통과 (2) 종합 가중평균 ≥9.9. 둘 중 하나라도 미달 = FAIL.
```

### "AI 슬롭" 명시 페널티 list (3 template 공통)

evaluator prompt 끝에 다음 추가:

```
## AI 슬롭 패턴 (발견 시 자동 -1.0 점)
- "흰 카드 + 보라 그라데이션" (UI)
- 등록 X 폰트 + 회색 placeholder
- 무의미 emoji 박기 (✨ 🎯 💫 등 의미 X)
- "본인의 결은" / "흐름이" / "센터처럼" (콘텐츠)
- 의료 단정 ("이 사람은 X 병이 있어요")
- 직장인 jargon ("리텐션 잡기" / "퍼포먼스" 등)
- 반복 phrase 5회 이상 (다양성 부족)
- Apologetic AI 어조 ("죄송하지만" / "단정 짓기 어렵지만")
```

### few-shot 보정 (evaluator 회의적 튜닝)

매 template 끝에 1-2개 예시 추가:

```
## 보정 예시
- "당신은 K팝 센터처럼 사람들 시선을 끄는 사람이에요" → 9.2 → FAIL (K팝 센터 비유 = AI 슬롭)
- "친구 사이에서 분위기 메이커 역할이 많아요" → 9.7 → FAIL (개별 dimension 은 통과지만 종합 <9.9 → FAIL)
- "친구 사이에서 분위기 메이커 역할이 많고, 모임 정하면 늘 먼저 약속 잡는 편이에요. 한 번 빠지면 다들 허전해해요." → 9.92 → PASS
```

### "평가 대상" 을 codex 에 어떻게 넘기나 (필수 패턴)

evaluator 가 코드를 보지 못하면 평가 불가능. **commit 전 staged diff 가 ground truth** (§2 의 commit-audit 순서 — audit PASS 후만 commit).

```bash
# === sprint 진행 중 (commit 전) ===
# 1. staged 변경 요약
git diff --cached --stat | tee /tmp/diff_stat.txt

# 2. 핵심 staged 파일 diff (큰 파일은 일부만)
git diff --cached -- lib/main.dart lib/services/foo.dart | head -150 > /tmp/diff_key.txt

# 3. 콘텐츠 정제면 변경 phrase sample
#    (변경된 JSON entry 30개 sample 추출 — jq + git show :file)

# 4. audit prompt 에 박기:
#    "## 평가 대상" 아래 cat /tmp/diff_stat.txt + cat /tmp/diff_key.txt

# === FAIL 후 재시도 ===
# FIX 적용 → git add <files> → 다시 1번부터 (re-stage 후 re-audit)
# commit 미생성 → history 오염 X

# === audit PASS 후 commit ===
# git commit -m "..."  (이때만 비로소 commit)

```

> **기본 패턴 = staged diff `git diff --cached`.** 위 박스 안 모든 audit 호출은 staged 기반.

---

#### (별도 — 거의 안 씀) PASS 후 sprint 간 비교 audit

여러 sprint 가 모두 PASS 했고 사용자 명시로 "sprint 간 일관성 다시 봐줘" 요청 받은 경우만:

```bash
# 이건 generator 의 일반 routine 아님. 사용자 요청 시에만.
git diff HEAD~<n> HEAD  # 이미 commit 된 변경 비교
```

기본 sprint 진행 중 audit 은 절대 이 패턴 X — staged diff 만 사용.

### codex CLI 호출 (검증된 stdin pipe)

```bash
# 1. prompt 를 임시 파일로 저장 (heredoc 직접 codex 에 pipe 하면 큰 prompt 시 hang)
python3 << 'PY' > /tmp/audit_<round>.txt
print("""<위 template 중 작업 유형에 맞는 거>

## 평가 대상
""")
import subprocess
print(subprocess.check_output(['git', 'diff', '--cached', '--stat']).decode())  # staged stat (commit 전)
print("---")
print(subprocess.check_output(['git', 'diff', '--cached']).decode()[:8000])  # staged diff 8KB cap
print("""

## 결과 형식
PASS 9.9+ (A {x} / B {x} / C {x} / D {x}) — 한 줄 강점
또는
FAIL {종합점수}, FIX:
1. ...
2. ... (최대 5개)
""")
PY

# 2. stdin pipe 로 codex 호출 (tail 60-80 으로 잘라 결과만)
cat /tmp/audit_<round>.txt | codex exec - 2>&1 | tail -80

# 3. 결과에서 PASS 또는 FAIL parse
#    PASS 9.9+ 발견 → 종료
#    FAIL → FIX list 적용 → 다시 1번부터
```

> `codex exec "..."` (인자로 전달) X — 큰 prompt hang. 항상 stdin pipe.
> `codex exec resume --last "추가 의견"` 도 같은 패턴 — stdin pipe 가 안전.
> diff 가 8KB 초과면 핵심 파일만 골라 분할 audit (한 라운드에 한 파일).

---

## 4. 단계 4 — 최종 보고 (메인 에이전트 → 사용자)

generator 가 반환한 dict 기반. 사용자 화면에 다음만 노출 (코드 dump X, 사용자 컨텍스트 절약):

```
✅ /harness 완료 — {idea 한 줄}

라운드: {N} sprint × {평균 codex round} = 총 {M} codex audit
최종 점수: PASS 9.9+ (A {x} / B {x} / C {x} / D {x})

변경 파일 ({개수}):
- path/to/file1.dart
- path/to/file2.dart
- ... (10개 초과 시 "...외 N개")

검증:
- flutter analyze: 0 error
- flutter test: {N}/{N} pass (또는 "테스트 없음")
- git commit: {hash 1-3개}

캡쳐 (있으면): {path list}

TestFlight: 미배포 (사용자 명시 X — mandate 준수)
다음: 사용자가 명시적으로 "TestFlight 올려" / "출시" 한 마디 → 별도 배포 단계 진행 (자동 X, 사용자 확인 후 한 번 더)
```

### halt 모드 보고 (generator 가 halted dict 반환했을 때)

```
⚠️ /harness 중단 — {idea 한 줄}

이유: {halt_reason 한국어 변환}

**main halt (§0~§1 단계 — sprint 진입 전)**
- codex_auth_apikey → "codex CLI 가 API key 모드. `codex logout && codex login` 후 재시도"
- git_pull_conflict → "seephone git pull 충돌 — 수동 resolve 필요"
- wrong_machine → "이 작업은 다른 머신에서 처리. HANDOFF.md 로 넘길까요?"
- arguments_empty → "1-4 문장 idea 부탁드려요"
- planner_spec_invalid → "planner 가 spec 작성 실패. idea 명확화 1줄 부탁드려요"

**generator halt (§2 sprint 진행 중)**
- sprint_same_round_max_fail → "Sprint <halted_at_sprint> 가 7 라운드 모두 FAIL (동일 sprint 막힘)"
- sprint_accumulated_block → "5 sprint 누적 진행 중 1개도 PASS 못 함 (방향 자체 문제)"
- git_conflict_mid_sprint → "sprint 중 git 충돌 — 수동 resolve 필요"
- new_direction_detected → "기존 spec 의 NON-GOAL 벗어남. 새 idea 로 재호출?"
- spaceauth_expired → "사용자가 'TestFlight 올려' 명시한 경우만 도달. `fastlane spaceauth -u zkxmel@naver.com` 1회 후 재시도"
- secret_leak → "시크릿 leak 감지 (파일명 또는 staged content). 수동 점검 후 재시도"

진행 상황: Sprint {halted_at_sprint} / codex audit {codex_audits_total} 라운드
마지막 audit: **FAIL** (overall {last_codex_score.overall}, A {A} / B {B} / C {C} / D {D})
  ↑ "halt 모드는 정의상 FAIL". 부분 PASS 후 sprint 사이에서 halt 한 경우엔 commits / changed_files 로 어디까지 됐는지 표시
부분 commit (audit PASS 후 made — 이 hash 는 history 에 남음): {commits, 있으면}
부분 changed_files (commit 안 된 staged 또는 commit 된 파일 모두 포함): {changed_files}

남은 FIX:
1. ...
2. ...

다음 결정: {next_action_for_user}
```

장황한 코드 snippet X. 사용자 결정 필요한 부분만 노출.

---

## 5. 메모리 자동 업데이트 (필수)

`/harness` 작업 끝나면 다음 파일 추가:

`~/.claude/projects/-Users-seunghyeon-seephone/memory/project_<slug>_round_<N>.md`

```yaml
---
name: project_<slug>_round_<N>
description: <한 줄 무엇·왜>
type: project
date: <YYYY-MM-DD>
---
```

본문:

```
## 무엇
{idea 1-2 문장}

## 왜
{spec 의 제품 컨텍스트 1-2 문장}

## 검증 결과
- codex audit: {N} 라운드 PASS 9.9+ (A X / B X / C X / D X)
- flutter analyze: 0 error
- 변경 파일 ({개수}): {top 5 path}
- commit: {hash}

## 다음
- TestFlight 미배포 (사용자 명시 대기)
- {남은 NON-GOAL or 후속 sprint, 있으면}
```

그리고 `MEMORY.md` 인덱스에 한 줄 append:

```
- [<한 줄 무엇·왜>](project_<slug>_round_<N>.md) — {핵심 결과}
```

---

## 6. 실패 처리 (자동 재시도 / 사용자 보고 경계)

| 상황 | 종류 | 처리 |
|---|---|---|
| codex auth_mode = apikey | main halt | 사용자 한 줄 보고 + STOP (generator spawn X) |
| `$ARGUMENTS` 비어 있음 | main halt | 사용자에게 한 줄 idea 요청 + STOP |
| `git pull` 충돌 (seephone cwd) | main halt | 사용자 한 줄 + STOP |
| 머신 mismatch (Mac 작업 ↔ Windows) | main halt | "HANDOFF.md 로 넘길까요?" 한 줄 + STOP |
| planner spec 파일 부재 / 요약 부재 | main halt | 사용자에게 idea 명확화 1줄 요청 |
| 동일 sprint 가 7 evaluator 라운드 모두 FAIL | generator halt | `sprint_same_round_max_fail` dict 반환 |
| 5 sprint 누적인데 1개도 PASS 못 함 | generator halt | `sprint_accumulated_block` dict 반환 |
| sprint 중 새 디렉션 (NON-GOAL 벗어남) 발견 | generator halt | `new_direction_detected` dict 반환 |
| secret leak 감지 (파일명 또는 staged content) | generator halt | `secret_leak` dict 반환 |
| spaceauth cookie 만료 (단, **사용자가 명시적으로 "TestFlight 올려"/"출시" 한 경우만 단계 도달** — 기본 mandate 는 미배포) | generator halt | `spaceauth_expired` dict 반환 + 1회 명령 안내 |
| `git push` / `git commit` 실패 (sprint 중 충돌) | generator halt | `git_conflict_mid_sprint` dict 반환 (force push 절대 X) |

자동 재시도는 codex evaluator 라운드 안에서만 (최대 7). 그 외 실패는 사용자 confirm.

---

## 7. 트레이드오프 (스킬 사용 가이드)

### 시간 예산
- 풀스택 앱 (Anthropic Aesop 패턴): 1-4시간
- 콘텐츠 정제 (사주 phrase 변주): 30분-1.5시간
- 기능 추가 (UI + 로직): 45분-2시간

### 비용 (Pro 구독 모드 — 추가 결제 X)
- codex audit 1 라운드 ~5-15k token (구독 한도 안에서 무료)
- planner spawn: Opus 1회
- generator spawn: Opus 1회 (sprint 동안 compaction)
- 전체 평균 1 작업 = Opus 5-15 turn + codex 10-30 round

### 적합한 작업
- ✅ 풀스택 앱 빌드 (`/appfty` 후 톤·디자인 다듬기)
- ✅ 큰 기능 추가 (60일주 deep slice 840 fields 같은)
- ✅ 콘텐츠 정제 (pillarseer Round 60+ 잔반복 변주)
- ✅ 톤 일관성 검증 (codex 9.9+ 패턴)

### 부적합 (직접 처리가 빠름)
- ❌ 단순 버그 수정 (1줄 변경)
- ❌ 명백한 typo
- ❌ 빌드/배포 자체 (별도 `/appfty` 또는 `scripts/deploy_testflight.sh`)
- ❌ 단순 정보 조회 ("이 파일 어디 있어?")

> 한계선 안 = evaluator 불필요 (Anthropic). 한계선 밖 = 가치 있음. 작업 직전 "Opus 가 한 방에 가능?" 자문해서 YES 면 직접 처리, 모호하면 `/harness` 발동.

---

## 8. 검증 단계 (이 스킬 자체 — 작성 후 확인)

이 스킬 자체도 codex audit 거침. 최소 3 dimensions:

```
A. 사용성 — 사용자가 5초 안에 호출 방법 이해? (0-10, ≥9.0)
B. 완성도 — 모든 단계 명시? planner / generator / evaluator / 보고 / 메모리 / 실패 처리? (0-10, ≥9.0)
C. mandate 통합 — TestFlight·페르소나·톤·5 절대 룰 모두? (0-10, ≥9.5)
D. Anthropic 인사이트 — 스프린트 계약 / 파일 communication / 단순화 / few-shot 보정? (0-10, ≥9.0)
```

PASS 9.9+ 까지 재작성.

---

## 9. 참고 (사용자 검증된 패턴)

이 스킬은 다음 검증 사례 기반:

- **pillarseer Round 60~70**: codex audit 8.4 → 9.9 PASS 라운드 누적. 60일주 deep slice 840 fields / 자미두수 융합 / 6각 radar / K-POP 셀럽 매칭.
- **protagonist**: zero-gate factory + 시뮬 검증 + AdMob 인증 + 1.0.1 metadata-only update 패턴.
- **bbaksin/pupil/anger**: TestFlight 외부 베타 통과 패턴 (`ganzitester` 그룹).

자세한 사례:
- `~/.claude/projects/-Users-seunghyeon-seephone/memory/reference_zero_gate_factory.md`
- `~/.claude/projects/-Users-seunghyeon-seephone/memory/feedback_app_factory_workflow.md`
- `~/.claude/projects/-Users-seunghyeon-seephone/memory/reference_testflight_pipeline.md`

---

자, 시작. 메인 에이전트는 **task 배분만**. 코드는 generator 가, 평가는 codex 가, 결정은 사용자가.
