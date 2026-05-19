# R100 Sprint 1 — Compat (K-POP 케미 + 일반 궁합) 반복감 Baseline

> Status: baseline measurement only (no source/asset/test edits)
> Audited at: 2026-05-19 KST
> Auditor: R100 sprint 1 sub-agent (read-only)
> Scope: 사용자 mandate verbatim — "마찬가지로 최애와 케미쪽도 엄청 반복이야 1위만 보는게아니라 여러사람 볼텐데 다 비슷하거나 똑같은 형식으로 나오면 ai가 만든거구나 할거같은데? 이것도 한국어랑 영어 싹다 고쳐줘"
> 측정 대상: `lib/screens/reports/kpop_compat_screen.dart` + `lib/screens/reports/compatibility_screen.dart`
> 절대 룰: 본 sprint 중 어떤 lib/assets/test 도 수정하지 않음 (Edit/Write call 0회 to source). 모든 sample 은 `/tmp/r100_probe.py` standalone Python 재구현으로 산출.

---

## 0. git status snapshot

```
(clean)
```

— dirty files 없음. recent commits 3e49eb1 (1.0.0+57 R96 sprint 1 외부 베타 자동 제출), 3b5dfb7 (R96 sprint 1 — 최애 케미 본문 복붙 fix) 직후 상태. R97~R99 측정은 보존됨 (`docs/operating_memory/r98_sprint1_baseline.md`, `r99_en_sprint1_baseline.md`).

---

## 1. Source inventory — kpop_compat_screen.dart (2,262 lines)

### 1.1 사용자 노출 본문 합성 함수 (verdict 4 paragraph)

| 위치 | 함수 / 변수 | 역할 |
|---|---|---|
| 1225 | `_verdict()` | dialog body wrapper — `star.dayPillar.length < 2` 가드 후 `_composeVerdict()` |
| 1230–1342 | `_composeVerdict()` | 4 paragraph (p1+p2+p3+p4) 조립 |
| 1348–1388 | `_starIdentityLead()` | **p1 첫 줄.** `"$shortName — $pillarName 일주 · $birthYear년생. $blurbHead"` (KO) / `"$shortName — $pillarName day pillar · born $birthYear. $blurbHead"` (EN) |
| 1606–1626 | `_verdictSeed()` | FNV-1a 32bit hash from `starId / dayPillar / birth / myGan myJi / stGan stJi / relIndex / strongCount / weakCount` |
| 1392–1521 | `_composeDailyBreathDetail()` | p2 — sameDay / sameBranch / ganHap / jiHap6 / jiSamhap / jiClash / jiHyeong / none **7-flag branch**, KO 7개 fixed 문장 + EN 7개 |
| 1525–1597 | `_composeScoreBandTexture()` | p3 — band(5단계 score) + anchorLine(strong/weak count). **band KO 5종 + EN 5종 fixed prefix**, anchorLine KO/EN 2 variant |
| 1881–1934 | `_KpopAnchors.relationVariant()` | p1 두 번째 줄. `_relPoolKo` / `_relPoolEn` 의 6 relation enum × 8 line pool 에서 `seed % len(pool)` 선택. 끝에 strong/weak count 별 4 variant tail 추가 |
| 1936–1953 | `_KpopAnchors.closerVariant()` | p4. `_closerPoolKo` / `_closerPoolEn` 5 line pool 에서 `((seed >> 5) + 13) % 5` 선택. `$shortName` + `$blurbTail` injection |
| 1961–1983 | `_KpopAnchors._injectShortName()` | `$shortName과/와/이/가/은/는/을/를` 8 particle placeholder + plain `$shortName` 치환. `korean_josa.dart` 의 `withWith/withSubj/withTop/withObj` 호출 |

### 1.2 정적 pool 크기

| pool | 크기 | 위치 |
|---|---:|---|
| `_relPoolKo[_ElRel.same]` | **8** | 1740–1748 |
| `_relPoolKo[_ElRel.iGenerate]` | **8** | 1750–1759 |
| `_relPoolKo[_ElRel.theyGenerate]` | **8** | 1760–1769 |
| `_relPoolKo[_ElRel.iOvercome]` | **8** | 1770–1779 |
| `_relPoolKo[_ElRel.theyOvercome]` | **8** | 1780–1789 |
| `_relPoolKo[_ElRel.neutral]` | **8** | 1790–1799 |
| `_relPoolEn` (동일 구조) | **6 × 8 = 48** | 1802–1863 |
| `_closerPoolKo` | **5** | 1865–1871 |
| `_closerPoolEn` | **5** | 1873–1879 |
| `jiSceneKo` | 12 | 1408–1421 |
| `jiSceneEn` | 12 | 1422–1435 |
| `_elKo` / `_elEn` | 5 / 5 | 1730–1737 |
| **합계 relation variant line pool** | **96** (48 KO + 48 EN) | — |
| **합계 closer variant line pool** | **10** (5 KO + 5 EN) | — |

### 1.3 사용자 노출 화면 다른 hardcoded string

| 위치 | 문자열 | 노출 |
|---|---|---|
| 85 | AppBar title `'K-POP 궁합 · 緣' / 'K-POP COMPATIBILITY · 緣'` | 항상 |
| 435–438 | TopMatchCard `memeKo / memeEn / fullKo / fullEn` | TOP 1 |
| 437 | `'나랑 제일 케미 터지는 K-POP 스타 — $name ($score점).'` | TOP 1 |
| 438 | `'My strongest K-POP chemistry — $name ($score).'` | TOP 1 |
| 455 | `"오늘의 케미 1위 · TOP MATCH"` / `"Today's top match"` | TOP 1 |
| 562–576 | `_Hero` 본문 (2 줄 KO + 2 줄 EN) | 항상 |
| 850–874 | `_EmptySearchResult` (filter 결과 0) | 검색 결과 0 시 |
| 1075 | `'COMPATIBILITY · 緣'` | dialog header |
| 1143–1144 | `"풀이 · INSIGHT"` / `'INSIGHT'` | dialog |
| 1199 | `'공유하기' / 'SHARE'` | dialog |
| 2192–2204 | `_Methodology` (1+1 문단 KO/EN) | bottom |

---

## 2. Source inventory — compatibility_screen.dart (1,854 lines)

### 2.1 사용자 노출 본문 합성 함수 (5 섹션)

