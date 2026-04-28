# Seephone Monorepo — Claude 작업 지침

이 디렉토리는 **3개의 1인 개발 앱**을 담는 모노레포입니다. 각 앱은 같은 모노레포 안에서 별도 디렉토리로 관리되고, 인프라(ASC 자격증명, TestFlight 스크립트, 이미지 생성 워크플로우)를 공유합니다.

## 앱 목록 / 우선순위

`APPS.md` 참고. 현재는 **빡신** (1번) 진행 중. 2번/3번은 빡신 출시 후 시작.

## 머신 간 작업 교환: HANDOFF.md

이 프로젝트는 **Mac mini** (Flutter 개발)와 **Windows + RTX 5070 Ti** (로컬 AI 이미지 생성) 두 머신에서 각각 Claude Code로 작업합니다. `HANDOFF.md` 가 두 머신 간 메시지 큐 역할.

### 세션 시작 시 반드시
1. `git pull`
2. `HANDOFF.md` 읽기
3. "## 최신" 블록에 **자기 앞으로 온 요청**이 있는지 확인
4. 있으면 수행 → 결과를 "## 최신"에 덧붙여 적고 → commit → push
5. 처리 완료된 이전 항목은 "## 이력"으로 이동

### 현재 머신 식별
- `uname` 결과가 `Darwin` → Mac (Flutter 개발 담당)
- Windows/WSL → Windows (이미지 생성 담당)

## 디렉토리 구조

```
/seephone
├── CLAUDE.md             # 본 문서 (양쪽 Claude 공통 지침)
├── APPS.md               # 3개 앱 개요·기획서
├── HANDOFF.md            # Mac ↔ Windows 메시지 큐
├── .gitignore
├── prompts/              # 이미지 생성 배치 요청 (Mac → Windows)
│   └── batch_NNN.json
├── raw-images/           # 생성 결과물 (Windows → Mac)
│   └── batch_NNN/
├── content-draft/        # 멘트·콘텐츠 큐레이션 작업 공간 (Mac)
├── bbaksin/              # 1번 앱 — 디지털 무당
│   ├── lib/
│   ├── assets/
│   │   ├── backgrounds/  # 큐레이션 통과 부적 배경
│   │   └── data/         # 팩폭 멘트 JSON
│   └── pubspec.yaml
├── pupil/                # 2번 앱 (예정)
└── anger/                # 3번 앱 (예정)
```

---

## 인프라 재활용 (shadowrun 프로젝트로부터)

shadowrun(`~/shadow/shadowrun`)에 다음 인프라가 이미 셋업돼 있고 빡신/pupil/anger 앱에서도 그대로 사용 가능:

### App Store Connect API (재활용)

| 항목 | 값 |
|---|---|
| ASC API Key 파일 | `~/.appstoreconnect/private_keys/AuthKey_JSGU6J4JN4.p8` (chmod 600, git 제외) |
| Key ID | `JSGU6J4JN4` |
| Issuer ID | `5269abe3-03f1-46a9-a37c-35d950758714` |
| Team ID | `Q6H9HCTK6W` |

### 외부 테스트 그룹 (재활용 가능 — 단, 새 앱마다 ganzitester 그룹 새로 만들어야)

shadowrun 의 `ganzitester` 외부 그룹은 **shadowrun 앱 전용**. 새 앱마다 ASC에서 외부 그룹을 별도로 생성·심사 통과시켜야 함. (그룹 이름 재사용은 OK.)

### TestFlight 자동화 스크립트 (재활용 — 앱별 APP_ID만 교체)

shadowrun `scripts/asc/_helpers.rb` 의 `APP_ID` 상수를 빡신 등록 후 받는 새 App ID로 교체하면 동일하게 작동.

`scripts/deploy_testflight.sh`도 거의 그대로 복사 가능 (Flutter 빌드 → altool 업로드 → 외부 그룹 할당 → Beta Review 제출).

**TODO**: 빡신을 ASC에 등록하면 새 APP_ID 발급. 그 시점에 shadowrun 스크립트를 `bbaksin/scripts/`로 복사하고 APP_ID만 교체.

### Bundle ID 컨벤션
- shadowrun: `com.ganziman.shadowrun`
- 빡신: `com.ganziman.bbaksin` (이 프로젝트는 이미 `com.ganziman` org로 생성됨)
- pupil/anger: `com.ganziman.pupil` / `com.ganziman.anger` (예정)

---

## 사용자 선호 (shadowrun에서 확인된 것 — 신규 앱에도 동일 적용)

### TestFlight = 항상 외부 테스트
사용자는 **외부 그룹으로만** TestFlight 테스트. **내부 테스트 전용으로 올리지 말 것.**
"TestFlight 에 올려줘" = 업로드 + 외부 그룹 할당 + Beta Review 제출까지 **하나의 작업**.

### 커밋 메시지 스타일
- `chore: handoff <요약>` — HANDOFF.md 업데이트
- `feat(bbaksin): <요약>` — 빡신 기능 추가
- `fix(bbaksin): <요약>` — 빡신 버그 수정
- shadowrun 스타일 그대로 따라감.

---

## Mac Claude 가 자동 처리할 수 있는 일

(shadowrun 와 동일 패턴. 빡신이 ASC 등록되면 추가)

- TestFlight 새 빌드 배포 (스크립트 한 줄)
- 빌드 처리 상태 조회
- 외부 TestFlight 심사 제출
- ASC REST API 작업 (메타데이터, IAP, 스크린샷 등)

각 명령은 빡신 ASC 등록 후 `bbaksin/scripts/` 에 추가 예정.

---

## Windows Claude 가 자동 처리할 수 있는 일

- `prompts/batch_NNN.json` 읽고 → 로컬 AI (ComfyUI / Automatic1111 / sd-scripts) 로 이미지 생성 → `raw-images/batch_NNN/` 에 PNG 저장 → HANDOFF.md "## 최신"에 완료 보고 + commit + push
- 앱 아이콘 / 굿판 이펙트 / 부적 배경 / 동공 지진 분석 결과 카드 배경 등 모든 비주얼 에셋 생성

생성에 사용하는 모델·워크플로우는 Windows 측 Claude가 자체 판단 (사용자가 이미 셋업한 환경 기준).

---

## 주의 사항

- **시크릿 절대 커밋 금지**: `.p8`, `.env`, `key.properties` 등은 `.gitignore` 처리됨
- **raw-images 큐레이션**: 탈락 이미지는 `raw-images/batch_NNN/.rejected/` 로 이동 (gitignore됨)
- **TestFlight 파이프라인은 shadowrun 인프라 의존**: shadowrun 디렉토리(`~/shadow/shadowrun`) 가 같은 머신에 있어야 ASC API key 경로 등 그대로 작동
