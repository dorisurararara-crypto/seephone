---
name: ElevenLabs SFX·TTS API 사용 가이드
description: shadowrun 의 elevenlabs_guide.md 핵심 + seephone 자율 SFX 생성에서 검증된 패턴.
type: reference
originSessionId: 65198821-57e9-40a2-b42d-d1b65b6f5042
---
## API 키 위치
`/Users/seunghyeon/shadow/shadowrun/.env` 의 `ELEVENLABS_API_KEY`. shadowrun + seephone + 향후 모든 사용자 앱이 같은 키 공유.

## SFX (Sound Effects) 생성

### 엔드포인트
```
POST https://api.elevenlabs.io/v1/sound-generation
Headers: xi-api-key, Content-Type: application/json, Accept: audio/mpeg
Body: { text, duration_seconds (0.5~30), prompt_influence (0~1, default 0.3), loop?, model_id? }
응답: audio/mpeg 바이너리
```

### 비용 (2026-04 기준)
- `duration_seconds` 명시: **40 크레딧/초**
- 미명시 (자동): 모델 결정 길이 × 40 크레딧
- 20K 크레딧 = 약 500초 분량

### 프롬프트 작성 룰 (검증됨)
1. **영어로** — 한국어 프롬프트는 품질 저하 (커뮤니티 합의)
2. **audio 업계 용어**: `whoosh`, `impact`, `one-shot`, `stinger`, `foley`, `drone`, `chime`, `riser`, `ambience`
3. **구체성**: 재료/공간/시간전개 명시
   - 나쁨: `"epic sound"`
   - 좋음: `"low sub-bass drone building over 10 seconds in cavernous reverberant hall"`
4. **금지**: 모호한 감정어만, 복수 이벤트 한 prompt 안에 나열, 한국어
5. **loop=true** (model_id `eleven_text_to_sound_v2`): ambience/BGM 에 사용

### 검증된 카테고리별 prompt (seephone sfx-shared/ 에 전부 사용중)
| 이름 | duration | prompt |
|---|---|---|
| `ui_tap` | 0.5 | short mechanical click, clean futuristic UI button press, one-shot |
| `ui_success` | 0.6 | positive crystal bell chime notification, milestone reached |
| `ui_share` | 0.5 | whoosh swoosh send sound, content shared away |
| `kr_bell_short` | 0.8 | single Korean jing brass gong strike, short sustain, ceremonial |
| `kr_drum_buk` | 0.5 | single Korean buk drum strike, deep boomy hit, traditional folk percussion |
| `magic_burst` | 1.8 | mystical golden burst stinger, magical reveal explosion, sparkles |
| `magic_chime` | 1.2 | ascending sparkle chime, magical reveal sequence, fairy dust shimmer |
| `magic_drone` (loop) | 4.0 | mystical ambient drone, low pad with subtle high shimmer |
| `tech_scan_beep` | 0.5 | sci-fi scanner activation beep, single short electronic tone |
| `tech_tick` | 0.5 | digital countdown tick, single short clean beep, minimal |
| `alert_siren` | 1.0 | short alarm siren wail, danger alert, two-tone urgent |
| `drama_buzzer` | 1.5 | dramatic game show buzzer, big reveal fanfare, comedic timing, foley |
| `elec_surge` | 0.8 | electric power-up surge, energy buildup, capacitor charging |
| `elec_buzz_low` (loop) | 1.5 | low electrical hum, soft buzz, machinery idle |
| `elec_buzz_high` (loop) | 1.5 | intense electric crackle, lightning surge, high voltage |

전체 24개 라이브러리: `/Users/seunghyeon/seephone/scripts/generate_sfx.py`

## TTS (Text-to-Speech) 생성

### 엔드포인트
```
POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
Body: { text, model_id, voice_settings: { stability, similarity_boost, style } }
응답: audio/mpeg
```

### 모델
- `eleven_v3` — 최고 품질, 한국어 OK
- `eleven_multilingual_v2` — 빠름, 한국어 OK
- shadowrun 에서 v3 사용 중

### voice_id 추천
- shadowrun 에 검증된 한국어 음성들 있음 — `scripts/test_voices.py` 참고
- 한국어 TTS Korean Female · Korean Male voice IDs 는 ElevenLabs Voice Library 에서 검색

### 비용
- v3: ~30 캐릭터당 1 크레딧 (대략)
- v2: ~50 캐릭터당 1 크레딧

## 트랩 (검증됨)
1. **duration < 0.5초 거부**: HTTP 400 `Invalid setting for duration_seconds`. 최소 0.5초.
2. **한글 prompt 품질 저하**: 영어로 번역 후 보내기.
3. **CLIP 77 토큰 한계** (text-to-image 와 별개로 SFX 도 prompt 길면 일부 무시): 짧고 명확한 영어 한 문장.
4. **응답이 binary**: Python `urllib`로는 `r.read()`, `requests` 는 `.content`. JSON 파싱 시도하면 깨짐.

## 마스터 SFX 라이브러리 운영 패턴 (seephone)
- 모든 SFX → `/sfx-shared/` (semantic naming, 단일 source)
- 각 앱 `assets/sfx/` 는 manifest 따라 자동 sync (스크립트가 처리)
- 향후 앱 추가 시 `LIBRARY` 에 새 항목 + `USAGE[새앱]` 명시 → 스크립트 재실행 → 자동 sync

## 참조
- shadowrun docs/elevenlabs_guide.md — 카테고리 prompt 레시피, 후처리 (ffmpeg) 등 종합 가이드