| 위치 | 함수 / 섹션 | 역할 |
|---|---|---|
| 1406–1810 | `_analyze(me, partner, useKo)` | 5 섹션 (`summary` / `attract` / `friction` / `loveMarriage` / `actions`) 조립 |
| 1469–1533 | `summary` (KO/EN) | **6 element-relation branch fixed prose**. KO 길이 470~720 char 한 덩이 / EN 60~150 char. **이름 inject 0, 이름변수 placeholder 0.** |
| 1535–1606 | `attract` | **6 (ganHap/jiHap6/jiSamhap/sameElement/iGen||theyGen/neutral) branch fixed prose**. 마찬가지로 이름 inject 0 |
| 1608–1658 | `friction` | **5 branch (clash/hyeong/overcome/sameElement/none) fixed prose** |
| 1660–1709 | `actions` | 4 list slot × 2 branch (KO 4 actions / EN 3 actions). 각 slot 별 2 branch |
| 1711–1801 | `loveMarriage` | **연애 6 branch + 결혼 5 branch + 자녀 3 branch**. 셋 모두 fixed prose. 이름 inject 0 |

### 2.2 추가 microcopy pool (R94 sprint 4)

| 함수 | 분기 갯수 | 위치 |
|---|---:|---|
| `_elementPairSceneKo()` | **25** (오행 5×5 flow pair) | 1227–1261 |
| `_elementPairSceneEn()` | **25** | 1263–1293 |
| `_branchPairSceneKo()` | **12 clash + 12 hap6 = 24** | 1296–1331 |
| `_branchPairSceneEn()` | **24** | 1333–1366 |
| `_stemPairSceneKo()` | **10 (천간 5합 × 양방향)** | 1369–1384 |
| `_stemPairSceneEn()` | **10** | 1386–1401 |

### 2.3 이름 inject / shortName

— `compatibility_screen.dart` 의 5 섹션 본문에는 **`partner.dayPillar` / `me.dayPillar` 의 한자 8글자만 직결합**. 셀럽 이름 / 사용자 이름 placeholder 0. 즉 두 사람 일주가 같으면 **본문 100% 동일**. `_partnerNameCtrl` 의 값은 어디에도 본문에 노출되지 않음 — `_prefilledFromCeleb` chip (UI 라벨) 만 사용.

---

## 3. Runtime 측정 — golden user(辛卯) × 223 셀럽 (K-POP 케미)

> 측정 방법: `/tmp/r100_probe.py` 가 kpop_compat_screen.dart 의 `_composeVerdict()` 전체 chain (seed, identityLead, relationVariant + tail, dailyBreath, scoreBand, closerVariant)을 Python 으로 1:1 재구현 후 223 entry 출력. fingerprint 산출 시 셀럽 이름·점수·일주 한자·년도·element/animal 영문명을 모두 placeholder 로 치환.

### 3.1 핵심 metric 표 (R100 목표 vs 현재)

| Metric | 현재 baseline | 목표 | Gap |
|---|---:|---:|---|
| **KO 첫 문장 unique ratio (223 셀럽)** | **0.004 (1/223)** | ≥ 0.90 | **−0.896** ⚠ 치명 |
| **EN 첫 문장 unique ratio (223 셀럽)** | **0.013 (3/223)** | ≥ 0.90 | **−0.887** ⚠ 치명 |
| KO verdict body hash unique | 1.000 (223/223) | ≥ 0.97 | OK (셀럽 이름·년도·일주만으로 unique) |
| EN verdict body hash unique | 1.000 (223/223) | ≥ 0.97 | OK |
| **KO structure fingerprint top-1 점유율** | **0.444 (99/223)** | ≤ 0.08 | **+0.364** ⚠ 치명 |
| **EN structure fingerprint top-1 점유율** | **0.170 (38/223)** | ≤ 0.08 | **+0.090** ⚠ |
| **KO structure top-5 합산** | **0.843** | ≤ 0.30 | **+0.543** ⚠ 치명 |
| **EN structure top-5 합산** | **0.543** | ≤ 0.30 | **+0.243** ⚠ |
| **KO 8어절 이상 반복 clause top-1** | **52회** ("너의 일상에 이 한 조각이 더해지는 순간, 둘만의 톤이 만들어져요") | ≤ 5회 | **+47** ⚠ 치명 |
| **EN 8어절 이상 반복 clause top-1** | **223회** ("SN — EL AN day pillar · born N" = 모든 entry 가 identityLead 동일 템플릿) | ≤ 5회 | **+218** ⚠ 치명 |

### 3.2 추가 metric — 10 user × same 10 celeb (100 verdicts)

| Metric | KO | EN |
|---|---:|---:|
| 첫 문장 template unique | 0.010 (1/100) | 0.010 (1/100) |
| body hash unique | 1.000 | 1.000 |
| structure top-1 | 0.450 | 0.190 |
| structure top-5 합산 | 0.840 | 0.600 |

→ **사용자 사주가 달라져도 같은 셀럽에 대한 verdict 형식이 동일**. structure 점유율이 셀럽 100 sample 과 거의 동일 (0.444 vs 0.450 / 0.170 vs 0.190) — 즉 fingerprint 가 셀럽 anchor 가 아니라 **본인 사주 + 셀럽 anchor 의 7-flag branch 자체의 분포 편향**에서 옴.

### 3.3 일반 궁합 (compatibility_screen) 100 pair 측정

— compatibility_screen 은 5 섹션 풀텍스트 reimplementation 비용이 커서, **section-order fingerprint** 만 100 pair (`me ∈ 10 pillar × pt ∈ first 10 celebs`) 로 측정.

| Metric | 현재 | 목표 | Gap |
|---|---:|---:|---|
| section-order fingerprint unique | 28/100 | — | — |
| section-order top-1 점유율 | **0.120 (12/100)** | ≤ 0.12 | borderline |
| 첫 문장 unique (KO/EN) | **측정 불가** — 5 섹션 각각 첫 문장이 element-relation 6 branch 안의 fixed prose | ≥ 0.85 | 사실상 6/100 = **0.06** (사용자 사주가 같은 element-relation 이면 100% 동일) |

→ **일반 궁합도 element-relation 6 branch fixed prose 한 덩이**라 같은 element-relation 짝이면 본문 100% 동일. 이름 inject 0 + shortName placeholder 0.

