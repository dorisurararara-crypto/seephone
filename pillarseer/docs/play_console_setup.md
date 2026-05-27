# Play Console 첫 셋업 가이드 — pillarseer

## 사용자가 한 번만 해야 하는 일 (자율 자동화 불가 영역)

### Step 1 — Play Console 에 앱 등록

1. https://play.google.com/console 로그인 (구글 계정 — 다른 앱들 이미 같은 계정)
2. **앱 만들기** 클릭
3. 입력:
   - **앱 이름**: `Pillarseer`
   - **기본 언어**: 한국어 (대한민국) — ko-KR
   - **앱 또는 게임**: 앱
   - **무료 또는 유료**: 무료
4. 정책 동의 체크 2개 (개발자 프로그램 정책 + 미국 수출법) → **앱 만들기**

→ 앱 생성 완료 시 패키지 이름 자동 `com.seephone.pillarseer` 인식 (AAB 업로드 시 매칭).

### Step 2 — 서비스 계정 생성

1. https://console.cloud.google.com 접속 (Play Console 과 같은 구글 계정)
2. 프로젝트 선택 (`protagonist` 만들 때 썼던 거 재사용 가능) — 없으면 새로 생성
3. 좌측 메뉴 **IAM 및 관리자** → **서비스 계정** → **+ 서비스 계정 만들기**
   - 이름: `pillarseer-publisher`
   - 역할: (비워두기, Play Console 에서 권한 부여)
   - **완료**
4. 만들어진 서비스 계정 클릭 → **키** 탭 → **키 추가** → **새 키 만들기** → **JSON** → 다운로드
5. 다운로드된 JSON 을 ~ /.googleplay/ 로 이동:
   ```bash
   mv ~/Downloads/<생성된 키 파일>.json ~/.googleplay/pillarseer-key.json
   chmod 600 ~/.googleplay/pillarseer-key.json
   ```

### Step 3 — Play Console 에서 서비스 계정에 권한 부여

1. https://play.google.com/console 다시 진입
2. 좌측 메뉴 **설정** → **API 액세스**
3. 위에서 만든 서비스 계정 (`pillarseer-publisher@...`) 옆 **앱 권한 관리** 클릭
4. **앱 추가** → Pillarseer 추가
5. 권한 체크:
   - ✅ 앱 출시본 만들고 수정
   - ✅ 트랙에 출시본 게재
   - ✅ 스토어 등록 정보, 가격 책정, 배포 관리
   - ✅ 앱 메타데이터 보기
6. **사용자 초대** / **변경사항 저장**

→ 서비스 계정 셋업 끝. 이후 모든 배포는 자동.

### Step 4 — 사용자가 끝났다고 알려주면 자동 진행

다음 명령 하나면 끝:
```bash
cd ~/seephone/pillarseer
python3 scripts/play_listing_patch.py   # K-pop lead listing patch
python3 scripts/deploy_play.py --aab ~/Downloads/pillarseer-1.0.0-77.aab --track internal
```

`internal` 트랙 = 내부 테스트 (즉시 게재, 사용자만 접근). 통과 검증 후:
```bash
python3 scripts/deploy_play.py --aab <같은 파일> --track production
```

---

## 또 사용자가 챙겨야 할 것 (Play Console 첫 출시 필수)

Play Console 은 첫 출시 시 listing 외에도 챙겨야 할 필수 항목 다수:

| 항목 | 어디서 | 자동화 가능? |
|---|---|---|
| 앱 이름 / 짧은 설명 / 자세한 설명 | scripts/play_listing_patch.py | ✅ |
| 스크린샷 (전화기 4~8장) | Play Console 웹 수동 업로드 | ❌ 첫 출시 수동 권장 |
| Feature graphic (1024×500) | Play Console 웹 | ❌ |
| 앱 아이콘 (512×512) | Play Console 웹 | ❌ |
| 카테고리 (Lifestyle / Entertainment) | Play Console 웹 | ❌ 첫 출시 수동 |
| 콘텐츠 등급 설문 | Play Console 웹 (5분) | ❌ 답변 사람만 가능 |
| 타겟 사용자 / 콘텐츠 (광고 여부 등) | Play Console 웹 | ❌ |
| 데이터 안전 설문 (Data safety) | Play Console 웹 (10분) | ❌ |
| 정부 앱 / 금융 앱 / 뉴스 앱 여부 | Play Console 웹 | ❌ |
| 개인정보 처리방침 URL | scripts (가능) | ✅ |
| 가격 (무료) | Play Console 웹 | ❌ 자동 (무료 기본) |

→ Play Console 웹에서 모든 "초안" 빨간 점 사라질 때까지 채워야 첫 출시 심사 진입.

---

## 콘텐츠 등급 설문 권장 답변

iOS 4+ 와 같은 등급 목표 → **모두에게 적합** (Everyone). 답변:

- 폭력: 없음
- 성적 콘텐츠: 없음
- 욕설/거친 언어: 없음
- 통제 약물: 없음
- 도박 시뮬레이션: 없음
- 사용자 생성 콘텐츠 공유: 없음 (서버 공유 X)
- 위치 공유: 없음
- 결제 (디지털 구매): **있음** (프리미엄팩 IAP)

→ 결과 "모두에게 적합" 또는 IARC 3 PEGI 3 가 예상.

## 데이터 안전 설문 권장 답변

- 데이터 수집: **수집하지 않음** (RevenueCat / AdMob 미구현, 사용자 데이터 서버로 안 보냄)
- 데이터 공유: 없음
- 데이터 보안: 전송 중 암호화 (HTTPS) — 적용
- 사용자 데이터 삭제 요청: 가능 (앱 데이터 = 디바이스 로컬만 → 앱 삭제 = 데이터 삭제)
