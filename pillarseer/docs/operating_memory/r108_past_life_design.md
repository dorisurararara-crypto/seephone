# R108 ② — 전생 스토리 인터넷소설 장편화 design doc

**ground truth.** R108 item ② 의 톤·구조·집필 사양. 새 세션은 이 문서부터 읽는다.

## 사용자 mandate (verbatim)
- "지금 전생 스토리 유치하고 내용도 없어. 아예 웃긴 느낌으로 가거나 아예 긴 내용이 있는 소설로 가거나. 내용도 지금의 최소 10배는 넘어야 돼. 약간 팬픽 느낌으로다가."
- "긴 소설로 가자, 팬픽인데 장르 다양하게, 최소 20-30분, 늑대의 유혹·그놈은 멋있었다 말고도 유명한 팬픽 느낌."
- 구조: "내가 생각해보니까 66편 만드는게 좋을거 같아." → 현 66 arc 슬롯 전부를 장편으로.
- 워크플로: "방향만 주면 Claude 가 초안 → 사용자 검토." 항목마다 샘플→승인→확장.

## 톤 사양 (절대)
- **인터넷소설 / 팬픽 톤** — 늑대의 유혹·그놈은 멋있었다 식. 했다체 narration + 대화체. 짧고 강한 문장. 감정 폭발. 운명적 만남, 캐릭터성 강한 상대($celebName), 반전·여운.
- **분량**: 편당 20-30분 읽기 (~13,000자+). 현재 arc 의 ~20배.
- **변수**: `$userName`(사용자 이름), `$celebName`(최애) 만 본문 치환. $era/$userRole/$celebRole 식 잘게 쪼갠 템플릿 폐기 — 장편은 배경·역할을 prose 에 고정.
- **장르 다양화**: 같은 관계 8편도 시대·장르 다르게 (경성/무협/현대 아이돌 RPF/판타지/SF 윤회/사극 궁중/근현대 등).
- 전생 = fiction. 사주 해석 단정 불필요 — 사주 관계(충/합/원진…)를 *이야기 결*로만 쓴다. 단 메인 앱의 사주 계산은 불변.
- 마지막에 **전생→현생 연결** 한 문단 (샘플의 "100년 뒤…" 식) — 팬심·여운 자극.

## 66 arc 구조 (현 past_life_pool.json `story_arcs`)
9 관계 키 × 8 (neutral 2) = 66:
| 관계 | 결 | 장편 톤 |
|---|---|---|
| wonjin (원진) | 악연·애증 | 애증 다크로맨스 / 복수 스릴러 |
| dohwa (도화) | 매력·끌림 | 로맨스 (경성/현대 RPF/판타지 등) |
| yeokma (역마) | 길·이동 | 로드무비 / 만남과 이별 |
| cheoneul (천을) | 위기의 은인 | 힐링·감동 / 구원 |
| gongmang (공망) | 빈자리의 정 | 잔잔 멜로 / 한 사람만 남는 |
| hap (합) | 잘 맞음 | 소울메이트 / 우정·로맨스 |
| chung (충) | 부딪침 | 라이벌물 (무협/경연/검객) |
| hyeong (형) | 맹세 | 의형제 느와르 / 전우애 |
| neutral (2) | 스쳐간 인연 | 짧은 여운 (다른 8편보다 짧아도 OK) |

`past_life_service.dart` 가 사주 관계 → 관계 키 매핑, 그 안에서 arc 선택. 매핑 로직 유지.

## 승인된 샘플 (gold standard) — dohwa_01 대체본

### 「경성 1929 — 그해 겨울의 모던보이」 (도화 / 로맨스)