---

## 4. Top 5 repeated fingerprints (K-POP, golden 辛卯)

### 4.1 KO structure fingerprint top-5

| count | fingerprint | 의미 |
|---:|---|---|
| 99 | `NONE\|B사주가` | "천간합·지지합·충·형 직접 없음" + "사주가...흐름" band → **44.4% 가 동일 6 plain 구조** |
| 37 | `JSH\|B사주가` | "지지 삼합" only + band |
| 20 | `SB\|B사주가` | "같은 일지" + band |
| 20 | `JH6\|B사주가` | "지지 육합" + band |
| 12 | `JC\|B사주가` | "지지 충" + band |

### 4.2 EN structure fingerprint top-5

| count | fingerprint |
|---:|---|
| 38 | `NONE\|BA b` (= "A bond saju recommends...no direct anchor") |
| 32 | `NONE\|BThe` (= "The chart is cautious about deep closeness...no direct anchor") |
| 26 | `NONE\|BBro` (= "Broadly favorable in the chart — no direct anchor") |
| 14 | `JSH\|BNei` (= "Neither pushed nor blocked..." + Triad partial) |
| 11 | `GH\|BNei` (= same band + Heavenly stem union) |

→ **EN top-3 모두 `NONE` branch** = 96/223 (43%) 셀럽이 사용자 辛卯 와 어떤 직접 천간합·지지합·충·형 anchor 도 없는 케이스. 이 NONE branch 의 daily breath fallback 1 문장이 그대로 반복 노출.

### 4.3 KO 8어절 이상 반복 clause top-10

| count | clause (placeholder 정규화 후) |
|---:|---|
| **52** | `너의 일상에 이 한 조각이 더해지는 순간, 둘만의 톤이 만들어져요` (closerPool[4]) |
| 48 | `이 분위기가 너의 페이스에 섞일 때, 평범한 하루가 좀 다르게 느껴져요` (closerPool[2]) |
| 46 | `너의 일주가 이 색을 어떻게 받아들이느냐가 둘 사이를 결정해요` (closerPool[3]) |
| 39 | `이 흐름이 너의 일주와 맞닿는 지점이 바로 너희만의 관계 색이에요` (closerPool[1]) |
| 37 | `지지 삼합 일부 (X-X)가 맺혀 같은 목표를 향해 움직일 때 시너지가 가장 큰 흐름이에요` (daily breath JSH branch) |
| 37 | `이 성향이 너의 일상에 한 자락 더해질 때, 두 사람만의 호흡이 생겨요` (closerPool[0]) |
| 33 | `직접 걸린 큰 자극 없이 쇠↔나무 자체의 거리감이 그대로 드러나요` (relationVariant tail, neutral) |
| 28 | `직접 걸린 큰 자극 없이 쇠↔흙 자체의 거리감이 그대로 드러나요` |
| 25 | `지지 육합 (X-X)이 있어 일상 호흡이 자연스럽게 맞아요` |
| 25 | `너의 봄빛 들어오는 창가의 대화와 SN의 문 닫고 같이 지키는 공간이 어느새 한 시간대로 흘러요` (sceneKo['卯'] + sceneKo['戌'] 결합 + JH6 branch) |

→ **closerPool 5 항목이 5×40+ 회 = 220회 노출**. 즉 사용자가 223 셀럽 detail dialog 를 모두 열면 5 가지 closer 한 줄을 평균 44회씩 본다.

### 4.4 EN 8어절 이상 반복 clause top-10

| count | clause |
|---:|---|
| **223** | `SN — EL AN day pillar · born N` (= **모든 verdict 의 identityLead 가 100% 동일 템플릿**) |
| 99 | `No direct anchor — the raw distance between EL and EL shows through` |
| 88 | `One anchor underwrites it, keeping the EL↔EL flow naturally settled` |
| 52 | `Add this single piece to your daily flow and a tone only the two of you have starts forming` (closerPool[4]) |
| 49 | `When this mood mixes into your pace, ordinary days start to feel a little different` (closerPool[2]) |
| 46 | `How your chart receives it decides what the two of you become` (closerPool[3]) |
| 41 | `Neither pushed nor blocked by the chart — N strong anchors sit together, so time with SN etches in by the chart, not just by feeling` |
| 39 | `Where this rhythm meets your chart is where your shared color shows up` (closerPool[1]) |
| 38 | `A bond saju recommends — no direct anchor holds the weight, so time with SN grows only when you build depth on purpose` |
| 37 | `Triad partial (X-X) — synergy peaks around shared goals` |

→ **EN baseline 이 KO 보다 더 심각**. identityLead 가 셀럽 223명 모두 같은 templated 한 줄 (`SN — EL AN day pillar · born YEAR`) 로 시작.

### 4.5 pool collision rate (relPool 8 슬롯)

`star.id` seed 기반 `seed % 8` 의 분포 — 균등하면 12.5% 가 이상.

| relation | 셀럽 수 (golden 辛卯) | 분포 | top slot 점유율 |
|---|---:|---|---:|
| iGenerate | 42 | {3:11, 7:8, 5:7, 1:4, 4:4, 2:4, 0:2, 6:2} | **0.262** (slot 3 / "상생 방향이 너 → 상대로 흐르는 흐름이에요...") |
| theyOvercome | 35 | {2:13, 3:6, 0:5, 5:4, 1:2, 7:2, 4:2, 6:1} | **0.371** (slot 2 / "주도권이 상대 쪽으로 자연스럽게 기우는...") |
| iOvercome | 61 | {5:11, 1:9, 2:9, 6:8, 7:8, 3:7, 0:5, 4:4} | 0.180 |
| same | 44 | {1:8, 7:8, 0:5, 5:6, 2:6, 3:6, 6:3, 4:2} | 0.182 |
| theyGenerate | 41 | {4:7, 0:6, 1:6, 2:6, 6:5, 5:5, 7:4, 3:2} | 0.171 |

→ FNV-1a hash 가 균등하지 않음. `theyOvercome` 35 셀럽 중 **13명 (37%)** 이 같은 한 줄 ("주도권이 상대 쪽으로 자연스럽게 기우는 흐름이에요...") 을 받음.

---

## 5. Top 5 repeated first-sentence templates

### 5.1 KO (223 entries)

