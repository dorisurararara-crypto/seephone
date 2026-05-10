---
name: 이미지 dimension 한계 — 스크린샷·생성 PNG Read 자제
description: iOS 시뮬 스크린샷·AI 생성 PNG 를 Read 로 잔뜩 보면 "image exceeds 2000px dimension limit" 에러로 세션 폭사. 시각 확인은 1-3장 제한.
type: feedback
originSessionId: 65198821-57e9-40a2-b42d-d1b65b6f5042
---
## 룰
- iOS 시뮬 스크린샷 (`xcrun simctl io booted screenshot /tmp/X.png`) → 저장만 하고 **Read 는 결정적 검증 순간 1-3장만**
- AI 생성 raw-images/* PNG (1024×1024, 1080×1920) → 존재·크기는 `ls -la` 로 확인, Read 는 큐레이션 결정 직전 1-2장만
- 시각 검증 필요 시 → 사용자에게 경로 주고 직접 확인 부탁이 가장 안전
- 텍스트 로그 우선: `xcrun simctl spawn booted log show/stream --predicate 'process == "Runner"'`

**Why:** Anthropic API 의 multi-image 요청은 이미지당 2000px dimension 제한. iOS 시뮬 스크린샷 (보통 2556×1179) + 생성 PNG (1024+) 를 한 세션에 여러 장 Read 하면 토큰 폭증 + dimension 한계 hit → 세션 죽고 /compact 로만 복구. 이미 2026-04-29 발생.

**How to apply:**
- 한 턴에 이미지 Read 최대 2-3장. 그 이상 필요하면 한 번 메모리에 핵심 상태 저장하고 "이미지 예산 소진" 플래그
- 시나리오 처음 (intro) + 마지막 (result) 2장이면 검증 충분. 중간 화면은 텍스트 로그로
- raw-images batch 큐레이션 시: ls 로 파일 목록·크기 → 의심나는 1-2장만 Read → 나머지는 사용자에게 경로 전달
- 큰 PNG 캡처가 필요하면 `sips -Z 800 input.png --out small.png` 로 다운스케일 후 Read
- shadowrun 메모리 `feedback_simulator_screenshots.md` 도 같은 룰 (글로벌 develop 메모리)

**복구:** /compact 로 컨텍스트 압축. 압축 직후엔 이전 이미지가 사라져 다시 Read 가능. 그래도 같은 실수 반복 금지.
