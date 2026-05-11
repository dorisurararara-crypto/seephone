# Pillar Seer — 이어서 자율 진행 (새 세션용)

> **시작 명령** (새 세션에서): `cd ~/seephone/pillarseer && cat RESUME.md` 읽고 그대로 자율 진행.

## 🎯 협업 프로토콜 (PM = codex, Coder/QA = Claude)

사용자 mandate (2026-05-12 ~14:50):
> "codex 와 claude 가 완전히 앱을 제대로 만들고 아이콘 하나하나까지 기능 제대로
> 동작하는지 부족한 부분은 없는지 자세하게 분석. 명령은 codex 가 하게."

### 역할 분담
- **codex = PM (Product Manager)**: 전체 plan, 화면별 우선순위, 사용자 관점 판단, 콘텐츠 퀄리티 검토, 다음 명령 발행
- **Claude = Coder + QA**: 코드 작성, 아이콘/버튼 단위 동작 검증, 오류 발견, 추가/수정 제안

### 매 cycle 프로토콜 (무한 iterate)
1. **Claude → codex**: "다음 무엇을 할까요? 현재 상태 X, 옵션 A/B/C." (codex 에 plan 검토 요청)
2. **codex**: 우선순위 + 명령 ("Z 부터 해. 이유: ...")
3. **Claude**: 코드 작성 + 화면 빌드 + 캡쳐
4. **Claude → codex**: "Z 완성. 화면 X, 코드 Y. 검토 부탁."
   - 첨부: 캡쳐 image, 코드 diff 요약, 클릭 가능한 모든 아이콘/버튼 list
5. **codex**: 사용자 관점 review → "통과 / 추가 필요 / 수정 필요" 판단
   - 부족한 부분 / 사용자 헷갈림 / 추가하면 좋은 것 / 콘텐츠 퀄리티 vs 점신·평생사주
6. **Claude**: 통과 → 다음 화면. 수정 → 다시 step 3.

### 아이콘/버튼 단위 QA 체크리스트 (Claude 가 매 화면마다)
- [ ] 모든 IconButton/Icon/TextButton/InkWell 의 onTap 동작 확인 (null 또는 wire)
- [ ] 사용자가 클릭한 후 무엇이 일어나는지 명확? (모달/페이지 이동/SnackBar)
- [ ] 왜 이 화면을 보는지 명확? (Header + sub-text)
- [ ] 다음 화면 어디로 갈지 명확? (CTA + 보조 액션)
- [ ] 처음 본 사용자가 헷갈리는 부분 없나?
- [ ] 한국어/영어 둘 다 자연스러운가? (직역 X)
- [ ] 콘텐츠 퀄리티가 점신/평생사주 무료 결과 수준인가?

### codex 호출 패턴

```bash
codex exec --skip-git-repo-check "[현재 상태 + 질문]" 2>&1 | tail -50
```

- 화면 캡쳐 첨부: `--image /path/to/cap.png` (codex 가 multimodal 지원 시)
- 긴 review: `cat capture_log.md | codex exec --skip-git-repo-check "검토:"`
- 사용자 mandate 인용 + "PM 입장에서 결정"

### 막힐 때 fallback (사용자 mandate)
1. 인터넷 검색 (WebSearch / WebFetch)
2. 커뮤니티 (Reddit / GitHub Issues / 개발자 블로그)
3. codex 에 방법 물음 ("이거 어떻게 해결?")
4. **그래도 안 되면**: 뒤로 미루고 마지막에 한 번에 보고 (혼자 결정 X)

### 사용자 보고 (한 번에)
- 완료: 모든 화면 + 콘텐츠 + Build #5
- 안 된 것 (있다면): list + 이유 + codex 의견
- 사용자 액션 필요한 것 (있다면): 명확하게

## 🚀 출시 quality bar (사용자 mandate 2026-05-12 ~15:00)

> "시장에 당장 나갔을 때 바로 성공할 수 있게끔 완성도 하나도 빈틈없이 완벽하게.
> 기능 / 디자인 / 사주내용 / 퀄리티 다 좋게."

### 4축 perfect 기준
1. **기능**: 모든 화면 + 모든 버튼/아이콘 동작. 0 dead-end. crash 없음. flutter analyze 0. flutter test 통과
2. **디자인**: V4 미스틱 폼 톤 일관 + 모든 화면 polish. 다크 코스믹 + 골드 + 한자 element. animation smooth. 접근성 OK
3. **사주 내용**: 점신·평생사주 수준 (3000+ words MVP, 8섹션, 단정형 톤, ko/en 둘 다 자연스러움). 영어권 K-pop 팬이 이해 가능
4. **퀄리티**: 첫 사용자가 30초 안에 "오 진짜네" 느끼는 detail. SnackBar / Loading state / Empty state / Error state 모두 polish