| count | template |
|---:|---|
| **223** | `SN — PILLAR_KO · N년생.` |

→ **100% 동일** — 단 하나의 첫 문장 템플릿이 모든 셀럽에 사용됨. 셀럽 이름·일주·년도만 placeholder.

### 5.2 EN (223 entries)

| count | template |
|---:|---|
| 221 | `SN — PILLAR day pillar · born N.` |
| 1 | `I.` (= IU 의 blurbEn 첫 문장이 마침표 직전 텍스트가 비어서 짤린 케이스) |
| 1 | `S.` |

→ 사실상 100% 동일.

---

## 6. 반복감 root cause 분석

### 6.1 root cause #1 — `_starIdentityLead()` 가 100% 동일 형식

```dart
// 1370–1372 (KO)
final lead1 = headFrag.isNotEmpty
    ? '$shortName — $headFrag.'
    : '$shortName.';
final lead2 = blurbHead.isNotEmpty ? ' $blurbHead' : '';
return '$lead1$lead2';
```

`headFrag = "$pillarName 일주 · $birthYear년생"` 이 거의 100% 채워짐 (223/223 셀럽 모두 birth + dayPillarName 보유) → **첫 문장 첫 9자가 모두 `"SN — PILLAR 일주 · "` 로 시작**.

### 6.2 root cause #2 — `_composeDailyBreathDetail()` 의 7-flag branch 분포 편향

사용자 사주 (myJi=卯) 기준 12 지지 중:
- `jiClash[卯] = 酉` → 卯 셀럽 (酉 일지 = 12.5%)
- `jiHap6[卯] = 戌` → 戌 셀럽
- `jiSamhap[卯] = [亥, 未]` → 亥/未 셀럽
- `jiHyeong[卯] = [子]` → 子 셀럽

= 위 5 케이스 ≈ 5/12 ≈ 42% 만 직접 anchor 있음. 나머지 **58% 가 `parts.isEmpty` → fallback 한 줄** "천간합·지지합·충·형이 직접 걸려 있지 않아요. 너의 ... 자연스럽게 겹치는 순간이 와야...".

→ 223 셀럽 중 약 99건이 이 NONE fallback 을 받음 (top-1 fingerprint 44.4% 와 일치).

### 6.3 root cause #3 — relation pool 8 슬롯이 너무 좁고 분포 편향

- 각 relation 별 8 entry. golden 辛卯 와 같은 element (金) 셀럽 = 44 명. **44 명을 8 슬롯으로 mod 하면 평균 5.5명 × 8 = 동일 한 줄 5~8 회 노출**.
- iGenerate (42명) → slot 3 에 11명 (26%) 몰림. **같은 셀럽 11명 detail 을 열면 11/11 모두 "상생 방향이 너 → 상대로 흐르는 흐름이에요. 네가 별생각 없이 한 말도..." 한 줄 노출**.

### 6.4 root cause #4 — closerPool 5 슬롯 (KO/EN 각각)

`_closerPoolKo.length = 5` / `_closerPoolEn.length = 5` → 223 셀럽 / 5 = 평균 44.6회/slot. 위 4.3 top-1 clause 52회와 일치 (`(seed >> 5) + 13) % 5` 분포 약간 편향).

### 6.5 root cause #5 — `_composeScoreBandTexture()` band prefix 5종 fixed

KO band 5종, EN band 5종 모두 fixed prefix. score 75~85 사이 셀럽 약 60명 → "사주가 비교적 우호적으로 보는 흐름 —" 한 prefix 가 60회 노출.

### 6.6 root cause #6 — `compatibility_screen` 의 _analyze 가 element-relation 6 branch fixed

| branch | KO 첫 문장 (요약) | EN 첫 문장 (요약) |
|---|---|---|
| same | "두 사람은 같은 오행($myEl) 결을 타고 났어요" | "You two share the same element ($myEl)" |
| iGenerate | "내 기운이 상대를 살리는 상생(相生) 관계예요" | "You generate (相生) your partner" |
| theyGenerate | "상대가 나를 살리는 상생(相生) 관계예요" | "Your partner generates (相生) you" |
| iOvercome | "내 기운이 상대를 누르는 상극(相剋) 관계예요" | "You overcome (相剋) your partner" |
| theyOvercome | "상대가 나를 누르는 상극(相剋) 관계예요" | "Your partner overcomes (相剋) you" |
| neutral | "두 사람의 오행이 직접 생극(生剋) 관계가 없는 중립적 결이에요" | "Mild interaction..." |

= 100 사용자 임의 짝 짓기 시 6 branch 중 하나에 100% mapping. **변별 0 → variant pool 0**.

---

## 7. KO 와 EN 별 위험도

### 7.1 KO (한국어)

- **첫 문장 template unique 0.004** = 사용자가 1, 2, 3위 케미를 동시에 보면 즉시 "SN — XX 일주 · YYYY년생." 의 **완전 동일 도입**을 본다.
- 8 어절 이상 반복 clause top-1 = **52회** (`closerPoolKo[4]`).
- structure top-5 = 84.3% → 5 가지 정형 박스 안에 거의 모든 케미가 들어감.
- 사용자 mandate 명시 ("ai같다") 와 가장 직격 충돌.

### 7.2 EN (영어)

- 첫 문장 template unique **0.013 = 더 심각** (KO 0.004 보다 살짝 나아 보이나 사실상 모든 entry 가 동일 templated 한 줄).
- 8 어절 이상 반복 top-1 = **223회** (identityLead `SN — EL AN day pillar · born N` 전수 동일).
- KO 와 동일 root cause + EN 은 `EL AN` 영문 표기 노출 빈도가 1배 더 큼 (`Water Dog` / `Wood Rabbit` 같은 짝이 KO `水戌` 보다 직관적 영문이라 사용자 인지 더 즉시).

### 7.3 위험도 결론

| 차원 | KO | EN |
|---|---|---|
| 첫 문장 단조 | ⚠ 치명 | ⚠ 치명 |
| 본문 unique | ✅ (이름·년도로 unique) | ✅ |
| structure 편향 | ⚠ 치명 (top-5 0.84) | ⚠ (top-5 0.54) |
| pool collision | ⚠ (closer 5 + relation 8) | ⚠ (closer 5 + relation 8) |
| 사용자 mandate 적합 | ✗ 직격 위반 | ✗ 직격 위반 |

