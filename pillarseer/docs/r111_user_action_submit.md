# R111 — 사용자 마지막 1 클릭 가이드 (ASC 웹)

## 왜 사용자 클릭?

ASC API 가 거절 직후의 첫 resubmit 만큼은 PATCH 로 자동화 거부 (Apple 의 의도된 friction). 모든 데이터는 이미 patch 완료 — 버튼 1개만 사용자가 누르면 끝.

| 항목 | 상태 |
|---|---|
| 새 빌드 1.0.0+77 | ✅ ASC VALID, version 에 attach |
| App name (K-pop lead) | ✅ patched |
| Subtitle | ✅ patched |
| Description / Keywords / promotionalText | ✅ patched (ko + en-US) |
| Category Entertainment | ✅ patched |
| Notes for Review (영문 차별화 설명) | ✅ patched |
| Privacy Policy URL · Support URL | ✅ 유지 |
| usesIdfa / contentRights / encryption | ✅ patched |
| IAP premium pack | ✅ READY_TO_SUBMIT, bundle |

## 클릭 절차 (5 step, 30초)

1. https://appstoreconnect.apple.com 로그인 (Apple ID: `zkxmel@naver.com`)
2. **My Apps** → **Pillarseer** 클릭
3. 좌측 메뉴 **App Store** → **1.0.0 Prepare for Submission** (또는 Rejected 표시)
4. 페이지 최상단 우측 **"Submit for Review"** (또는 "Add for Review") 버튼 클릭
5. 팝업 export compliance / content rights / advertising identifier 질문 3개:
   - Export Compliance: **No** (we already set usesNonExemptEncryption=false)
   - Content Rights: **DOES_NOT_USE_THIRD_PARTY_CONTENT** (이미 set)
   - IDFA / Advertising Identifier: **No** (we already set usesIdfa=false)

→ 제출 끝. **WAITING_FOR_REVIEW** 진입.

## Resolution Center "Reply" 도 같이 paste 권장

위 5번 클릭 끝나면 같은 페이지의 좌측 **"App Review"** 또는 **"Resolution Center"** 섹션 진입:

1. 거절 메시지 (Guideline 4.3a) 아래 **Reply** 버튼
2. `pillarseer/docs/appeal_4_3_resolution_reply.md` 의 **영문 본문** paste
3. Send

→ 리뷰어가 Notes for Review + Resolution Center reply 양쪽에서 같은 차별화 메시지를 보게 됨. 4.3(a) 통과율 ↑.

## 그 다음

24~48 시간 안에 Apple 응답. 결과:
- **Approved** → 🎉 App Store 라이브 (사용자 release 클릭 X — `releaseType: AFTER_APPROVAL`)
- **Rejected again** → Resolution Center 응답문 추가 + 필요 시 App Review Board appeal 검토

## ⚠️ 주의

- 시뮬에서 새 스크린샷 캡쳐 후 ASC 에 업로드 권장 (현재 스크린샷 7장은 R110 시절 — 일반 사주 화면). 새 K-pop 차별화 스크린샷이 있으면 4.3(a) 통과율 더 ↑. 단, 시뮬 사용 금지 mandate 가 있어서 **실기기 캡쳐 권장**. 스크린샷 교체 없이도 resubmit 자체는 가능.