### 멀티 세션 / 서브에이전트 사용 OK
- **Claude subagent**: `Agent` tool 로 병렬 작업 (콘텐츠 batch / 시뮬 캡쳐 / web research / Reports 화면별 etc)
- **codex 여러 인스턴스**: `codex exec` 여러 번 호출 가능 (백그라운드 + 메인). PM 명령 codex + 콘텐츠 생성 codex 분리
- **gemini**: `gemini -p "..."` 보조 (codex 부하 분산)
- 병렬 가능한 작업은 동시 시작 (Task tool 또는 multiple Bash run_in_background)

### Deep thinking (모든 발언)
- 모든 codex / gemini 호출 prompt 끝에 **"ultrathink"** 또는 **"이 결정을 시장 출시 success 관점에서 깊게 검토"** 추가
- Claude 본인도 매 단계 깊게 사고 (단편적 답변 X, 옵션 비교 + tradeoff + 사용자 관점 + 시장 비교)

### 막힘 시 fallback (사용자에게 묻기 전 무조건)
1. WebSearch / WebFetch
2. 커뮤니티 (Reddit r/Flutter / r/iOS / GitHub Issues / 개발자 블로그 / Stack Overflow)
3. codex 에 방법 물음
4. **그래도 안 되면**: 뒤로 미루고 마지막에 list 로 보고

---

## 현재 상태 (2026-05-12 ~14:40 KST)

### TestFlight
- ASC App ID `6768096855` (Pillar Seer)
- Build #3 `WAITING_FOR_REVIEW` (사용자 결정으로 자연 통과 대기, 24-48h)
- Build #4 ASC `VALID` (Round 1-4 SHIP fix 포함, #3 통과 후 자동 submit 가능)
- Public TestFlight: https://testflight.apple.com/join/kRs36R3b
- Beta Group `3217ce1c-29ca-4946-a26a-0c55529172a3`

### 완료된 것 (이번 세션)
- i18n (en/ko) — `lib/l10n/app_{en,ko}.arb` + `AppL10n` 자동생성. 60+ strings. 전 화면 적용 (Splash/Input/Result/Home/Placeholder/BottomNav/Settings/Profile/ComingSoonModal)
- LocaleNotifier (Riverpod + shared_preferences) — system/en/ko 3옵션
- Settings 화면 (`/settings`) — 언어 토글 + About
- Profile 화면 (`/profile`) — 사용자 사주 + Settings 진입 + Reset
- ComingSoonModal — Notify Me / Not now (Result Unlock/Share + Home Promo wire)
- Phase 1 fix: 시간 nullable + validation, Home score explanation (low/mid/high), Promo 모달
- Phase 2 fix: Splash 1.8s→2.8s, Gender 옵션 (Male/Female/Other ChoiceChip)
- V4 미스틱 폼 Input 디자인 — 별자리 (StarField 12개) + 한자 watermark (柱/命) + IconField 컴포넌트 + 골드 glow CTA
- mockup HTML 5톤 (디자인 리뉴얼) + 5종 (Input 리디자인, ko/en JS 토글)
- codex CLI ChatGPT 구독 모드 전환 완료 (`auth_mode: chatgpt`, `chatgpt_plan_type: pro`)
- 글로벌 룰 (.claude-shared/global.md) — codex API key 모드 금지 명시

### 사용자 mandate (이번 세션 마지막)
1. **개발자 모드 hidden gate**: 어떤 부분 5탭 → 키 입력 다이얼로그 → `ganzinam95` 입력 → 모든 Pro 잠금 해제, `ganzinam12` → free 복귀. **위치: Settings 화면의 'Version 1.0.0' 라벨 5탭 (Android 표준 패턴)**
2. **자세한 reading 콘텐츠**: 한국 사주 사이트(점신/평생사주 수준) 톤. 8섹션 × 60일주 × ko/en. MVP 3000 words/사용자. 단정형 ("당신은 ~한 사람입니다"). codex batch 생성.
3. **Coming Soon 4 화면 진짜 구현**: Reports → 4종 (Compatibility 궁합, Tojeongbigyeol 144괘, Date Picking 택일, Dream 해몽) + Discover K-pop saju 콘텐츠
4. **Result 화면 8섹션 확장**: Day Master 250w + Five Elements 150w + Ten Gods 6×80w + Life Themes 6×180w (Career/Wealth/Love/Health/Family/Fame) + 10-Year Luck 6×100w + This Year 300w + Lucky 150w. Pro 잠금 적용 (free user는 Day Master + Five Elements + Life Themes 절반 정도, 나머지 잠금)
5. **앱 자체 언어 토글**: 이미 Settings에서 가능 (확인)
6. **Build #5 ASC 업로드** + Build #3 review 통과 후 #5 자동 submit
7. **테스트 + 사용자 관점 QA**: codex와 함께 모든 아이콘/버튼 다 눌러보기, 콘텐츠 퀄리티 vs 한국 사주앱 비교, 안 되는 것 미루고 마지막에 보고. 막히면 web search → 커뮤니티 → codex.

