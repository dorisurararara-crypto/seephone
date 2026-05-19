---
name: workflow-option-a-codex-brain
description: "pillarseer R95+ 부터 사용자 mandate 새 workflow — codex 두뇌, 서브에이전트 코딩, Claude (Opus 4.7) 메신저+보고. Option A = pure passthrough."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b7388865-d3ed-4b0b-8946-5130910483e5
---

사용자가 직접 mandate (2026-05-18 대화):

> "잠깐 하네스 방식을 바꾸자 너는 codex에게 내가 보낸 말만 보내주고 codex가 머리이고
> 너가 (claude opus4.7) 이 코딩을 잘하니까 코딩만 시키게하자 그리고 코딩도 너가 직접하는게아니라
> 서브에이전트 시켜서 하고 너는 그냥 나랑 대화만하고 codex한테 내 대화 그대로 전달만 하고
> codex답변을 나한테 알려주고 완료되었다 이정도만 말하는걸로 바꾸자"

그 후 사용자가 Option A 선택:
> "A" (= 완전 passthrough 옵션)

## 역할 분담 (절대 룰)

- **사용자**: mandate 만
- **codex**: 두뇌 — planning, spec 결정, evaluator (한국어 native read)
- **Claude Opus 4.7 (나)**: 메신저 + 서브에이전트 디스패치 + 보고만
- **서브에이전트** (general-purpose): 실제 코딩

## Option A 룰

1. **사용자 메시지 → codex 에 그대로 전달**. context inject 금지 (project 정보·이전 회차 결과 추가 X).
   - 명령: `echo "사용자 verbatim 메시지" | codex exec --skip-git-repo-check 2>&1 | tail -N`
   - 또는 heredoc 으로 사용자 메시지만

2. **codex 답변 → 사용자에게 그대로 paste**. 요약·번역·sale 금지.
   - "codex 답변 그대로:" 한 줄 + 답변 전체 paste

3. **서브에이전트 디스패치는 codex spec 그대로** 받아서 위임. 내가 spec 만들지 마.

4. **서브에이전트 완료 → "완료" 한 단어 보고**. 길게 요약 X.

5. **검수도 codex 가** — 서브 결과 sample 보내서 한국어 native 기준 read 받기.

6. **ship 도 codex 가 GO 줄 때까지 rework 반복**. Claude 가 "괜찮아 보임" 판단 X.

## R97 까지 검수 progress (왜 정직히 codex 답변 그대로 paste 해야 하나)

- R96 — 내가 codex 의 "9.9/10 SHIP" 만 알려줌. 사실 codex 는 surface metric 만 봤음.
- 실기기 검증 후 사용자: "Codex한테 9.9 테스트 받은거 맞아???"
- codex 자체 철회: 실기기 sample 기준 **3~4/10**.
- 교훈: codex 답변 sale 금지. 사용자가 codex 평가 raw 그대로 봐야 함.

## 이어서 할 때 (다음 세션)

사용자가 "이어서" / "체크해줘" 한 마디 → Claude 가:
1. `git pull --rebase` (변경 없으면 OK)
2. HANDOFF.md "## 최신" block read
3. 마지막 ship build # 확인 (`ruby scripts/check_build_status.rb`)
4. 사용자 다음 mandate 대기

다음 mandate 받으면 → **즉시 codex 에 verbatim 전달** (context 없이) → codex 답변 그대로 paste → 서브 위임 → 완료 한 줄.

## 관련

- [[reference_testflight_pipeline]] — ship pipeline (deploy_testflight.sh + submit_b{N}.rb)
- [[project_pillarseer_round_97]] — R95~R97 진행 결과 (별도 memory)
