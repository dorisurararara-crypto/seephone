# Pillar Seer Design System

---

## 1. 디자인 원칙

### 톤앤매너 키워드 (5개)
1. **Mysterious** — 신비로움, 알 수 없는 매력
2. **Ancient-but-Modern** — 5000년 전통 + 2026년 미니멀
3. **Cinematic** — K-drama 무속 장면 같은 영화적 연출
4. **Trustworthy** — 점술의 신뢰감 (가벼운 밈 X)
5. **Minimalist** — Co-Star급 절제, 텍스트 중심

### 디자인 철학
- **공간이 곧 신비**: 여백을 두려워하지 않음 (Co-Star 학습)
- **별이 말한다**: 텍스트를 빛나는 별처럼 배치
- **다크 우선**: 라이트 모드 X (정통 점성술 톤)
- **K-shamanism의 시각화**: 부적/단청/팔괘 모티프를 현대적으로

---

## 2. 컬러 팔레트

### Primary
| 이름 | HEX | 용도 |
|---|---|---|
| Deep Midnight Purple | `#1A0B2E` | 메인 배경 |
| Cosmic Black | `#0A0612` | 다크 배경 (모달, 카드 뒤) |

### Secondary
| 이름 | HEX | 용도 |
|---|---|---|
| Celestial Gold | `#D4AF37` | 강조, 별/달, 행운 표시 |
| Spirit Indigo | `#311B92` | 보조 강조, 버튼 hover |
| Mystic Violet | `#6B46C1` | 그라디언트 보조색 |

### Text
| 이름 | HEX | 용도 |
|---|---|---|
| Ghostly White | `#F5F5F5` | 본문 텍스트 |
| Moonlight Gray | `#A8A8C0` | 부가 정보 |
| Faded Silver | `#6B6B82` | 비활성 텍스트 |

### Status
| 이름 | HEX | 용도 |
|---|---|---|
| Lucky Green | `#00C896` | 좋은 운세 |
| Warning Amber | `#FF9F43` | 주의 운세 |
| Danger Red | `#E74C3C` | 흉운 (사용 자제) |

### Element Colors (5행)
| 5행 | 이름 | HEX |
|---|---|---|
| 목 (Wood) | Forest Jade | `#27AE60` |
| 화 (Fire) | Phoenix Red | `#E74C3C` |
| 토 (Earth) | Ancient Bronze | `#C19A6B` |
| 금 (Metal) | Lunar Silver | `#BDC3C7` |
| 수 (Water) | Deep Ocean | `#2980B9` |

---

## 3. 타이포그래피

### 영문 (메인)
- **Display**: `Playfair Display` (Serif, 우아함, 헤드라인)
- **Body**: `Montserrat` (Sans-serif, 가독성, 본문)
- **Mono**: `JetBrains Mono` (사주 8자 표시 등 코드 같은 표현)

### 한글/한자
- `Noto Serif KR` (사주 8자 한자 표시)
- `Pretendard` (한국어 UI 보조)

### Type Scale
| 레벨 | 크기 | 사용 |
|---|---|---|
| Display 1 | 48px | 사주 결과 헤드라인 |
| Display 2 | 36px | 데일리 점수 |
| H1 | 28px | 화면 제목 |
| H2 | 22px | 섹션 제목 |
| Body Large | 18px | 풀이 본문 |
| Body | 16px | 일반 텍스트 |
| Caption | 14px | 부가 정보 |
| Micro | 12px | 라벨, 메타 |

---

## 4. 핵심 모티프

### 시각 모티프
1. **별과 달** — 미스테리어스 다크 베이스
2. **8괘 (Bagua)** — 기하학 패턴, 배경 텍스처
3. **단청 (Dancheong)** — 한국 전통 색채 패턴, 액센트
4. **부적 (Talisman)** — 한자 글씨 스타일, 카드 배경
5. **태극** — 음양 균형, 5행 시각화 베이스
6. **연꽃** — 동양적 우아함, 로딩 애니메이션
7. **엽전** — 한국 전통 화폐, 운세 동전 던지기 메타포

