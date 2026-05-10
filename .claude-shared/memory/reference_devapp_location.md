---
name: 새 앱 폴더 위치 규칙 (devapp)
description: 모든 새 앱은 ~/devapp/{app_name}/ 단독 디렉토리. seephone 모노레포와 별개.
type: reference
originSessionId: 57bec09c-255a-4306-954d-87a055d0688c
---
사용자가 2026-04-29 명시: **앞으로 새 앱은 모두 `~/devapp/{app_name}/` 에 단독 폴더로**.

**Why:** seephone 모노레포(빡신/pupil/anger) 와 별개로 운영. 새 앱은 zero-gate factory(fastlane produce + ASC API + AdMob API + LLM-driven content) 로 만들 거라 독립 디렉토리가 git/배포 격리에 적합.

**How to apply:**
- 신규 앱 시작 시: `mkdir -p ~/devapp/{name}` → 거기서 spec/scaffold 부터 시작
- seephone 모노레포는 빡신/pupil/anger 3개로 **동결**. 여기에 새 앱 추가 금지.
- 공유 인프라는 기존 위치 그대로 재참조:
  - ASC API key: `~/.appstoreconnect/private_keys/AuthKey_JSGU6J4JN4.p8`
  - ElevenLabs key: `~/shadow/shadowrun/.env`
  - sfx-shared 마스터 라이브러리: `~/seephone/sfx-shared/` (필요 시 새 앱 `assets/sfx/` 로 sync)
- 각 새 앱은 자체 `fastlane/` 디렉토리 + `Appfile`/`Fastfile` 가짐 (zero-gate 흐름의 일부)
- 디렉토리 README: `~/devapp/README.md` 에 위치 규칙 기록됨

**현재 상태 (2026-05-01):**
- `~/devapp/` 는 단순 부모 디렉토리 (git repo 아님)
- **각 앱마다 단독 GitHub private repo** (`dorisurararara-crypto/{name}`):
  - https://github.com/dorisurararara-crypto/protagonist
  - https://github.com/dorisurararara-crypto/memereport
  - (구) https://github.com/dorisurararara-crypto/devapp — 모노레포 시도 후 폐기, 사용자가 GitHub 웹에서 삭제 결정
- 시크릿 (`fastlane/asc_api_key.json`, `*.p8`, `*.jks`, `key.properties`, `.env`) 모두 각 앱 `.gitignore` — 절대 push 금지

**신규 앱 추가 시 표준**:
```bash
mkdir ~/devapp/{name}
cd ~/devapp/{name}
flutter create --org com.ganziman --project-name {name} --platforms ios,android .
# .gitignore 에 fastlane secrets 패턴 추가
git init -b main
git add . && git commit -m "feat: ..."
gh repo create dorisurararara-crypto/{name} --private --source=. --remote=origin --push
```
