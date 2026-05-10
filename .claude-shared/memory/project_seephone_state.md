---
name: seephone 프로젝트 현재 상태
description: 빡신·동공지진탐지기·분노발전소 3개 앱 모노레포. 2026-04-29 야간 자율 작업 시점 전체 상태.
type: project
originSessionId: 65198821-57e9-40a2-b42d-d1b65b6f5042
---
## 프로젝트 개요
1인 개발 / 서버 0원 / Flutter 크로스플랫폼 / 한국 시장 블루오션 / 자발적 바이럴 = 4가지 기준의 3개 앱 묶음.

**Why:** 사용자가 빡신 (디지털 무당) 으로 시작 → pupil (동공 지진 탐지기) + anger (분노 발전소) 까지 묶어서 자율 모드로 한 번에 만들기로 결정.

**How to apply:**
- 모노레포 위치: `/Users/seunghyeon/seephone/`
- GitHub: `https://github.com/dorisurararara-crypto/seephone` (private)
- 머신: Mac mini (Flutter 빌드 + 배포) + Windows + RTX 5070 Ti (AI 이미지 생성)

## 디렉토리 구조 (2026-04-29 기준)
```
/seephone
├── CLAUDE.md           # 양쪽 머신 Claude 작업 지침
├── HANDOFF.md          # Mac ↔ Windows 메시지 큐 (30분 폴링)
├── APPS.md             # 3앱 개요 + 사용자 액션 항목
├── PRIVACY_POLICY_TEMPLATE.md
├── prompts/            # 이미지 생성 batch 요청 (Mac → Windows)
├── raw-images/         # AI 생성 결과 (batch_001~006 + 002b)
├── marketing/          # 앱스토어 1번 슬롯 마케팅 컷 3장
├── sfx-shared/         # 마스터 SFX 라이브러리 24개 + manifest.json
├── docs/privacy.md     # GitHub Pages 호스팅용 (사실 gist 사용)
├── scripts/            # generate_sfx.py + register_bundle_ids.rb
├── content-draft/      # 멘트 1차 큐레이션 작업
├── bbaksin/            # 1번 앱 (빡신)
├── pupil/              # 2번 앱 (동공 지진 탐지기)
└── anger/              # 3번 앱 (분노 발전소)
```

각 앱 디렉토리:
```
{app}/
├── lib/
│   ├── main.dart, app.dart, router.dart
│   ├── screens/        # home/ritual/result + 앱별 변형
│   ├── services/       # share_service, sound_service, (lie_detector|anger_calc)
│   ├── state/          # message_repo (bbaksin only)
│   └── theme/          # theme_style + 5 테마 (bbaksin only)
├── assets/
│   ├── icon/           # 앱 아이콘
│   ├── sfx/            # SFX (sfx-shared 에서 manifest 따라 자동 sync)
│   ├── effects/        # 굿판 이펙트, 클라이맥스 (bbaksin)
│   ├── backgrounds/    # 도깨비 캐릭터 (bbaksin V2)
│   └── data/           # 멘트 JSON (bbaksin only)
├── ios/Runner/Info.plist  # GADApplicationIdentifier (테스트), camera 권한 등
├── ios/ExportOptions.plist  # TestFlight 제출용 (app-store, automatic, Q6H9HCTK6W)
└── scripts/            # _helpers.rb, deploy_testflight.sh 등 (앱별 APP_ID/GROUP_ID wire됨)
```

## 3개 앱 상태 (2026-04-29 01:25)

### 빡신 (bbaksin) — 가장 완성도 높음
- 5 테마 시스템 (V1 Classic / V2 Kitsch / V3 Minimal / V4 Y2K / V5 Mystic 기본)
- 설정 화면 + Pro 게이트 + 잠금/해금 (long-press dev toggle)
- 멘트 120개 (assets/data/messages.json) + 카테고리 키워드 매칭
- 캡처/저장/공유 (screenshot + gal + share_plus)
- RitualScreen 클라이맥스 트랜지션 (200ms fadeIn + 1500ms scale 1.2x → ResultScreen smoke ambient 800ms)
- SFX: 한국 전통 (jing 종, 북) + magical (burst, chime, drone)
- iOS 시뮬 빌드+런 ✅ 검증
- IPA 빌드 → TestFlight 업로드 ✅ (Apple processing 중)

### pupil (동공 지진 탐지기)
- 카메라 + ML Kit FaceDetector 연결 (실 frame 분석은 fallback 사용 중)
- LieDetector 결정론적 점수 (blink + head + smile + question hash)
- 결과 화면 progress 진도 magnitude 0~10 + 색상별 verdict
- ML Kit ARM64 시뮬 미지원 (실기기 OK)
- IPA 빌드 ✅ + TestFlight 업로드 ✅

### anger (분노 발전소)
- sensors_plus 가속도 + 터치 측정 10초
- AngerCalc W 환산 + 7단계 비유 멘트 (모기 ~ 발전소)
- 강도별 SFX ambient 전환 (elec_buzz_low ↔ high)
- iOS 시뮬 빌드+런 ✅ 검증
- IPA 빌드 ✅ + TestFlight 업로드 ✅

## 자율 모드 누적 결과 (Windows 측 AI 생성 — 6 batches + 자율 변종)
- 48장 생성, 28장 채택·적용
- 생성 모델: SDXL (FLUX 16GB VRAM 부족으로 SDXL 채택)
- 검증 패턴: 짧은 prompt + "korean" 키워드 빼기 (CLIP 77 토큰 안)