### 사용 예
- 데일리 운세 점수 → 달의 위상 (초승달~보름달)
- 5행 분포 → 5각형 레이더 차트, 색상은 Element Colors
- 일간 → 한자 큰 글씨 + 부적 배경
- 길흉 표시 → 별점이 아닌 별 개수 (☆☆☆☆☆)

---

## 5. 핵심 화면 와이어프레임 (5개)

### 5-1. 온보딩 (Birth Information Input)

```
+----------------------------------+
|              ✨                  |
|                                  |
|       ENTER YOUR FATE            |
|                                  |
|   ┌────────────────────────┐     |
|   │ Name / Nickname        │     |
|   └────────────────────────┘     |
|                                  |
|   ┌──────────┐ ┌──────────┐     |
|   │ Birthday │ │   Time   │     |
|   │ 96.04.15 │ │  14:30   │     |
|   └──────────┘ └──────────┘     |
|                                  |
|   ┌────────────────────────┐     |
|   │ 📍 Birth City          │     |
|   │   Seoul, South Korea   │     |
|   └────────────────────────┘     |
|                                  |
|   ⚪ Solar    ⚫ Lunar           |
|                                  |
|   ┌────────────────────────┐     |
|   │ ✨ Find My Destiny ✨   │     |
|   └────────────────────────┘     |
|                                  |
|              ✨                  |
+----------------------------------+
```
**인터랙션**:
- 입력 완료 시 한국 징(Gong) 사운드 + 우주 배경 펼쳐지는 애니메이션 (3초)
- "Skip Time" 옵션 (시간 모르는 사용자)
- City 입력 → Google Places API 자동완성

### 5-2. 일생 사주 결과 (Life Reading)

```
+----------------------------------+
|  ←  Your Life Path        ⚙     |
|                                  |
|     [Animated 8-character        |
|      Korean calligraphy]         |
|                                  |
|        甲子 / 丙寅 / 戊辰 / 庚午    |
|                                  |
|     ╔══════════════════════╗     |
|     ║   Wood Dragon (甲辰)  ║     |
|     ║                      ║     |
|     ║  "You are a forest   ║     |
|     ║   that grows fire."  ║     |
|     ╚══════════════════════╝     |
|                                  |
|   🌳 Wood ▓▓▓▓▓░░░░░ 50%        |
|   🔥 Fire ▓▓▓░░░░░░░ 30%        |
|   🏔️ Earth░░░░░░░░░░ 0%         |
|   ⚙ Metal ▓░░░░░░░░░ 10%        |
|   💧 Water▓░░░░░░░░░ 10%        |
|                                  |
|  ┌────────┐ ┌────────┐          |
|  │ 💪     │ │ 💝     │          |
|  │Strength│ │Love    │ 🔒        |
|  └────────┘ └────────┘          |
|  ┌────────┐ ┌────────┐          |
|  │ 💼 🔒  │ │ 💰 🔒  │          |
|  │Career  │ │Wealth  │          |
|  └────────┘ └────────┘          |
|                                  |
|  ✨ Unlock Full Reading $9.99   |
+----------------------------------+
```
**인터랙션**:
- 8자가 글씨 쓰이듯 한 글자씩 페이드인 (5초)
- 5행 막대그래프 좌→우 채워지는 애니메이션
- 카드 탭 → 펼쳐짐 (무료 카드만), 잠긴 카드 → 페이월

### 5-3. 데일리 운세 (Today's Energy)