**一.**
$userName이 그 남자를 처음 본 건, 진눈깨비가 흩날리던 경성역 앞이었다.
검은 인버네스 코트. 비뚜름하게 눌러쓴 중절모. 담배를 문 채 전차를 기다리는 그 남자 주위로만 사람들이 비켜 섰다. 마치 그 자리에 보이지 않는 선이라도 그어진 것처럼.
"…뭘 봐."
들켰다. $userName은 황급히 고개를 돌렸지만 늦었다. 남자가 담배를 툭 떨어뜨리고 구둣발로 비벼 끄더니, 곧장 이쪽으로 걸어왔다.
"학생. 방금 나 봤지." / "아, 아니요." / "봤잖아."
코앞이었다. 남자의 그림자가 $userName의 얼굴을 다 덮었다. 그가 천천히 허리를 숙였다. 모자챙 아래 눈이, 웃지 않는데도 웃는 것 같았다.
"기억해 둬. 다음에 또 보면 — 그땐 모른 척 안 해 줄 거니까."
전차가 왔다. 남자는 그 말만 남기고 올라타 버렸다. $userName은 그 자리에 한참을 서 있었다. 손에 쥔 책 보따리가 다 젖는 줄도 모르고. 그게 $celebName이었다. 경성 바닥에서 모르는 사람이 없다는 그 남자.

**二.** 소문은 많았다. 어느 부잣집 막내아들이라고도, 만주에서 흘러든 정체 모를 사내라고도. 종로 카페란 카페는 다 그의 단골이었고, 그가 한번 웃어 준 여학생은 사흘을 앓아눕는다고 했다. $userName은 코웃음을 쳤다 — 그 카페에 $celebName이 앉아 있기 전까지는. 하필 $userName이 일하는 카페였다. 그가 창가에서 손을 까딱였다. "여기 커피. 그리고 — 너." 그날부터 매일 같은 시간, 같은 창가, 커피 한 잔, 그리고 한마디씩. $userName은 끝까지 웃어 주지 않았다. 그게 $celebName을 미치게 한다는 걸 그땐 몰랐다.

**三.** 겨울이 깊던 밤, 카페 문을 닫고 나선 $userName 앞에 검은 코트가 기다리고 있었다. "데려다줄게." 처음으로 그가 이름을 불렀다 — 장난기 없는 목소리로. "$userName. 요 며칠 종로에 순사가 깔렸어. 밤길 혼자 다니지 마." 제 인버네스 코트를 벗어 $userName 어깨에 걸쳐 주었다. "한 번만. 오늘만 모른 척 받아 줘." 가로등 아래 진눈깨비가 또 흩날렸다. 처음 만난 날처럼. $userName은 알아 버렸다 — 유치하다 비웃던 이 남자를 어느새 매일 기다리고 있었다는 걸.

**四.** $celebName의 정체. 부잣집 아들도 떠돌이도 아닌 — 독립운동 자금 연락책. 매일 같은 창가에 앉은 이유는 거리가 가장 잘 보여서. $userName에게 말을 건 것도 처음엔 위장이었다. "처음 사흘은. …그다음부턴 네가 안 웃어 줘서. 웃겨 주고 싶었어. 진심으로." $userName은 울었다. $celebName은 천천히 끌어안았다. "이 일 끝나면, 다 끝나면 — 한량처럼 살게. 너 옆에서. 약속해."

**五.** 그 약속은 지켜지지 못했다. 이듬해 봄 경성역 검거, $celebName은 마지막 문서를 동지에게 넘기고 순사들을 자기 쪽으로 끌고 갔다 — 처음 $userName을 만났던 그 자리에서. 남은 건 검은 코트 한 벌과 쪽지. 『$userName에게. 다음 생엔 위장 같은 거 없이 만나자. 처음부터 웃겨 줄게. 네가 질리도록. — 그러니까 그땐, 한 번에 웃어 줘.』 그리고 100년 뒤, $userName은 진눈깨비 날 길에서 검은 코트의 남자를 본다. 이름을 모르는데 심장이 먼저 안다. *…아, 또 너구나.* 이번 생엔, $userName은 그를 보고 처음부터 웃는다.