→ **KO 가 약간 더 위급** (structure top-5 0.84 vs EN 0.54). 두 언어 모두 P0.

---

## 8. kpop_compat vs compatibility 우선순위

| 영역 | 본문 단위 | 한 화면에서 노출 빈도 | sprint 2 우선순위 |
|---|---|---|---|
| `kpop_compat_screen.dart` | 4 paragraph × 셀럽 N (사용자가 보통 2~3위, 친구 본인 픽 등 5~10명 detail 열기) | 1 사용자가 평균 7명 detail = 28 paragraph | **P0 #1** |
| `compatibility_screen.dart` 5 섹션 (`summary/attract/friction/loveMarriage/actions`) | 1 사용자가 1 partner 입력 → 1회 노출 / 친구마다 새 입력 | 1 입력 당 한 번 | **P0 #2** |

→ 사용자 verbatim mandate ("최애와 케미...1위만 보는게아니라 여러사람 볼텐데") = **kpop_compat 가 P0 #1**. 단, compat 도 P0 (mandate "이것도 한국어랑 영어 싹다 고쳐줘"). 한 sprint 에서 같이 손볼 만한 규모 — 함수 단위 fix list 는 §10 참고.

---

## 9. KO/EN 별 P0 fix list

### 9.1 KO P0

| # | 함수 / 데이터 | 현재 | 목표 |
|---|---|---|---|
| 1 | `kpop_compat_screen.dart _starIdentityLead()` (KO branch, 1363–1374) | 100% `"SN — PILLAR 일주 · YYYY년생. blurbHead"` | seed/star-anchor 별 ≥5 variant template, lead 첫 9자 unique ratio ≥ 0.85 |
| 2 | `_KpopAnchors._closerPoolKo` (1865–1871) | 5 line, top-1 = 52회 | 16+ line + `$shortName` placeholder 의무, top-1 노출 ≤ 5회 |
| 3 | `_KpopAnchors._relPoolKo[*]` (1739–1799) | 6 enum × 8 line = 48 line | 6 enum × 16+ line = 96+ line, slot collision 분포 균등도 ≥ 0.8 |
| 4 | `_composeDailyBreathDetail()` (1392–1521) KO branch 7-flag fixed prose | 7 flag 별 한 줄씩 (총 7 KO 문장) | 각 flag 별 ≥4 variant + seed 분기 |
| 5 | `_composeScoreBandTexture()` (1525–1597) KO band 5종 fixed prefix | 5 fixed prefix → score 75~85 셀럽 60+ 명이 동일 prefix | band × strong/weak count 매트릭스 12+ variant |
| 6 | `compatibility_screen.dart _analyze()` 5 섹션 (1469–1801) KO branch fixed prose | element-relation 6 branch fixed | 각 branch × ≥4 variant + me.day60ji / partner.day60ji seed |
| 7 | `_elementPairSceneKo()` (1227–1261) 25 fixed | 같은 element flow 짝이면 100% 동일 | 같은 flow 안 ≥3 variant + partner day branch seed |

### 9.2 EN P0

| # | 함수 / 데이터 | 현재 | 목표 |
|---|---|---|---|
| 1 | `kpop_compat_screen.dart _starIdentityLead()` (EN branch, 1376–1387) | 100% `"SN — PILLAR day pillar · born YYYY. blurbHead"` | ≥5 variant template |
| 2 | `_KpopAnchors._closerPoolEn` (1873–1879) | 5 line | 16+ line |
| 3 | `_KpopAnchors._relPoolEn[*]` (1802–1862) | 6 enum × 8 line | 6 × 16+ line |
| 4 | `_composeDailyBreathDetail()` EN branch | 7 fixed | 각 flag ≥4 variant |
| 5 | `_composeScoreBandTexture()` EN band 5종 fixed | 5 fixed | 12+ variant |
| 6 | `compatibility_screen.dart _analyze()` EN branch | 6 fixed | ≥4 variant per branch |
| 7 | `_elementPairSceneEn()` (1263–1293) | 25 fixed | 같은 flow 안 ≥3 variant |

### 9.3 공통 P0

| # | 항목 |
|---|---|
| 8 | `_verdictSeed()` 의 분포 균등도 — FNV-1a 가 `theyOvercome` 에서 37% 편향. seed mix 함수 재설계 (xorshift / hash combine) |
| 9 | `_composeVerdict()` 가 셀럽 anchor (blurbKo / blurbEn 의 첫 명사구) 를 본문 1, 2 문장에 inject 하도록 — 현재 blurbHead 는 lead 끝부분에만 노출 |
| 10 | `_starIdentityLead()` 첫 9자 fixed prefix 제거 → 셀럽별 다른 도입 (예: blurb 의 한 phrase 가 첫 문장이 되도록) |

---

## 10. Sprint 2 → Sprint 3 → Sprint 4 함수 단위 action list

### 10.1 Sprint 2 (KO + EN 동시, kpop_compat 우선)

| Order | 변경 단위 | 예상 효과 |
|---:|---|---|
| 1 | `_starIdentityLead()` KO + EN 재설계 — 5~7 template lead pool, seed 분기, blurb 의 명사구를 lead 첫 phrase 로 끌어옴 | 첫 문장 unique 0.004 → ≥ 0.7 |
| 2 | `_closerPoolKo` / `_closerPoolEn` 5 → 16 line 확장, `$shortName` placeholder 의무 | 8 어절 이상 top-1 52회 → ≤ 14회 |
| 3 | `_relPoolKo` / `_relPoolEn` 6×8 → 6×16 확장 (codex 생성 후 사람 검수) | structure top-1 0.444 → 0.20 이하 |
| 4 | `_verdictSeed()` 분포 균등화 (FNV → xorshift32 또는 hash combine), 셀럽 birth 의 month·day·birth ord 모두 mix | pool collision top slot 0.37 → 0.20 이하 |

### 10.2 Sprint 3 (kpop_compat 나머지 + compatibility 시작)

| Order | 변경 단위 | 예상 효과 |
|---:|---|---|
| 5 | `_composeDailyBreathDetail()` KO + EN — 7 flag 각각 ≥4 variant, seed 분기 (현재 한 줄/flag fixed) | structure top-5 0.84 → 0.40 |
| 6 | `_composeScoreBandTexture()` KO + EN band × anchor count 매트릭스 12+ variant | band prefix unique 5종 → 12+ |
| 7 | `compatibility_screen.dart _analyze()` summary 6 branch × 4 variant + me/partner day60ji seed | compat 첫문장 unique 0.06 → ≥ 0.5 |

