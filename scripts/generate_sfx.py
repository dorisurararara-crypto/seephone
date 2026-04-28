#!/usr/bin/env python3
"""seephone 마스터 SFX 라이브러리 생성기 (ElevenLabs Sound Effects API).

설계 원칙 (shadowrun docs/elevenlabs_guide.md 기반):
- 재사용 가능한 semantic 이름 (앱 종속 X). 향후 만드는 모든 앱이 이 라이브러리 그대로 사용.
- 영어 프롬프트 (한글은 품질 저하 — 가이드 #3.5).
- audio 업계 용어 사용: whoosh / impact / one-shot / stinger / foley / drone / chime
- duration 최소 0.5s (API 제약).
- duration_seconds 명시 시 40 크레딧/초. 가이드 #3.4.

폴더 정책:
- 모든 SFX → `/sfx-shared/` (단일 소스).
- 각 앱 `assets/sfx/` 는 sfx-shared 의 필요 파일을 복사 (Flutter asset 정책).
- `manifest.json` 에 각 앱별 사용 목록 기록 → 향후 자동 sync.
"""

import os, json
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError

env_path = Path('/Users/seunghyeon/shadow/shadowrun/.env')
for line in env_path.read_text().splitlines():
    if '=' in line and not line.startswith('#'):
        k, v = line.split('=', 1)
        os.environ[k.strip()] = v.strip()

API_KEY = os.environ['ELEVENLABS_API_KEY']
ENDPOINT = 'https://api.elevenlabs.io/v1/sound-generation'
ROOT = Path('/Users/seunghyeon/seephone')
SHARED = ROOT / 'sfx-shared'

# 마스터 라이브러리 — semantic 이름 + audio 업계 용어 prompt
LIBRARY = [
    # ───── UI 피드백 (모든 앱 재사용) ─────
    {'name': 'ui_tap',           'dur': 0.5, 'text': 'short mechanical click, clean futuristic UI button press, one-shot'},
    {'name': 'ui_success',       'dur': 0.6, 'text': 'positive crystal bell chime notification, milestone reached, single clean tone'},
    {'name': 'ui_share',         'dur': 0.5, 'text': 'whoosh swoosh send sound, content shared away, light upward sweep'},
    {'name': 'ui_error',         'dur': 0.5, 'text': 'short low buzzer error tone, denied feedback, one-shot'},
    {'name': 'ui_swoosh',        'dur': 0.5, 'text': 'soft whoosh page transition, smooth horizontal sweep'},

    # ───── 한국 전통 (한국풍 앱 재사용) ─────
    {'name': 'kr_bell_short',    'dur': 0.8, 'text': 'single Korean jing brass gong strike, short sustain, ceremonial reverb'},
    {'name': 'kr_bell_long',     'dur': 2.0, 'text': 'Korean jing brass gong struck slowly with long shimmering decay, reverberant temple hall'},
    {'name': 'kr_drum_buk',      'dur': 0.5, 'text': 'single Korean buk drum strike, deep boomy hit, traditional folk percussion, one-shot'},
    {'name': 'kr_daegeum',       'dur': 2.5, 'text': 'solo Korean daegeum bamboo flute, single long sustained note, ambient meditative breath'},

    # ───── 미스틱·매지컬 (점집·판타지·운세 류) ─────
    {'name': 'magic_burst',      'dur': 1.8, 'text': 'mystical golden burst stinger, magical reveal explosion, sparkles and impact, dramatic'},
    {'name': 'magic_chime',      'dur': 1.2, 'text': 'ascending sparkle chime, magical reveal sequence, fairy dust shimmer, positive'},
    {'name': 'magic_drone',      'dur': 4.0, 'text': 'mystical ambient drone, low pad with subtle high shimmer, otherworldly atmosphere, loop ready', 'loop': True},
    {'name': 'magic_reveal',     'dur': 1.0, 'text': 'magical reveal moment stinger, ethereal sweep with bell tail'},

    # ───── 사이파이·테크 (탐지기·스캐너 류) ─────
    {'name': 'tech_scan_beep',   'dur': 0.5, 'text': 'sci-fi scanner activation beep, single short electronic tone, futuristic UI'},
    {'name': 'tech_scan_done',   'dur': 1.2, 'text': 'dramatic scan complete stinger, suspenseful reveal moment, sci-fi instrument'},
    {'name': 'tech_tick',        'dur': 0.5, 'text': 'digital countdown tick, single short clean beep, minimal'},
    {'name': 'tech_confirm',     'dur': 0.7, 'text': 'positive confirmation chime, all-clear bell, two-tone ascending'},

    # ───── 알람·드라마 (분노·경고·게임쇼) ─────
    {'name': 'alert_siren',      'dur': 1.0, 'text': 'short alarm siren wail, danger alert, two-tone urgent'},
    {'name': 'drama_buzzer',     'dur': 1.5, 'text': 'dramatic game show buzzer, big reveal fanfare, comedic timing, foley'},
    {'name': 'drama_stinger',    'dur': 1.0, 'text': 'cinematic suspense stinger, low brass impact with high tail, dark reveal'},

    # ───── 일렉트릭·파워 (분노 발전소 류) ─────
    {'name': 'elec_surge',       'dur': 0.8, 'text': 'electric power-up surge, energy buildup, capacitor charging'},
    {'name': 'elec_buzz_low',    'dur': 1.5, 'text': 'low electrical hum, soft buzz, machinery idle, loop ready', 'loop': True},
    {'name': 'elec_buzz_high',   'dur': 1.5, 'text': 'intense electric crackle, lightning surge, high voltage, loop ready', 'loop': True},
    {'name': 'elec_zap',         'dur': 0.5, 'text': 'single sharp electric zap, lightning bolt impact, one-shot'},
]