```
+----------------------------------+
|  ←  Today's Energy          🔔  |
|                                  |
|       May 10, 2026               |
|                                  |
|              ⚪                  |
|         ⚪      ⚪               |
|                                  |
|         ┌──────────┐             |
|         │   85     │             |
|         │ /100     │             |
|         └──────────┘             |
|                                  |
|     "A secret friend             |
|       arrives from afar."        |
|                                  |
|  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐|
|  │ 💝  │ │ 💼  │ │ 💰  │ │ ⚡  │|
|  │ 90  │ │ 75  │ │ 60  │ │ 88  │|
|  │Love │ │Work │ │$$$  │ │Energy│|
|  └─────┘ └─────┘ └─────┘ └─────┘|
|         🔒  🔒  🔒                |
|                                  |
|  🎨 Lucky Color: Midnight Purple|
|  🔢 Lucky Number: 7              |
|  🧭 Lucky Direction: East        |
|                                  |
|  ┌──────────────────────────┐   |
|  │ 📤 Share to Story         │   |
|  └──────────────────────────┘   |
|                                  |
|  Want details? Try Premium →    |
+----------------------------------+
```
**인터랙션**:
- 점수 카운터 0→85 애니메이션 (1초)
- 카테고리 점수 카드 탭 → 페이월 (무료는 종합만)
- 공유 버튼 → 자동 카드 생성 (Instagram Story 9:16 사이즈)

### 5-4. 결제 페이월 (Subscription Paywall)

```
+----------------------------------+
|  ✕                               |
|                                  |
|         ✨ ⭐ ✨                |
|                                  |
|   UNVEIL YOUR FUTURE             |
|                                  |
|   Get unlimited access to        |
|   ancient Korean wisdom          |
|                                  |
|   ✓ Daily In-depth Analysis      |
|   ✓ 10-Year Major Cycle (大運)   |
|   ✓ Unlimited Dream Interpret.   |
|   ✓ Lucky Direction Map          |
|   ✓ No Ads                       |
|                                  |
|   ┌──────────────────────────┐  |
|   │  📅 Yearly      $39.99   │  |
|   │     ────────             │  |
|   │     $3.33/mo             │  |
|   │  💎 SAVE 33%             │  |
|   └──────────────────────────┘  |
|                                  |
|   ┌──────────────────────────┐  |
|   │  📆 Monthly     $4.99    │  |
|   └──────────────────────────┘  |
|                                  |
|   ✨ Start 7-Day Free Trial ✨   |
|                                  |
|   Restore Purchase | Terms       |
+----------------------------------+
```
**인터랙션**:
- 별 반짝이는 배경 애니메이션 (저성능 디바이스 fallback)
- Yearly 자동 선택 (33% 할인 강조)
- Free Trial 버튼 → 7일 후 자동 결제 명시

### 5-5. 단건 결제 (Compatibility Report)

```
+----------------------------------+
|  ←  Soul Compatibility           |
|                                  |
|     Your Sign + Their Sign       |
|                                  |
|   ┌──────────┐    ┌──────────┐   |
|   │  YOU     │ ✨ │  THEM    │   |
|   │  甲辰    │ + │  丙午    │   |
|   │ Dragon   │    │  Horse   │   |
|   └──────────┘    └──────────┘   |
|                                  |
|         ⚡⚡⚡⚡⚡                |
|                                  |
|   ╔══════════════════════════╗   |
|   ║      89% MATCH           ║   |
|   ║   Soul Connection         ║   |
|   ╚══════════════════════════╝   |
|                                  |
|   Preview (15%):                 |
|   "Your Wood feeds their Fire.   |
|    A relationship of growth      |
|    and..."                       |
|   ┌──────────────────────┐       |
|   │ [Blurred premium     │ 🔒   |
|   │  content - 6,000 char│       |
|   │  unlock to read]     │       |
|   └──────────────────────┘       |
|                                  |
|  💎 Unlock Full Report $9.99    |
|                                  |
|  📊 5 Element Analysis          |
|  💝 Love Compatibility          |
|  💼 Business Partnership        |
|  🌙 Long-term Forecast          |
+----------------------------------+
```
**인터랙션**:
- 두 사주 사이 5행이 섞이는 비주얼 이펙트 (3초)
- 점수 카운터 0→89 (2초)
- Blurred content 위에 락 아이콘 + 결제 CTA