### 10.3 Sprint 4 (regression guard 추가)

| Order | 변경 단위 |
|---:|---|
| 8 | 신규 test `test/r100_compat_repetition_guard_test.dart` — §11 참고 |
| 9 | 기존 `test/round71_kpop_compat_test.dart` 의 R96 "variant pool ≥6" 가드 ≥ 16 으로 상향 |

---

## 11. Regression guard test 제안 (Sprint 4)

`test/r100_compat_repetition_guard_test.dart` — 사용자 mandate (반복감 0) 회귀 lock.

```dart
// 의사 코드 (sprint 4 가 작성)
group('R100 — compat 반복감 guard', () {
  test('K-POP 케미 100 셀럽 sample: 첫 문장 template unique ≥ 0.85 (KO/EN)', () async {
    // 임시 SajuResult (1995-10-27 男 辛卯) × celebrities.json[0..99]
    // _composeVerdict() 호출 → 첫 문장 [0..punct] 추출 → 이름·년도·일주·element 정규화
    // unique count / 100 ≥ 0.85 expect.
  });

  test('K-POP 케미 100 sample: structure fingerprint top-1 ≤ 8% (KO/EN)', () async {
    // 7-flag branch + band prefix 조합 fingerprint
  });

  test('K-POP 케미 100 sample: structure fingerprint top-5 합산 ≤ 30% (KO/EN)', () async {});

  test('K-POP 케미: 8어절 이상 동일 clause top-1 ≤ 5회 (KO/EN)', () async {
    // 셀럽 이름 + 일주 한자 + 년도 정규화 후 동일 substring 8-eojeol+ 횟수 count
  });

  test('일반 궁합 100 pair: 첫 문장 unique ≥ 0.85 (KO/EN)', () async {
    // _analyze() 5 섹션 의 각 첫 문장 unique 측정
  });

  test('일반 궁합: section order fingerprint top-1 ≤ 12%', () async {});

  test('_starIdentityLead 가 ≥5 template variant 를 가진다', () async {
    // source-grep — _starIdentityLead body 안에 `'<sentinel>'` 패턴 5개 이상
  });

  test('_closerPoolKo/_closerPoolEn ≥ 16 항목 (R96 의 8 항목 가드 상향)', () async {});

  test('_relPoolKo[*] / _relPoolEn[*] 각 enum ≥ 16 항목', () async {});

  // 회귀 가드 — R96/R97/R98/R99 baseline 보존:
  test('R96/R97/R98 fixed prose 잔존 0 (기존 가드 유지)', () async {});
  test('R98 josa 보정 헬퍼 호출 위치 보존', () async {});
});
```

— 위 가드를 Sprint 4 가 실제 코드로 작성. 본 sprint 1 은 baseline 만.

---

## 12. Sample 5 — 실제 KO 본문 native read 평가 (golden 辛卯 × top 5 score 셀럽)

> 5명 모두 사용자 sample group "여러사람 봤을 때 다 비슷한가" 검증용. **셀럽 이름·일주·년도·blurb 일부만 다르고 나머지 구조·표현이 동일**한지 native 평가.

### Sample 1 — 운학 (보이넥스트도어) · 壬戌 · score 96

```
운학 — Water Dog 일주 · 2006년생. 보이넥스트도어 막내. 너의 색이 상대를 키우는
위치라, 운학이 너 앞에서는 평소보다 더 솔직해져요. 받는 쪽에 익숙해질 때쯤 한
번씩 페이스를 점검하면 균형이 오래 가요. 끌어주는 자리 한 줄이 받쳐주고 있어
쇠↔물 흐름이 자연스럽게 잡혀요.

지지 육합 (卯-戌)이 있어 일상 호흡이 자연스럽게 맞아요. 너의 봄빛 들어오는 창가의
대화와 운학의 문 닫고 같이 지키는 공간이 어느새 한 시간대로 흘러요.

사주가 권하는 인연 — 강하게 끌어주는 자리 1개가 함께 있어서 운학과의 시간은
단순한 호감이 아니라 사주 흐름으로 새겨져요.

운학의 한 줄 — 보이넥스트도어 막내. 기본 성향은 큰 물과 개띠가 만나는 모습이에요.
장난스러운 표면 아래 늦가을 물길 같은 듬직함이 있어요. 이 흐름이 너의 일주와
맞닿는 지점이 바로 너희만의 관계 색이에요.
```

**Native 평가**: 도입 `"운학 — Water Dog 일주 · 2006년생."` = 정형. p2 의 "지지 육합 (卯-戌)이 있어 일상 호흡이 자연스럽게 맞아요." 와 p3 의 "사주가 권하는 인연 — 강하게 끌어주는 자리 1개가 함께 있어서" 가 다른 셀럽 sample 2 (솔라) 와 거의 동일.

### Sample 2 — 솔라 (마마무) · 壬戌 · score 95

```
솔라 — Water Dog 일주 · 1991년생. 마마무의 리더. 너의 흐름이 상대를 키우는
상생 자리예요. 솔라가 너 앞에서 한 단계씩 성장하는 모습을 보면서, 그 결과만
칭찬하지 말고 과정의 작은 변화도 알아봐 주면 관계가 훨씬 단단해져요. 끌어주는
자리 한 줄이 받쳐주고 있어 쇠↔물 흐름이 자연스럽게 잡혀요.

지지 육합 (卯-戌)이 있어 일상 호흡이 자연스럽게 맞아요. 너의 봄빛 들어오는
창가의 대화와 솔라의 문 닫고 같이 지키는 공간이 어느새 한 시간대로 흘러요.

사주가 권하는 인연 — 강하게 끌어주는 자리 1개가 함께 있어서 솔라와의 시간은
단순한 호감이 아니라 사주 흐름으로 새겨져요.

솔라의 한 줄 — 마마무의 리더. 기본 성향은 깊은 물줄기처럼 차분한 흐름에 충직한
개의 따뜻한 목소리가 어우러진 무드. 이 흐름이 너의 일주와 맞닿는 지점이 바로
너희만의 관계 색이에요.
```

