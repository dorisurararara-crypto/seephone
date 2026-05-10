---
name: 이니셜전문가 앱 진행 상황 (2026-05-06)
description: ~/devapp/initialexpert. 광고 이니셜 디코딩 검색 앱. 데이터/Flutter/광고 다 준비됨, AdMob 키 + 풀크롤만 남음.
type: project
originSessionId: 1bbbb74b-68ef-4424-a77b-1dd776c014d4
---
# 이니셜전문가 (com.ganziman.initialexpert)

**컨셉**: 인터넷 광고에 자주 등장하는 이니셜 표기 (ㅇㅌ성형외과, ㅇㅌㅊ 원장) 의 실명을 디코딩 검색하는 앱. v1.0 = 의료(성형/피부), v1.1+ = 학원·쇼핑·부동산 확장.

**Why**: 사용자가 눈밑지방재배치 알아보다가 친구·커뮤니티에서 ㅇㅌㅊ 원장 들었는데 매번 직접 검색하기 번거로워서. 의료 한정 X, 인터넷 익명 표기 디코더 일반화 가능.

**How to apply**: 다음 세션 "이니셜전문가 이어서" 또는 "체크해줘" 시 이 메모 + 아래 진행 상황 기준으로 재개.

## 결정 완료 (2026-05-06)
- 앱 이름: **이니셜전문가** / Bundle ID: `com.ganziman.initialexpert`
- 데이터 소스: HIRA 공공데이터 + 1차 출처(병원 홈페이지) 직접 크롤. 모두닥/굿닥/강남언니 코드레벨 차단.
- 회색지대 7개 가드레일 결정 완료 (개인정보, 명예훼손, DB권, robots.txt, 의료광고, 저작권, 부하)
- 디자인: 화이트 + 네이비(#1D4ED8) + 민트(#5ECDA8) + Pretendard, 다크모드 지원
- 7개 화면: 면책동의/튜토리얼/검색/결과/상세/폴더/설정
- 매칭 점수: 카테고리(필수) + 시술키워드(30) + 시도(20)+시군구(10) + 병원이니셜(20) + 의사이니셜(30)
- 결과: 5개 카드. 매칭도 점수. 1등 민트 강조. 면책 한 줄. 외부링크 = 출처 텍스트만 클릭가능.
- 수익: AdMob (App Open + 검색결과 배너 + 10검색마다 전면 + 보상형) + IAP $4.99 영구제거
- 보상형 광고 1개 시청 = 3시간 광고 제거
- 의료/금융 카테고리 차단 (의료광고법 회피)
- 문의: dorisurararara@gmail.com

## 데이터 확보
- HIRA 병원정보 (15001698) + 의료기관별상세 (15001699) API 활성화 ✅
- 네이버 검색 API ✅
- 키 위치: `~/devapp/initialexpert/.env` (gitignore)
- **전국 6,308건** (성형외과 1,116 + 미용기관(dgsbjtCd=8) 5,192)
- 강남구 미용기관 903건, hospUrl 있음 267건
- 광고 자주 보는 곳 다 매칭: 오라클·그랜드·톡스앤필·디에이·반니·땡큐·아이디 등
- 시범 의사 데이터: data/sample_doctors.json (50명 — 1mm/그랜드/오라클/디에이)

## Flutter 코드 (~/devapp/initialexpert/)
- ✅ pubspec: shared_preferences + url_launcher + google_mobile_ads + in_app_purchase
- ✅ lib/main.dart, models/doctor.dart, data/doctor_repository.dart
- ✅ screens/search_screen.dart, result_screen.dart, detail_screen.dart
- ✅ services/ad_service.dart (AdMob 통합 — 테스트 ID 사용 중)
- ✅ services/iap_service.dart (IAP 통합)
- ⏳ screens/folder_screen.dart, settings_screen.dart, onboarding_screen.dart
- ✅ flutter analyze 통과, iPhone 17 Pro 시뮬 빌드 + 작동

## 자동 크롤링 한계 (2026-05-06)
- 시도: gpt-4o-mini로 generic 의료진 페이지 자동 추출 → **0명 추출** (모든 종합병원/SPA)
- 원인: 사이트 구조 다양 + JS 렌더링 의존 + 의료진 페이지 path 천차만별
- 해결: Anthropic Claude Sonnet 4.6 으로 교체 + 의료진 page URL 사이트맵 활용 → 정확도 ↑

## 사용자 대기 큐
1. **AdMob 광고 ID 4개** (배너/전면/보상형/AppOpen) — Bundle ID `com.ganziman.initialexpert` 등록 후
2. **Anthropic Claude API 키** (옵션) — 풀크롤 정확도 ↑
3. ASC 앱 등록 (자동 진행 가능, 키 들어오면)

## 다음 단계
- AdMob ID 들어오면 services/ad_service.dart 의 ID 교체 + Info.plist 추가 + 빌드 재
- ResultScreen 의 _AdBanner placeholder를 진짜 BannerAd 위젯으로 교체
- 검색 화면 _search() 에 검색카운터 + 10번마다 광고 선택 다이얼로그
- ASC 앱 등록 + IAP 등록 + IPA 빌드 + 외부 베타 ganzitester 그룹 자동 제출
- v1.1: 풀크롤 + 폴더/설정/온보딩 화면 추가

## 주요 파일
- 데이터: ~/devapp/initialexpert/data/cosmetic_all.json (5192건)
- 시범: ~/devapp/initialexpert/data/sample_doctors.json (50명)
- 키: ~/devapp/initialexpert/.env
- 디자인 목업 HTML: ~/devapp/initialexpert/mockup.html
- 시뮬 스크린샷: ~/devapp/initialexpert/screenshot_*.png
