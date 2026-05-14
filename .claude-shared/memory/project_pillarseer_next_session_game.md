---
name: project_pillarseer_next_session_game
description: 다음 세션 4선수 부자연스러움 찾기 대결 — codex×2 + opus×2 / R1 표현 R2 오류 R3 UX / 5판 3선 / 심판=다음 세션 메인 Claude
metadata: 
  node_type: memory
  type: project
  originSessionId: bd822aa5-cb36-4cc4-bc81-10bcead64b89
---

## 무엇
다음 세션 main Claude 가 심판으로 진행하는 4선수 대결.
- 선수: codex_A, codex_B, opus_A, opus_B
- 라운드:
  - R1: pillarseer 한국어·영어 모든 텍스트의 부자연스러운 표현 찾기
  - R2: 코드·로직·맞춤법·기능 오류 찾기
  - R3: 사용자 (한국 MZ 중학생 K-POP 팬) 관점 어색·불편·재미없음 찾기
- 채점: 진짜 발견 +1 / false positive -1 / 중복 0 / 형식 위반 -1
- 진행: 라운드마다 결과 없을 때까지 게임 반복 (또는 5게임 cap). 라운드 winner 합산 → 종합 winner.

**Why:** 사용자 mandate (2026-05-14 마지막) — "codex 2개와 claude opus 2개가 대결을 하는거야 다음세션이 심판을 보고 부자연스러운 말 찾기 대결... 게임을 이기려고 이상한걸 찾으면 -1점... 5판 3선... 라운드마다 결과 많을수록 몇번 더 돌려도돼 결과가 없을때까지"

**How to apply:**
1. 다음 세션이 트리거 ("게임 시작" / "이어서" / "체크해줘") 받으면 spec 파일 `/Users/seunghyeon/seephone/pillarseer/다음세션_게임.md` 로드 후 자동 진행.
2. 4 선수 동시 launch (codex × 2 stdin pipe + Agent spawn × 2 opus).
3. 각 결과는 `/tmp/r{N}_g{game}_player_{ID}.md` 로 저장 (선수 간 독립 — 심판만 통합).
4. 채점 표 `/tmp/r{N}_g{game}_judge.md`.
5. 진짜 발견 항목은 fix backlog `/tmp/game_fix_backlog.md` 로 누계.
6. 게임 진행 중 코드 수정 X (발견만). TestFlight 배포 X. 시뮬·에뮬 새 부팅 X.

## 4 선수 호출 방식

### codex_A / codex_B
```bash
python3 << 'PY' > /tmp/r{N}_prompt.txt
print("""당신은 pillarseer R{N} 게임 선수. <라운드 명세>""")
PY
cat /tmp/r{N}_prompt.txt | codex exec - 2>&1 | tail -200 > /tmp/r{N}_g{game}_codex_A.md
# B 도 동일 — codex 응답 다양성 자연 발생
```

### opus_A / opus_B
```
Agent(
  subagent_type=general-purpose,
  model=opus,
  prompt=<라운드 명세 + spec 본문 reference + 출력 형식>,
  description="R{N} 부자연 찾기 — opus_A"
)
```

## 라운드 별 핵심 prompt 요지

### R1 — 부자연스러운 표현
- 범위: `lib/services/*.dart` + `lib/screens/*.dart` + `lib/l10n/*.arb` + `assets/data/*.json` 모든 string literal
- 찾을 패턴: 사람이 안 쓰는 jargon / AI tic / 어순 깨짐 / 직장인·미신 mystic 톤 / 영문 ChatGPT 톤 / 의료 단정
- 톤 mandate (Round 71-76 누적) 위반 = 진짜 발견

### R2 — 오류
- 범위: 코드 버그 / 사주 계산 / l10n key 누락 / JSON 형식·중복·누락 / 한국어 맞춤법 (되/돼 등) / 영문 grammar / UI breakage / test golden stale
- `flutter analyze` 통과해도 logic bug 면 hit

### R3 — UX 어색·불편·재미없음
- 범위: 사용자 흐름 friction / 첫 fold 흥미 X / 흔한 운세앱 느낌 / 카드 순서 X / 알림 식상 / 별점 뻔함 / "오 진짜?" 없음 / 폰트·색·간격
- 페르소나: 한국 MZ 중학생 K-POP 팬

## 결과 형식 (선수 통일)
```
### 항목 N
- 위치: <파일:line 또는 JSON key>
- 원문: "<verbatim>"
- 문제: <한 줄>
- 수정: <한 줄>
```
빈 list = "결과 0".

## 채점 (심판)
| 결과 | 점수 |
|---|---|
| 진짜 발견 (페르소나 + Round 71-76 mandate 위반 확인) | +1 |
| 중복 (같은 라운드 다른 선수가 이미 찾음) | 0 |
| false positive (게임 이기려고 사소한 거 잡음) | -1 |
| 형식 위반 (위치·원문 없음) | -1 |

## 라운드 종료 조건
- 5 게임 cap, 또는
- 마지막 게임에 4 선수 다 결과 0

## 종합 winner
- 3 라운드 중 2 라운드 이긴 자.
- 동점 시 누계 점수 합산 tiebreak.

## 절대 금지
- 게임 중 코드 수정 (발견만)
- TestFlight 배포
- 시뮬·에뮬 새 부팅
- 시크릿 push
- 선수 간 결과 공유 (독립 보존)

## 보고 형식 (심판 → 사용자)
```
🎮 4선수 대결 종료
R1: {winner} (X점 / N게임)
R2: {winner} (X점 / N게임)
R3: {winner} (X점 / N게임)
🏆 종합: {선수 2-1 또는 3-0}

📋 fix backlog (진짜 발견 N건):
- R1: ...
- R2: ...
- R3: ...

다음 라운드 작업으로 묶을까요?
```

## 다음 작업 후보 (게임 후)
fix backlog → 별도 /harness Round 77 으로 묶어 처리 (사용자 명시 후).
배포는 사용자 명시 후만 (mandate "다 자동배포하지마").

## spec 파일 location
[[reference_seephone_ids]] / [[reference_testflight_pipeline]] 도 참고:
- ground truth: `/Users/seunghyeon/seephone/pillarseer/다음세션_게임.md` (전체 spec)
- 인수인계 최상단 알림: `/Users/seunghyeon/seephone/pillarseer/인수인계.md`