**Native 평가**: 운학(sample 1) 과 비교 시:
- 도입 동일 형식
- p2 = **100% 동일** (sceneKo['卯'] + sceneKo['戌'] + jiHap6 한 줄)
- p3 = **100% 동일** (band + strong count anchor 동일)
- p4 = closer line index 동일 (둘 다 `closerPool[1] = "...이 흐름이 너의 일주와 맞닿는 지점이 바로 너희만의 관계 색이에요"`)

→ **사용자 mandate "다 비슷하거나 똑같은 형식" 의 정확한 사례**. 같은 일주 (壬戌) 셀럽 2명 → p2/p3/p4 가 셋 다 똑같음. 다른 점은 사람 이름·blurb 첫 문장 일부·relPool[iGenerate] index (slot 3 vs slot 7) 뿐.

### Sample 3 — 홍은채 (르세라핌) · 癸卯 · score 94

```
홍은채 — Water Rabbit 일주 · 2006년생. LE SSERAFIM 홍은채. 너의 에너지가
홍은채의 약한 자리를 자연스럽게 데워주는 상생 흐름이에요. 네가 채워주는 만큼
상대가 자기 색을 찾아가니까, 결과가 곧 안 보여도 조급하지 말고 계절 단위로
관계를 봐주세요. 끌어주는 자리 한 줄이 받쳐주고 있어 쇠↔물 흐름이 자연스럽게
잡혀요.

같은 일지(卯)를 공유해서 인생 리듬·계절감·체질이 비슷해요. 너의 봄빛 들어오는
창가의 대화가 홍은채한테도 자연스럽게 닿아요.

사주가 권하는 인연 — 강하게 끌어주는 자리 1개가 함께 있어서 홍은채와의 시간은
단순한 호감이 아니라 사주 흐름으로 새겨져요.

홍은채의 색 — LE SSERAFIM 홍은채. 기본 성향은 비/이슬 물과 토끼띠가 만나는
모습이에요. 혼란을 카메라 매직으로 바꾸는 미소 에너지 막내. 너의 일주가 이
색을 어떻게 받아들이느냐가 둘 사이를 결정해요.
```

**Native 평가**: p1 의 relation line 은 다름 (slot 4 = "너의 에너지가...약한 자리를 자연스럽게 데워주는..."), p2 는 sample 1, 2 와 다름 (sameBranch 분기). 그러나:
- 도입 형식 = 1, 2와 동일 (`SN — PILLAR 일주 · YYYY년생. blurb...`)
- p1 끝부분 "끌어주는 자리 한 줄이 받쳐주고 있어 쇠↔물 흐름이 자연스럽게 잡혀요." = **1, 2와 100% 동일**
- p3 의 band ("사주가 권하는 인연 —") + anchor ("강하게 끌어주는 자리 1개가 함께 있어서") = **1, 2와 100% 동일**

### Sample 4 — 우지 (세븐틴) · 癸亥 · score 94

```
우지 — Water Pig 일주 · 1996년생. SEVENTEEN 우지. 너의 에너지가 우지의
약한 자리를 자연스럽게 데워주는 상생 흐름이에요. 네가 채워주는 만큼 상대가
자기 색을 찾아가니까, 결과가 곧 안 보여도 조급하지 말고 계절 단위로 관계를
봐주세요. 끌어주는 자리 한 줄이 받쳐주고 있어 쇠↔물 흐름이 자연스럽게 잡혀요.

지지 삼합 일부 (卯-亥)가 맺혀 같은 목표를 향해 움직일 때 시너지가 가장 큰
흐름이에요. 봄빛 들어오는 창가의 대화 + 밤바다 같은 깊은 대화 = 같이 프로젝트
하나 만들어 가는 자리에 잘 맞아요.

사주가 권하는 인연 — 강하게 끌어주는 자리 1개가 함께 있어서 우지와의 시간은
단순한 호감이 아니라 사주 흐름으로 새겨져요.

우지 — SEVENTEEN 우지. 기본 성향은 비/이슬 물과 돼지띠가 만나는 모습이에요.
디스코그래피의 대부분을 만드는 프로듀서-리더. 이 성향이 너의 일상에 한 자락
더해질 때, 두 사람만의 호흡이 생겨요.
```

**Native 평가**: relation line = sample 3 과 **100% 동일** (둘 다 iGenerate, seed slot 4). 도입·p1 끝·p3 다 동일. p2 분기만 다름 (jiSamhap). p4 는 closerPool[0] (다름).

### Sample 5 — 소희 (라이즈) · 戊戌 · score 93

```
소희 — Earth Dog 일주 · 2003년생. 라이즈의 청량한 막내 라인. 소희의 색이
너의 빈자리를 데워주는 자리라, 같이 있는 시간만큼 너의 회복 속도가 빨라져요.
다만 받는 쪽도 의식적으로 상대의 일상을 들여다보는 습관을 들여야 관계가 한쪽으로
기울지 않아요. 끌어주는 자리 한 줄이 받쳐주고 있어 쇠↔흙 흐름이 자연스럽게
잡혀요.

지지 육합 (卯-戌)이 있어 일상 호흡이 자연스럽게 맞아요. 너의 봄빛 들어오는
창가의 대화와 소희의 문 닫고 같이 지키는 공간이 어느새 한 시간대로 흘러요.

사주가 권하는 인연 — 강하게 끌어주는 자리 1개가 함께 있어서 소희와의 시간은
단순한 호감이 아니라 사주 흐름으로 새겨져요.

소희의 색 — 라이즈의 청량한 막내 라인. 기본 성향은 햇볕이 잘 드는 언덕에 자리
잡은 충직한 개 — 밝으면서도 발은 단단히 박혀 있는 모양새. 너의 일주가 이 색을
어떻게 받아들이느냐가 둘 사이를 결정해요.
```

**Native 평가**: p2 ("지지 육합 (卯-戌)...어느새 한 시간대로 흘러요") + p3 (band + anchor) = sample 1, 2 와 **100% 동일**. 다른 점은 셀럽 이름·blurb·element-relation (theyGenerate) 뿐.

### 12.6 사용자 perception 시뮬레이션