> 위 샘플은 채팅 압축본. 실제 본편은 각 절을 1.5~2배 확장(대사·심리묘사·장면 추가)해 20-30분 분량. 톤·구조·전생→현생 마무리는 이 샘플이 기준.

## 집필 진행 방식
- harness generator 배치 (관계당 8편 또는 4편 단위) + codex QA. 「경성 1929」가 gold standard.
- codex 채점: 인터넷소설 톤 일관 / AI 슬롭 0 / 분량 / $변수 templating 정확 / 전생→현생 마무리 / 같은 관계 내 장르 변별.
- past_life_pool.json 스키마: 장편 arc = `{id, relation, genre, title, era, chapters: [...] }` (또는 본문 string). past_life_service / past_life_screen 정합.
- 멀티 세션. 세션마다 N편씩, 완료분 commit.

## 회귀 가드
- `past_life_service` arc 선택·관계 매핑 로직 불변.
- 신규 test: $변수 templating 0누락, 한글/영문 leak, 관계 매핑 유지.
- `flutter test` 전체 PASS, analyze 0.

---

# R108 ② 진행 상황 + 남은 sprint 명세 (Sprint 0+1 완료 후 append)

## 완료
- **Sprint 0** (commit 47a8753) — 인프라. past_life_pool.json 66 arc 에 longform 메타
  (relation/genre/era/title/logline/estReadMinutes) 주입. PastLifeService 에
  `_composeLongform` + `_isValidLongformArc` 분기, `PastLifeScenario`/`PastLifeChapter`
  모델 확장 (additive). past_life_screen 에 `_LongformBody`/`_MetaChip` 장편 리더 UI.
  `test/r108_past_life_longform_test.dart` 신규. 관계 매핑·구 슬롯 fallback 불변.
- **Sprint 1** (commit 3844f9a) — dohwa 8편 인터넷소설 장편 집필. 편당 5,800~8,800자,
  5챕터 + epilogue. 기존 슬롯 arc(~460자)의 12~19배. codex 4 dim audit 4라운드.

## 아키텍처 결정 (다음 세션 필독)
- **per-arc 듀얼 스키마**: 각 arc 는 longform 메타를 항상 갖되, 집필이 끝난 관계의
  arc 에만 `format:"longform"` + `chapters[]` + `epilogue` 가 붙는다. service 의
  `_composeFromStoryArc` 가 `arc['format']=='longform'` 이면 `_composeLongform` 으로
  분기. 미집필 arc 는 기존 `paragraphs`(gi/seung/jeon/gyeol) + `modernPunchlineByKind`
  로 동작 — 회귀 가드(r104_arc / r103_resolution_motif / r102_story_structure 등이
  모든 arc 의 paragraphs 를 직접 검사) 보존을 위해 기존 필드는 절대 삭제 금지.
- `build_longform_skeleton.py` 패턴: JSON 은 **1-space indent, trailing newline 없음**
  (원본 포맷). `json.dump(d, f, ensure_ascii=False, indent=1)`.
- 집필 본문은 `/tmp/dXX.py` 모듈 → `merge_dohwa_final.py` 식 병합 스크립트로 주입.
  병합 시 따옴표 balance 검사 (`body.count('"')%2`) 필수 — codex 가 닫는 따옴표
  누락을 hard B 위반으로 잡음.
- 분량 가드: `test/r108_past_life_longform_test.dart` 의 `longformWrittenRelations`
  set 에 집필 완료 관계를 추가하면 그 관계 arc 의 format/chapters/분량(총 글자
  ≥5,000)/챕터수(5~7)/title 유니크 가드가 enforce 된다. `longformCharFloor=5000`.
- codex goalpost 주의: dohwa 라운드에서 같은 텍스트가 round2 9.93~10.0 → round3+
  9.5~9.8 로 재채점 drift. 명백한 hard violation 만 수정하고 비재현 점수 하락은
  거부. ground-truth 룰 (예: 경성 1929 의 "100년" = design doc mandated) 을 audit
  프롬프트에 명시하면 codex 가 false-positive 를 철회함.

