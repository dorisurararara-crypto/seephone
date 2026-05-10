# 글로벌 지침 — Windows 전용

`$env:OS` = `Windows_NT` 일 때만 적용. 양쪽 공통은 `global.md` 참고.

## Windows 인프라 위치

| 자산 | 경로 |
|---|---|
| seephone repo | `%USERPROFILE%\seephone\` (= `C:\Users\seunghyeon\seephone\` 가정) |
| 신규 앱 폴더 (있다면) | `%USERPROFILE%\devapp\{name}\` |
| 메모리 (seephone 기준) | `%USERPROFILE%\.claude\projects\C--Users-seunghyeon-seephone\memory\` (→ `.claude-shared\memory\` 심볼릭 링크) |
| 글로벌 CLAUDE.md | `%USERPROFILE%\.claude\CLAUDE.md` (→ `.claude-shared\global.md` + `global-windows.md` 심볼릭 링크) |
| 이미지 생성 환경 | (사용자 셋업 — ComfyUI / Automatic1111 / sd-scripts 중 자체 판단) |
| Python venv | `seephone\scripts\.venv\` (gitignore 됨) |

> **메모리 경로 인코딩**: Claude Code 는 프로젝트 경로의 `\` 와 `:` 를 `-` 로, drive letter
> 를 `<letter>--` 로 변환해서 `~/.claude/projects/` 안에 폴더를 만듭니다. Windows 에서
> seephone repo 가 `C:\Users\seunghyeon\seephone` 면 인코딩된 폴더명은
> `C--Users-seunghyeon-seephone`. 부트스트랩 스크립트가 자동으로 처리.

## Windows 전용 운영 룰

### 1. 머신 역할 = 이미지 생성 + 콘텐츠 큐레이션
- iOS/Android 빌드는 Mac 담당. Windows 에서 `flutter build` 시도 ❌
- TestFlight·ASC API 호출도 Mac 담당
- Windows 가 자율 처리: 이미지 batch 생성, raw-images 큐레이션, HANDOFF 메시지 처리

### 2. HANDOFF.md 폴링 워크플로우
세션 시작 시 (또는 cron 30분):
1. `git pull`
2. `HANDOFF.md` 의 "## 최신" 블록 확인
3. 자기(Windows) 앞으로 온 요청 있으면 → 처리
4. 결과를 "## 최신" 에 덧붙여 적고 → commit → push
5. 처리 완료된 이전 항목은 "## 이력" 으로 이동

### 3. 이미지 생성 batch 프로토콜
- 입력: `seephone/prompts/batch_NNN.json`
- 출력: `seephone/raw-images/batch_NNN/<seed>.png` (PNG)
- 탈락 이미지: `seephone/raw-images/batch_NNN/.rejected/` (gitignore 됨)
- 모델·워크플로우 선택은 Windows 자체 판단

### 4. 경로 표기 통일
공통 문서(`global.md` 등)에서 `~/path` 표기는 Mac 의 `$HOME/path` 의미.
Windows 에서는 `$env:USERPROFILE\path` 로 정신적 매핑하면 됨.

## 첫 셋업 / 재셋업

```powershell
cd $env:USERPROFILE\seephone
.\.claude-shared\bootstrap-windows.ps1
```

스크립트가 자동 처리:
1. `%USERPROFILE%\.claude\CLAUDE.md` 를 `.claude-shared\global.md` + `.claude-shared\global-windows.md` 합쳐서 생성
2. `%USERPROFILE%\.claude\projects\C--Users-seunghyeon-seephone\memory` → `.claude-shared\memory` 심볼릭 링크 (또는 디렉토리 정션)
3. 시크릿 폴더 (`.appstoreconnect`, `.fastlane`) 는 Windows 에서 사용 안 함 → 셋업 X

## Windows ↔ Mac 차이 메모

| 항목 | Mac | Windows |
|---|---|---|
| 셸 | zsh | PowerShell (또는 Git Bash) |
| Home | `$HOME` | `$env:USERPROFILE` |
| 심볼릭 링크 | `ln -sfn` | `New-Item -ItemType SymbolicLink` 또는 `mklink /D` |
| Claude Code 글로벌 CLAUDE.md | `~/.claude/CLAUDE.md` | `%USERPROFILE%\.claude\CLAUDE.md` |
| 메모리 폴더 | `~/.claude/projects/-Users-seunghyeon-seephone/memory/` | `%USERPROFILE%\.claude\projects\C--Users-seunghyeon-seephone\memory\` |
