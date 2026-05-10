# `.claude-shared/` — 양쪽 머신 공통 ground truth

이 폴더는 **Mac mini ↔ Windows + RTX 5070 Ti** 두 머신에서 같은 Claude Code 운영 환경을
재현하기 위한 공유 디렉토리입니다. 글로벌 CLAUDE.md, 메모리 파일, 부트스트랩 스크립트가 모두
git 으로 동기화됩니다.

## 구조

```
.claude-shared/
├── README.md              # 이 문서
├── global.md              # 양쪽 적용되는 글로벌 운영 룰 (OS 무관)
├── global-mac.md          # Mac 전용 (Apple Dev / fastlane / iOS)
├── global-windows.md      # Windows 전용 (이미지 생성 / 경로 매핑)
├── memory/                # auto memory 스냅샷 (양방향 동기화)
│   ├── MEMORY.md          # 인덱스
│   └── *.md               # 개별 메모리 파일
├── bootstrap-mac.sh       # Mac 첫 셋업 (~/.claude/CLAUDE.md + memory 심볼릭 링크)
└── bootstrap-windows.ps1  # Windows 첫 셋업 (동일, PowerShell)
```

## 동작 원리

각 머신은 부트스트랩 스크립트를 한 번 실행해서 **로컬 Claude Code 의 글로벌 CLAUDE.md 와
메모리 폴더를 이 디렉토리로 심볼릭 링크**합니다. 이후 `git pull` 만 하면:

- 글로벌 운영 룰 변경 → 양쪽 즉시 반영
- 메모리 추가/수정 → 양쪽 즉시 반영 (AI 가 한쪽에서 학습한 내용을 다른 쪽도 본다)
- HANDOFF.md 워크플로우는 기존대로

## 첫 셋업

### Mac

```sh
cd ~/seephone
bash .claude-shared/bootstrap-mac.sh
```

### Windows (PowerShell, 관리자 권한 필요 — 심볼릭 링크용)

```powershell
cd $env:USERPROFILE\seephone
.\.claude-shared\bootstrap-windows.ps1
```

또는 Windows 10/11 에서 Developer Mode 켜면 일반 사용자도 `mklink` 가능.

## 시크릿 정책

이 폴더 안에는 **시크릿 절대 금지**:
- `.p8`, `.p12`, `.env`, `.jks`, `key.properties`, OAuth 토큰 등
- 시크릿은 각 머신의 OS-specific 경로에만 (`~/.appstoreconnect/` `~/shadow/shadowrun/.env` 등)
- 이 폴더에 들어가는 건 **운영 룰 + 경로 레퍼런스 + 메모리 텍스트**만

## 변경 시 워크플로우

1. 어느 머신에서든 `.claude-shared/*.md` 수정
2. `git add .claude-shared && git commit -m "chore: shared <요약>" && git push`
3. 다른 머신에서 `git pull` → 즉시 반영 (심볼릭 링크라 파일 갱신 자동)

메모리 파일은 Claude 가 자동으로 추가/수정하는 경우가 많은데, 그 변경도 위 워크플로우로 commit 하면 됨.
