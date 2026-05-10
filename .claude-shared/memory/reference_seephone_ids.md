---
name: seephone 모든 식별자·자격증명·URL
description: 3개 앱의 Bundle ID / ASC App ID / 베타 그룹 ID / Public link / 프라이버시 URL 등 모든 식별자 매핑.
type: reference
originSessionId: 65198821-57e9-40a2-b42d-d1b65b6f5042
---
## ASC API 자격증명 (재활용)
| 항목 | 값 |
|---|---|
| Key 파일 | `~/.appstoreconnect/private_keys/AuthKey_JSGU6J4JN4.p8` |
| Key ID | `JSGU6J4JN4` |
| Issuer ID | `5269abe3-03f1-46a9-a37c-35d950758714` |
| Team ID | `Q6H9HCTK6W` |

shadowrun 의 ASC API key 그대로 사용 (한 Apple Developer 계정 = 한 키).

## 3개 앱 ID 매핑

| 앱 | Bundle ID | ASC Bundle ID | ASC App ID | Beta Group ID | TestFlight Public Link |
|---|---|---|---|---|---|
| 빡신 | `com.ganziman.bbaksin` | `5WXF835WY8` | **`6764363757`** | `268c5bab-6896-4bf6-96f6-686940a383fe` | `https://testflight.apple.com/join/D3PtAHgE` |
| 동공 지진 탐지기 | `com.ganziman.pupil` | `43C6XTMC86` | **`6764363706`** | `b33fe663-031d-4e35-85de-af2f2e826c15` | `https://testflight.apple.com/join/qKFk74FH` |
| 분노 발전소 | `com.ganziman.anger` | `8D9M2MU4V2` | **`6764363954`** | `dd8969b7-4b66-48b4-8ea2-91781e374fe3` | `https://testflight.apple.com/join/vuXTFFV9` |

각 그룹: `name=ganzitester`, `publicLinkEnabled=true`.

## AdMob 테스트 ID (Google 공식)
- iOS: `ca-app-pub-3940256099942544~1458002511`
- Android: `ca-app-pub-3940256099942544~3347511713`

3 앱 모두 위 테스트 ID 로 설정. **출시 전 진짜 ID 로 교체 필요** (사용자가 AdMob 콘솔에서 등록).

## 외부 URL
- **개인정보 처리방침**: `https://gist.github.com/dorisurararara-crypto/1939b5ec8fb8f54693ac8f72345ca53f`
- **GitHub repo**: `https://github.com/dorisurararara-crypto/seephone` (private)

## 사용자 정보
- GitHub: `dorisurararara-crypto`
- 일반/연락 이메일: `dorisurararara@gmail.com`
- **Apple Developer Apple ID**: `zkxmel@naver.com` ← spaceship/fastlane 인증용
- (참고) ASC 등록 연락처 이메일은 `dorisurararara@gamil.com` 오타 — 사용자가 ASC UI에서 고치지 않은 상태

## 환경 변수 / 키 위치 (재사용 시)
- ElevenLabs API key: `/Users/seunghyeon/shadow/shadowrun/.env` (`ELEVENLABS_API_KEY`)
- OpenAI API key: 같은 파일 (`OPENAI_API_KEY`)
- ASC private key: `~/.appstoreconnect/private_keys/AuthKey_JSGU6J4JN4.p8` (chmod 600, git 제외)