## 66편 장르 슬레이트 (집필 ground truth — Sprint 2~8)

### wonjin (원진 · 8편) — 애증 다크로맨스 / 복수 스릴러
| id | 장르 | 시대·배경 | 가제 |
|---|---|---|---|
| wonjin_01 | 애증 다크로맨스 | 1929 경성 | 적과의 동침, 경성 |
| wonjin_02 | 복수 스릴러 | 1980년대 서울 강남 | 네가 무너뜨린 것 |
| wonjin_03 | 무협 (정파 vs 사파) | 명나라 강호 | 검을 겨눈 정인 |
| wonjin_04 | 아이돌 RPF 다크 | 현대 K-POP 같은 소속사 | 데뷔조 마지막 한 자리 |
| wonjin_05 | 궁중 사극 (후궁 암투) | 조선 중기 궁궐 | 같은 임금을 두고 |
| wonjin_06 | SF 윤회 디스토피아 | 22세기 기억이식 도시 | 세 번째 삭제 |
| wonjin_07 | 느와르 (조직 배신극) | 1960년대 홍콩 | 형제였던 총구 |
| wonjin_08 | 빅토리안 고딕 | 1880년대 런던 저택 | 유산을 둘러싼 두 사람 |

### dohwa (도화 · 8편) — 로맨스 [Sprint 1 완료]
경성 모던 / 현대 아이돌 RPF / 하이판타지 / 청 무협 기방 / 1950s 할리우드 /
조선 사극 화원 / 이세계 환생 / 1990s 캠퍼스. (본문 확정 — past_life_pool.json 참조.)

### yeokma (역마 · 8편) — 로드무비 / 만남과 이별
| id | 장르 | 시대·배경 | 가제 |
|---|---|---|---|
| yeokma_01 | 대항해 로드무비 | 17세기 대항해 시대 | 항구마다 너였다 |
| yeokma_02 | 비단길 카라반 | 8세기 실크로드 사막 | 모래바람 속 길동무 |
| yeokma_03 | 미국 66번 국도 로드무비 | 1960년대 미국 루트66 | 다음 마을에서 봐 |
| yeokma_04 | 우주 항해 SF | 24세기 항성 간 무역선 | 정거장 7에서 |
| yeokma_05 | 근현대 기차 멜로 | 1970년대 한국 완행열차 | 완행열차의 동행 |
| yeokma_06 | 유랑극단 시대극 | 1930년대 조선 팔도 | 천막을 걷는 밤 |
| yeokma_07 | 역참 파발 사극 | 고려 말 개경~변방 | 소식을 나르는 사람 |
| yeokma_08 | 현대 배낭여행 로맨스 | 2010년대 유럽 일주 | 유레일패스의 끝 |

### cheoneul (천을 · 8편) — 힐링·감동 / 구원
| id | 장르 | 시대·배경 | 가제 |
|---|---|---|---|
| cheoneul_01 | 사극 도피 구원극 | 조선 후기 한양 | 숨겨 준 사람 |
| cheoneul_02 | 전란 피난 감동극 | 한국전쟁 1951 피난길 | 흥남부두의 손 |
| cheoneul_03 | 의료 휴먼드라마 | 현대 대학병원 | 응급실 새벽 3시 |
| cheoneul_04 | 판타지 치유사 | 마법 세계 변경 마을 | 숲의 약초사 |
| cheoneul_05 | 1930년대 다실 위로극 | 1935 경성 다방 | 따뜻한 차 한 잔 |
| cheoneul_06 | 설산 조난 생존극 | 20세기 초 히말라야 | 눈보라가 멈출 때까지 |
| cheoneul_07 | 우주 조난 SF 휴먼 | 근미래 궤도 정거장 | 산소가 절반 남았을 때 |
| cheoneul_08 | 현대 재난 휴먼드라마 | 2020년대 대지진 도시 | 잔해 속 목소리 |