---

## 6. 인터랙션 / 애니메이션 가이드

### 핵심 애니메이션 5개
1. **Brand Splash** (3초): 별이 모여서 Pillar Seer 로고 형성
2. **Saju Calligraphy** (5초): 8자가 한 글자씩 글씨 쓰이듯 등장
3. **Score Counter** (1~2초): 0→타겟 숫자 카운트업
4. **Card Flip** (0.5초): 운세 카드 뒤집기 (3D transform)
5. **Element Mix** (3초): 두 사주의 5행 컬러가 섞이는 파티클 애니메이션

### Haptic Feedback
- 사주 계산 완료: Heavy (한 번)
- 결과 카드 공개: Medium
- 카테고리 카드 탭: Light
- 결제 성공: Success pattern (Heavy + Light + Medium)

### Sound Design (선택)
- Brand Splash: 한국 징 (Gong) 단발
- Score 공개: 차임벨 (Wind chime)
- 카드 뒤집기: Whoosh
- 결제 성공: 동전 떨어지는 소리 (Coin drop)

→ 사운드는 옵션 (사용자 OFF 가능). 디폴트 ON.

---

## 7. 참고 앱 분석

### Co-Star (★ 메인 레퍼런스)
- **차용**: 미니멀 검정 배경 + 별 모티프 + 텍스트 중심 레이아웃
- **차별화**: 보라 추가 (한국 무속 컬러), 8자 한자 (서양 점성술엔 없음), K-pop 클립 마케팅

### The Pattern
- **차용**: 깊이 있는 성격 분석 구조 (4~6 카드 분류)
- **차별화**: 사주 한자 시각화로 더 미스테리어스

### Sanctuary
- **차용**: 페이월 디자인 + 단건 결제 UX
- **차별화**: 컬러풀하지 않고 보라/금색 한정 (브랜드 일관성)

### 한국 점신
- **차용**: 사주 풀이 깊이, 토정비결 / 궁합 / 택일 카테고리
- **차별화**: 영어 + 글로벌 디자인 + K-pop 컨텍스트

---

## 8. 다크 모드 / 라이트 모드

**라이트 모드 X.** 다크 only.
이유:
- 점성술/무속 톤 = 다크가 정통
- Co-Star도 다크 only
- 사용자 선호 명시 (미스테리어스 다크)
- 1인 개발 시간 절약 (디자인 1세트만)

---

## 9. 접근성 (Accessibility)

- **WCAG 2.1 AA** 준수
- 텍스트 콘트라스트 4.5:1 이상 (Ghostly White on Cosmic Black 검증 완료)
- 폰트 크기 시스템 설정 따름 (Dynamic Type)
- 모든 인터랙티브 요소 44×44pt 이상
- VoiceOver / TalkBack 라벨링 필수

---

## 10. 디자인 자산 제작 계획

### 우선 제작 (Week 1)
- 앱 아이콘 (1024×1024) — 별 + 보라 그라디언트 + K 글자
- Splash Logo
- 5행 아이콘 5개 (목/화/토/금/수)
- 12지 동물 아이콘 12개

### Week 2~4
- 8괘 (Bagua) 패턴 SVG
- 부적 카드 배경 (단건 결제용)
- 별자리 배경 (5종 — 메인 화면 분위기)

### 자산 생성 방법
- **Windows AI 머신** (RTX 5070 Ti) 활용
- ComfyUI / SDXL / Flux 이미지 생성
- 컨셉: 미스테리어스 다크 + 보라/별 + 한국 전통 모티프
- 모든 결과 일관된 스타일로 (LoRA 학습 또는 ControlNet 활용)