### 시장조사 결과 (이전 세션)
- 한국 무료 사주 사이트: 8 섹션 × 150-1000자/섹션, A4 4-10페이지 (3000-8000 words)
- 인기 TOP: 연애·궁합 / 재물·직업 / 세운 / 일간 / 대운 / 신살 / 결혼·자녀
- Paywall 패턴: 원국/일간/오행/오늘운세 무료, 대운 전체/세운 디테일/궁합 풀/직업 풀 = Pro
- 톤: 단정형 + 한자어 ("당신은 ~한 사람입니다")

## 진행 순서 (이어서 시작)

### Phase A (개발자 모드 + 콘텐츠 생성 시작) — 1시간
1. `lib/providers/dev_unlock_provider.dart` 이미 작성 됨 (검토 후 settings_screen에 wire)
2. Settings 화면 'Version 1.0.0' 라벨에 5탭 GestureDetector → AlertDialog(TextField) → `devUnlockProvider.apply(code)` → DevCodeResult.unlocked/locked/invalid 별 SnackBar
3. `saju_60ji_full.json` 스키마 정의 (60일주 × 8섹션 × ko/en)
4. codex 백그라운드로 240 entries 생성 시작 (`codex exec`, 출력 → `assets/data/saju_60ji_full.json`)

### Phase B (Result 8섹션 확장) — 1.5시간
5. `SajuResult` model 확장 (8섹션 fields)
6. `SajuService` JSON 로드 + 8섹션 fill
7. `result_screen.dart` 8섹션 UI (스크롤 + Pro Lock pill on locked sections)
8. `devUnlockProvider` watch — true 시 모든 섹션 unlock

### Phase C (Reports 4 화면) — 2시간
9. `lib/screens/reports/compatibility_screen.dart` — 두 사주 input + 매치율 + 5행 분석
10. `lib/screens/reports/tojeongbigyeol_screen.dart` — 144괘 카드 + 12개월 격자
11. `lib/screens/reports/date_picking_screen.dart` — 길일/흉일 카렌더
12. `lib/screens/reports/dream_screen.dart` — 해몽 카테고리 + 검색
13. Reports placeholder → 4 카드 grid 진입 메뉴

### Phase D (Discover K-pop saju) — 1시간
14. `lib/screens/discover_screen.dart` — 유명인 사주 카드 (placeholder data) + K-pop 스토리
15. `assets/data/celebrities.json` — IU/BTS V/Squid Game 출연자 등 10-20명

### Phase E (QA + Build #5) — 1시간
16. iOS 시뮬 빌드 + 모든 화면 캡쳐
17. codex 와 협의: 각 화면 사용자 관점 QA. 모든 버튼/아이콘 동작 검증
18. 콘텐츠 퀄리티 vs 점신/평생사주 비교 (codex 의견)
19. `bash scripts/deploy_testflight.sh 5` → ASC 업로드
20. Build #3 review 진행 상태 폴링 → 통과 시 #5 submit
21. HANDOFF.md 종합 보고

### 사용자 대기 큐 (현재 0건)
- Build #3 review 통과 후 ASC 콘솔에서 #4/#5 review submission 확인 (선택)
- AdMob/RevenueCat 등 결제 wire 는 사용자 mandate "나중에 OK"

## 인프라 참고

- ASC API: `pillarseer/scripts/_helpers.rb` (APP_ID `6768096855`)
- Deploy: `bash scripts/deploy_testflight.sh <build_number>`
- Beta 그룹: 자동 (ganzitester)
- Meta: `scripts/seed_beta_meta.rb` + `scripts/seed_review_detail.rb`
- Submit: `scripts/submit_external_beta.rb <build>`

## codex 사용

- 현재 `auth_mode: chatgpt` (ChatGPT Pro), 추가 결제 X
- 호출: `codex exec --skip-git-repo-check "..."` (non-interactive)
- 막히면 codex 상의 (`codex` 또는 `gemini -p "..."`)

## Mac 폴링

- `/loop` cron (job `a048ffea`, 매시 17분) 살아있음
- HANDOFF.md "## 최신" 추적
- Windows 메시지 즉시 처리

## 메모리

- `~/.claude/projects/-Users-seunghyeon-seephone/memory/MEMORY.md` 인덱스
- 야간 작업 로그: `project_overnight_log.md` 류 시계열 append