### gongmang (공망 · 8편) — 잔잔 멜로 / 한 사람만 남는
| id | 장르 | 시대·배경 | 가제 |
|---|---|---|---|
| gongmang_01 | 1960년대 다방 잔잔멜로 | 1962 서울 음악다방 | 늘 비워 둔 그 자리 |
| gongmang_02 | 현대 심야 라디오 멜로 | 2010년대 심야 방송국 | 새벽 2시의 청취자 |
| gongmang_03 | 빈 미술관 잔잔극 | 1970년대 작은 화랑 | 관객 없는 전시 |
| gongmang_04 | 우주 등대 SF 멜로 | 먼 미래 항로 표지 스테이션 | 마지막 통신만 남은 |
| gongmang_05 | 등대지기 시대 멜로 | 1900년대 초 외딴 섬 등대 | 불을 끄지 않는 사람 |
| gongmang_06 | 현대 빈집 잔잔극 | 2020년대 재개발 동네 | 떠난 동네에 남은 둘 |
| gongmang_07 | 사극 텅 빈 객줏집 멜로 | 조선 후기 외딴 주막 | 매일 같은 방을 찾던 나그네 |
| gongmang_08 | 폐역 무대 잔잔극 | 1980년대 폐선 직전 간이역 | 마지막 열차가 서던 역 |

### hap (합 · 8편) — 소울메이트 / 우정·로맨스
| id | 장르 | 시대·배경 | 가제 |
|---|---|---|---|
| hap_01 | 사극 우정 소울메이트 | 당나라 장안 서점 거리 | 같은 책을 고른 사이 |
| hap_02 | 현대 밴드 결성 청춘극 | 2000년대 홍대 합주실 | 우리 밴드의 시작 |
| hap_03 | 우주 탐사 버디 SF | 근미래 행성 탐사대 | 같은 별을 보던 두 사람 |
| hap_04 | 무협 의기투합 | 송나라 강호 객잔 | 같은 가락의 두 협객 |
| hap_05 | 1920년대 파리 예술가 | 1925 파리 몽파르나스 | 같은 카페 구석 |
| hap_06 | 판타지 마법 콤비 | 마법 학원 세계 | 짝이 맞는 마법 |
| hap_07 | 현대 요리 버디극 | 2010년대 작은 식당 | 한 상을 차리던 사이 |
| hap_08 | 1960년대 우주개발 동료극 | 1969 발사 관제소 | 같은 카운트다운 |

### chung (충 · 8편) — 라이벌물
| id | 장르 | 시대·배경 | 가제 |
|---|---|---|---|
| chung_01 | 무협 검객 라이벌 | 명나라 강호 비무대회 | 맞붙은 두 검 |
| chung_02 | 현대 아이돌 경연 RPF | 현대 K-POP 서바이벌 무대 | 1위 자리를 두고 |
| chung_03 | 사극 화원 경합 | 조선 도화서 | 같은 어진을 그린 두 화원 |
| chung_04 | 레이싱 스포츠 드라마 | 1980년대 F1 서킷 | 마지막 코너의 두 사람 |
| chung_05 | 판타지 검술 토너먼트 | 검과마법 왕국 무투대회 | 왕국 최강을 가리는 밤 |
| chung_06 | 1930년대 권투 드라마 | 1936 뉴욕 복싱 체육관 | 링 위의 두 주먹 |
| chung_07 | 우주 파일럿 경쟁 SF | 근미래 전투기 비행단 | 에이스 자리를 두고 |
| chung_08 | 현대 e스포츠 라이벌 | 2020년대 프로게임 무대 | 결승에서 다시 만난 |