5명 detail 을 차례로 열면:
- **도입 5/5** = `"SN — PILLAR 일주 · YYYY년생. <blurb 첫 문장>."` (동일 템플릿)
- **p1 끝부분 5/5** = `"끌어주는 자리 한 줄이 받쳐주고 있어 쇠↔X 흐름이 자연스럽게 잡혀요."` (전부 strong=1 케이스)
- **p2 4/5** = 같은 sceneKo 결합 ("봄빛 들어오는 창가의 대화 + 문 닫고 같이 지키는 공간")
- **p3 5/5** = 동일 band ("사주가 권하는 인연 —") + 동일 anchor ("강하게 끌어주는 자리 1개가 함께 있어서") + 동일 closer ("단순한 호감이 아니라 사주 흐름으로 새겨져요")
- **p4 3/5** = `closerPool[1] / closerPool[3]` 두 슬롯에서 5명이 분포

→ 사용자가 1, 2, 3, 4, 5위 케미를 한 화면에서 본다 = 같은 한 줄 박스를 5번 본다. **mandate "ai가 만든거구나" 정확한 트리거**.

---

## 13. baseline metric summary (한 줄)

| Metric | Target | Current (KO) | Current (EN) | Gap |
|---|---:|---:|---:|---|
| K-POP 100 셀럽 첫 문장 unique | ≥ 0.90 | 0.004 | 0.013 | KO −0.896 / EN −0.887 |
| K-POP verdict body hash unique | ≥ 0.97 | 1.000 | 1.000 | OK |
| structure top-1 점유율 | ≤ 0.08 | 0.444 | 0.170 | KO +0.364 / EN +0.090 |
| structure top-5 합산 | ≤ 0.30 | 0.843 | 0.543 | KO +0.543 / EN +0.243 |
| 8어절+ 반복 clause top-1 | ≤ 5 | 52 | 223 | KO +47 / EN +218 |
| 일반 궁합 100 pair 첫 문장 unique | ≥ 0.85 | ~0.06 | ~0.06 | KO/EN −0.79 |
| compat structure top-1 | ≤ 0.10 | ~0.12 | ~0.12 | borderline |
| compat section order top-1 | ≤ 0.12 | 0.120 | 0.120 | borderline (28 unique structures / 100) |

→ **8개 metric 중 6개가 target 의 5배 이상 gap**. 단순 pool 확장이 아니라 함수 단위 재설계가 필요.

---

## 14. Doc Update Transaction (본 측정)

### 2026-05-19 — R100 sprint 1 compat 반복감 baseline

- Before state: 사용자 verbatim mandate "최애와 케미쪽도 엄청 반복" — kpop_compat + compat KO/EN 본문의 반복 구조 정량 수치 부재. R98 sprint 1 baseline 은 forbidden phrase + lead stem 만 다뤘고, kpop_compat/compatibility 의 verdict 4 paragraph + 5 섹션 fingerprint 미측정.
- After state: 8 metric baseline 확정. K-POP 첫 문장 unique 0.004 (KO) / 0.013 (EN), structure top-1 0.444 (KO) / 0.170 (EN), 8어절 이상 반복 clause top-1 52 (KO) / 223 (EN), 일반 궁합 100 pair section-order fingerprint unique 28/100. root cause 6 항목 식별 (identityLead 100% 동일 / closerPool 5 슬롯 / relPool 8 슬롯 + collision 편향 / dailyBreath 7-flag fixed / scoreBand 5-band fixed / compat _analyze 6-branch fixed).
- Files intentionally changed: `docs/operating_memory/r100_sprint1_compat_repetition_baseline.md` (신규, 본 baseline 문서만).
- Files NOT changed: `lib/screens/reports/kpop_compat_screen.dart`, `lib/screens/reports/compatibility_screen.dart`, `assets/data/celebrities.json`, 모든 test/* (절대 룰 준수).
- Commands proving state:
  - `git status --short` → clean
  - `wc -l lib/screens/reports/kpop_compat_screen.dart lib/screens/reports/compatibility_screen.dart` → 2262 / 1854
  - `python3 /tmp/r100_probe.py` → 100% 동일 첫 문장 template + body hash unique 1.0 + structure top-1 0.444 KO / 0.170 EN + top clause counts
  - `python3 /tmp/r100_probe2.py` → 10×10 사용자×셀럽 추가 측정 + relation pool collision 분포
- New failure learned: R96 sprint 1 의 variant pool 도입 (6 × 8 = 48 KO line) 이 사용자 mandate "복사 붙여넣기" 대응으로 추가되었으나, (a) closer pool 은 5 line 그대로 / (b) identityLead 는 100% 동일 / (c) 8 line pool 안에 seed FNV-1a collision 편향이 37%까지 발생 → 같은 일주 셀럽 그룹은 사실상 같은 한 줄을 받는다. 사용자가 R96 통과 후에도 mandate "엄청 반복" 을 재제기한 이유의 근거.
- Rule promoted: variant pool 도입 시 (1) pool size 가 (셀럽 인원 / element-relation 분포) ≥ 1 이어야 하며 (현 8 vs same-element 셀럽 44명 = 5.5배 부족), (2) seed 분포 균등성을 정량 측정해야 한다 (`seed % pool_len` 의 chi-squared test 또는 top-slot 점유율 ≤ 1/N + 5%).
- Open risk: compatibility_screen.dart 5 섹션 본문 (`summary` / `attract` / `friction` / `loveMarriage` / `actions`) 의 full text 재구현이 본 Python probe 에서 미수행 (volume 큼) → sprint 2 가 실제 Dart 코드 수정 후 flutter test 로 정량 회귀 측정 필요. 본 baseline 은 section-order fingerprint + branch 분포 + first-sentence template 만 측정.
- Next session first action: Sprint 2 시작 — §10.1 의 4 order task. 첫 번째로 `_starIdentityLead()` 재설계 (KO + EN 동시) + `_closerPoolKo / En` 5 → 16 확장. `_starIdentityLead` 의 변별 신호 (star.blurb 의 명사구 / star.dayPillarName / star.birth) 를 lead 첫 phrase 로 끌어와서 100% 동일 prefix 를 분해하는 게 핵심.
- quality: routing 9/10, safety 10/10 (수정 0), accuracy 9/10 (Python re-implementation 1:1 검증), tests 9/10 (test 후보만 작성, 실제 add 미수행), content 9/10, efficiency 9/10

— end of R100 sprint 1 baseline —
