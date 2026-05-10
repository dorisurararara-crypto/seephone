---
name: seephone Mac↔Windows 협업 워크플로우
description: HANDOFF.md 메시지 큐 + Cron 폴링 + 이미지 생성 batch + 자율 모드 운영 패턴.
type: reference
originSessionId: 65198821-57e9-40a2-b42d-d1b65b6f5042
---
## 머신 역할
- **Mac mini**: Flutter 코드 + iOS 빌드 + TestFlight 배포 + 멘트 큐레이션
- **Windows + RTX 5070 Ti**: 로컬 AI 이미지 생성 (FLUX/SDXL via diffusers + bf16, GPU full-load)

각 머신에서 별도 Claude Code 세션 실행. HANDOFF.md 가 메시지 큐.

## 폴링 운영
- 양쪽 Claude 가 cron `7,37 * * * *` (30분 간격) 으로 HANDOFF.md "## 최신" 확인
- 자기 앞으로 "→ Mac" / "→ Windows" 요청이 있으면 처리 → 결과 덧붙여 commit+push
- 처리 끝난 항목은 "## 이력" 섹션으로 이동 (최신 짧게 유지)
- 충돌 방지: push 실패 시 `git pull --rebase` 후 재push

(2026-04-28 ~ 야간 초기엔 3분 폴링 / 2026-04-29 01:25 부터 30분으로 변경)

## 이미지 생성 batch 프로토콜
1. **Mac**: `prompts/batch_NNN.json` 작성 (item 별 id, prompt, size, category)
2. **Windows**: 폴링 시 새 batch 파일 발견 → 로컬 AI (diffusers + SDXL) 로 생성 → `raw-images/batch_NNN/{id}.png` 저장 → HANDOFF.md "## 최신" 에 평가 + 추천 보고
3. **Mac**: 큐레이션 결과 채택 → 적절한 위치 (`{app}/assets/...`) 로 복사 + Flutter wire → commit+push
4. **Windows**: 자율 모드 — Mac 확장 가능 영역 (도깨비 변종, 광고 자산 등) 자체 판단 batch 자율 생성 가능

## 자율 모드 (사용자 mandate 2026-04-28)
사용자 명시: "묻기 전에 로컬 + 웹 검색 → 진짜 사용자만 가능한 일만 미루고 나머지 다 진행"

자율 처리한 사용자 액션 (예시):
- ✅ Bundle ID 등록 (ASC API)
- ✅ 외부 베타 그룹 생성 (ASC API POST /v1/betaGroups)
- ✅ 개인정보 처리방침 호스팅 (gh gist create — 공개)
- ✅ ElevenLabs SFX 생성 (라이브러리 기반)
- ✅ Apple Distribution cert 즉석 발급 (xcodebuild -allowProvisioningUpdates + ASC key)

진짜 사용자만 가능한 것:
- ASC App 생성 (HTTP 403, 웹 UI 만)
- AdMob 첫 OAuth 동의 (브라우저 클릭)
- 메타데이터 텍스트 결정 (앱 설명, 키워드)
- Apple ID 2FA 인증

## 검증된 시뮬레이터 통제 명령
```bash
xcrun simctl boot "iPhone 17 Pro"             # 시뮬 부팅
xcrun simctl install booted <app>.app         # 설치
xcrun simctl launch booted <bundle.id>        # 실행
xcrun simctl launch --console-pty booted <id> # console 출력 보면서 실행
xcrun simctl terminate booted <bundle.id>     # 종료
xcrun simctl uninstall booted <bundle.id>     # 제거
xcrun simctl io booted screenshot /tmp/X.png  # 화면 캡처
xcrun simctl io booted recordVideo /tmp/X.mp4 # 영상 녹화
xcrun simctl spawn booted log show ...        # device 로그
```

흔들기 / 가속도 시뮬은 simctl 직접 미지원 → 실기기 또는 Maestro 필요.

## 흔들기 / 가속도 테스트 옵션
- **실기기**: TestFlight 외부 그룹 (ganzitester) 으로 본인 폰에 설치 후 직접 테스트
- **Maestro** (shadowrun 사용): UI 자동화 도구. yaml 시나리오 작성 가능
- **Widget integration test**: Flutter `integration_test` 패키지로 mock 가능 (시간 듦)

## seephone 운영 트릭
- 모든 commit 메시지: `chore: handoff <요약>` / `feat(<app>): <요약>` / `fix(<app>): ...` shadowrun 스타일
- HANDOFF.md "## 최신" 은 짧게 유지 (1~3 메시지). 처리됐으면 "## 이력" 으로
- raw-images 는 git 에 그대로 commit (50~100MB 정도, GitHub 한도 안)
- 마케팅 컷은 `/marketing/` (앱스토어 1번 슬롯), 출시할 때 ASC 에 사용자가 직접 업로드