### hyeong (형 · 8편) — 의형제 느와르 / 전우애
| id | 장르 | 시대·배경 | 가제 |
|---|---|---|---|
| hyeong_01 | 독립운동 결사 느와르 | 1920년대 만주·경성 | 같은 맹세를 한 밤 |
| hyeong_02 | 무협 의형제극 | 원나라 강호 | 피로 맺은 형제 |
| hyeong_03 | 전쟁 전우애 드라마 | 1944 유럽 전선 참호 | 참호 속의 약속 |
| hyeong_04 | 거리 소년 의형제극 | 1950년대 전후 서울 | 한 처마 밑 형제 |
| hyeong_05 | SF 군단 전우극 | 먼 미래 행성 방위군 | 같은 분대 마지막 둘 |
| hyeong_06 | 해적선 의형제 느와르 | 18세기 카리브해 | 같은 깃발 아래 |
| hyeong_07 | 현대 소방 전우극 | 2020년대 소방서 | 불 속으로 함께 들어간 |
| hyeong_08 | 판타지 기사단 맹세극 | 검과마법 왕국 기사단 | 검을 맞댄 맹세 |

### neutral (잔잔한 인연 · 2편) — 스쳐간 인연 (~6,000~8,000자, 3~4 챕터 OK)
| id | 장르 | 시대·배경 | 가제 |
|---|---|---|---|
| neutral_01 | 시장 단편 (잔잔한 여운) | 조선 후기 장터 | 장터에서 스친 사람 |
| neutral_02 | 현대 단편 (잔잔한 여운) | 2020년대 같은 동네 | 같은 버스를 타던 사람 |

## 남은 sprint 명세 (다음 세션 — Sprint 2~10)
- **Sprint 2** — wonjin 8편 (애증 다크로맨스/복수 스릴러). `_pickPrimary` 우선순위 1위
  = 노출 빈도 최다.
- **Sprint 3** — hap 8편 (소울메이트)
- **Sprint 4** — chung 8편 (라이벌물)
- **Sprint 5** — cheoneul 8편 (힐링·구원)
- **Sprint 6** — hyeong 8편 (의형제·전우애)
- **Sprint 7** — yeokma 8편 (로드무비)
- **Sprint 8** — gongmang 8편 (잔잔 멜로) + neutral 2편 (짧은 여운)
  - Sprint 2~8 각각: 해당 관계 8(+2)편 KO 집필 → format/chapters/epilogue 추가 →
    `longformWrittenRelations` set 에 관계 추가 → codex QA (4편 sub-batch) →
    test PASS → commit. 한 세션에 8편이 부담이면 4편씩 2 sub-sprint.
- **Sprint 9** — 영어판 66편 (`story_arcs_en`). KO 확정본을 EN longform 으로 현지화.
  현재 story_arcs_en 은 구 paragraphs 스키마 유지 중 (r106_past_life_english_test 가
  64 arc 의 paragraphs + 조건형 marker 를 검사 — EN longform 전환 시 그 테스트도
  longform 분기 추가 필요). KO 와 동일 id. EN 가드: 한글 leak 0, templating 0누락.
- **Sprint 10** — cleanup. 66편 전부 longform 확인 후 구 슬롯 풀 제거: JSON
  `eras/relations/endings/templates/body_lines` + 각 arc 의 `paragraphs`/
  `modernPunchlineByKind`, service `_composeFromPool` + 슬롯 josa 헬퍼. 이때 관련
  회귀 테스트(r104_arc group5, r103_resolution_motif, r102_story_structure)도
  longform 스키마 검사로 교체. `longformWrittenRelations` skip-list 완전 제거.

집필 톤·구조·전생→현생 epilogue 는 본 문서 상단의 「경성 1929」 gold standard +
past_life_pool.json 의 확정된 dohwa 8편이 기준. codex 채점 4 dim: A 인터넷소설 톤
일관(.35,h9.5) / B AI어색·반복 없음(.35,h9.5) / C 페르소나·몰입(.15,h9.0) /
D 종합·$변수·전생→현생·관계내 장르변별·거짓0(.15,h9.0).
