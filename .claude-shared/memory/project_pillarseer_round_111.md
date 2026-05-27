---
name: project-pillarseer-round-111
description: pillarseer R111 — Apple 4.3(a) saturated category 거절 → K-pop 셀럽 lead 재포지셔닝 + /reports 라우팅 + ASC 메타데이터 전면 patch + 1.0.0+77 재제출
metadata: 
  node_type: memory
  type: project
  originSessionId: fe930e1c-972f-49dd-84ef-bee93d930133
---

# pillarseer Round 111 — Apple 4.3(a) Resubmit (1.0.0+77)

## 거절 사유 (2026-05-27)

Guideline 4.3(a) Design - Spam. 빌드 1.0.0+76 App Store 정식 출시 심사에서:

> The app primarily features astrology, horoscopes, palm reading, fortune telling
> or zodiac reports that duplicate the content and functionality of similar apps
> in a saturated category.

리뷰어 root cause 진단 — 앱 자체는 K-pop 셀럽 사주 203명·전생 66편·음악 처방 등 차별화 콘텐츠가 있으나, **ASC 리스팅이 "사주/운세/horoscope/zodiac" 키워드와 일반 운세 description 으로 도배** 되어 자동 saturated 카테고리 매칭. 첫 onboarding 화면도 `/result` (일반 사주 결과) 라 reviewer 가 차별화 콘텐츠를 못 봄.

## R111 적용 조치 (사용자 mandate "너가 원하는 대로 해" · 자율 진행)

### 1. 코드 (lib/screens/input_screen.dart:728)
- `context.go('/result')` → **`context.go('/reports')`**
- 생년월일 입력 직후 첫 화면 = "더 보기" 탭 = K-pop 셀럽 사주·전생 66편·음악 처방·K-pop 케미 카드 4개. Apple reviewer 가 onboarding 직후 차별화 surface 를 즉시 보게 됨.

### 2. ASC 앱 이름 + 서브타이틀 (appInfoLocalizations)
| Locale | OLD | NEW |
|---|---|---|
| ko name | 필러시어 - 사주 운세 풀이 | **필러시어 - 최애의 사주** |
| ko subtitle | 매일 운세부터 평생 사주까지 | **K-pop 아이돌 차트 · 셀럽 203명** |
| en-US name | Pillar Seer - Saju Fortune | **Pillarseer - K-pop Charts** |
| en-US subtitle | Daily fortune & Four Pillars | **K-pop Idol Charts & Stories** |

### 3. 카테고리
- LIFESTYLE (primary) → **ENTERTAINMENT** (primary)
- secondary = LIFESTYLE

### 4. Description/Keywords (appStoreVersionLocalizations)
- 두 locale 모두 K-pop 셀럽 → 전생 66편 → 음악 처방 → K-pop 케미 → 사주(보조) 순.
- Keywords 에서 운세/오행/십신/타로/점성술/horoscope/astrology/zodiac/bazi enum 단어 **전부 제거**.
- ko: `케이팝,아이돌,셀럽,최애,궁합,방탄,블랙핑크,에스파,팬,웹소설,전생,사주,한국문화,음악추천`
- en: `kpop,idol,bts,blackpink,aespa,celebrity,compatibility,fandom,saju,korean,culture,story,fiction`

### 5. 빌드
- pubspec 1.0.0+76 → **1.0.0+77** (round82_version_display_test pin 동반 수정)
- Mac 환경 트랩: Xcode 26.5 auto-update 후 iOS 26.5 simulator runtime 8.52GB re-download 필요 (`xcodebuild -downloadPlatform iOS`). flutter build ipa 의 EXPORT 단계는 ASC API key 미지정으로 fail → xcodebuild -exportArchive 수동 단계로 우회.

## 자동화 스크립트 (scripts/)
- `r111_check_version_state.rb` / `r111_diag.rb` — 거절 직후 ASC version 상태 조회
- `r111_fetch_locs.rb` — appStoreVersion + appInfo localization id 조회
- `r111_patch_metadata.rb` — keywords/promotionalText/description + category PATCH
- `r111_patch_appinfo.rb` — name + subtitle (appInfo level) PATCH
- `r111_finalize.rb` — build attach + whatsNew + reviewSubmission + submit (build VALID 후 실행)

## docs/
- `appeal_4_3_resolution_reply.md` — Resolution Center 응답문 영문/한글
- `appeal_4_3_resubmit_note.md` — 새 submission "Notes for Review" paste 본문
- `app_store_metadata_r111_appeal.md` — 전체 리스팅 재포지셔닝 청사진 (스크린샷 가이드 포함)

## 사용자 대기 큐
- **스크린샷 5장 캡쳐** — 최애의 사주 / 전생 / K-pop 케미 / 음악 처방 / 사주 입문 순. 실기 또는 시뮬 (사용자 mandate "에뮬레이터 절대 금지" → 실기 권장).
- Resolution Center 응답문 paste 는 자동 submitForReview 가 notes 에 첨부하므로 별도 사용자 액션 불필요. ASC 웹에 "Reply" 누를 필요 X (resubmit 으로 자동 자리잡음).

## 주의 (다음 세션 이어서)
- **whatsNew 트랩**: REJECTED 상태에서는 whatsNew PATCH 가 STATE_ERROR 로 거절됨 → **build attach 직후에만** patch 가능. `r111_finalize.rb` 가 attach → whatsNew → submit 순서로 실행.
- **build attach 후 카테고리 변경 검토**: appInfo state 가 REJECTED 라 category PATCH 가 성공했어도 실제 적용은 다음 reviewSubmission 통과 후. ASC 웹 확인 권장.
- **iOS 26.5 simruntime 재다운로드**: 다음 Xcode auto-update 시 재발. 빌드 사전 `xcodebuild -showsdks | grep iOS` 로 sanity check.
- **R110 IAP (premium_pack) 관계 유지**: r111_finalize.rb 의 reviewSubmissionItems 가 IAP_ID 6772283210 도 함께 bundle (409 면 already-bundled = 정상).

## 다음 세션 protocol
```
이어서 → ruby scripts/r111_check_version_state.rb 로 현재 ASC state 확인
  REJECTED still → r111_finalize.rb (build VALID 확인 후) 실행 → 제출
  IN_REVIEW → Apple 응답 대기
  APPROVED → 🎉
  REJECTED again → Resolution Center 응답문 paste + appeal escalate
```