# 각 앱이 라이브러리에서 어떤 SFX 를 가져갈지 (manifest)
USAGE = {
    'bbaksin': [
        'kr_bell_short',     # 흔들기 시작
        'kr_drum_buk',       # 흔들기 1회당
        'magic_burst',       # 클라이맥스
        'magic_chime',       # 부적 등장
        'magic_drone',       # 결과 화면 ambient
        'ui_share', 'ui_success', 'ui_tap',
    ],
    'pupil': [
        'tech_scan_beep',    # 스캔 시작
        'tech_tick',          # 카운트다운
        'tech_scan_done',    # 스캔 완료
        'alert_siren',       # 거짓말 감지
        'tech_confirm',      # 진실 확인
        'drama_stinger',     # 결과 reveal
        'ui_share', 'ui_tap',
    ],
    'anger': [
        'elec_surge',        # 측정 시작
        'elec_buzz_low',     # 약한 흔들기 (loop)
        'elec_buzz_high',    # 강한 흔들기 (loop)
        'elec_zap',          # 터치 hit
        'drama_buzzer',      # 결과 발표
        'ui_share', 'ui_tap',
    ],
}


def generate(item):
    out = SHARED / f'{item["name"]}.mp3'
    if out.exists() and out.stat().st_size > 1000:
        return ('skip', out)
    body = {
        'text': item['text'],
        'duration_seconds': item['dur'],
        'prompt_influence': 0.4,
    }
    if item.get('loop'):
        body['loop'] = True
        body['model_id'] = 'eleven_text_to_sound_v2'
    req = Request(ENDPOINT, data=json.dumps(body).encode(), method='POST', headers={
        'xi-api-key': API_KEY,
        'Content-Type': 'application/json',
        'Accept': 'audio/mpeg',
    })
    try:
        with urlopen(req, timeout=60) as r:
            audio = r.read()
        out.write_bytes(audio)
        return ('ok', out, len(audio))
    except HTTPError as e:
        return ('fail', out, f'HTTP {e.code} {e.read().decode()[:200]}')
    except Exception as e:
        return ('fail', out, str(e))


def main():
    SHARED.mkdir(parents=True, exist_ok=True)
    total_secs = sum(s['dur'] for s in LIBRARY)
    print(f'예상 비용: {total_secs:.1f}s × 40 = {int(total_secs * 40)} credits (예산 20,000)')
    print()
    ok = skipped = fail = 0
    for item in LIBRARY:
        result = generate(item)
        if result[0] == 'ok':
            print(f'  [OK]   {item["name"]:20} {result[2]/1024:.0f}KB')
            ok += 1
        elif result[0] == 'skip':
            print(f'  [skip] {item["name"]} (이미 있음)')
            skipped += 1
        else:
            print(f'  [FAIL] {item["name"]}: {result[2]}')
            fail += 1

    # 각 앱 assets/sfx/ 에 manifest 따라 복사
    print()
    print('=== app SFX sync ===')
    for app, names in USAGE.items():
        target = ROOT / app / 'assets' / 'sfx'
        target.mkdir(parents=True, exist_ok=True)
        # 기존 비-semantic 파일 정리
        for old in target.glob('*.mp3'):
            if old.stem not in names:
                old.unlink()
                print(f'  [del]  {app}/{old.name} (구 명명)')
        for n in names:
            src = SHARED / f'{n}.mp3'
            dst = target / f'{n}.mp3'
            if src.exists() and (not dst.exists() or dst.stat().st_size != src.stat().st_size):
                dst.write_bytes(src.read_bytes())
                print(f'  [cp]   {app}/{n}.mp3')

    # manifest.json 저장 (향후 자동화에 사용)
    manifest = {'library': [s['name'] for s in LIBRARY], 'usage': USAGE}
    (SHARED / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    print(f'\n결과: {ok} OK / {skipped} skip / {fail} FAIL / 총 {len(LIBRARY)}')


if __name__ == '__main__':
    main()
