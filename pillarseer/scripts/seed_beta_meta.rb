#!/usr/bin/env ruby
# 베타 앱 설명·피드백 이메일·마케팅 URL 채우기 (한국어 + 영어)
require_relative '_helpers'

FEEDBACK_EMAIL = 'dorisurararara@gmail.com'

LOCALES = {
  'ko' => {
    description: <<~KO.strip,
      POV: 나는 주인공

      걸으면 BGM 자동, 폰 흔들면 칼소리, 버튼 누르면 화면 번쩍.
      8가지 모드로 일상이 영화가 되는 효과음·BGM 앱.

      [모드]
      - 천하무적 발걸음: 걸을 때마다 효과음
      - 주인공 등장: 화면 번쩍 + 등장 사운드
      - 전설의 무기: 폰 휘두르면 칼·광선검 소리
      - 인생은 드라마: 상황별 BGM 무한 반복
      - 심판의 시간: 점수·천재·거짓말 즉석 카드
      - 리액션 장인: 썰렁/메롱/딩동댕 사운드보드
      - 공포의 몰카: 타이머 후 깜짝 사운드
      - 내 목소리 이상해: 5초 녹음 → 변조 재생

      [테스트 포인트]
      - 8개 모드 진입/사운드 재생 정상 여부
      - 걷기·흔들기 센서 반응 정확도
      - 점수 카드 캡처/공유 동작
      - 광고 표시 정상 여부

      문제 발견 시 dorisurararara@gmail.com 으로 회신 부탁드립니다.
    KO
  },
  'en-US' => {
    description: <<~EN.strip,
      POV: I'm the Main Character

      Walk and BGM plays automatically. Swing the phone for sword sounds.
      Tap a button for a flash entrance. 8 modes that turn daily life into a movie.

      [Modes]
      - Invincible Footsteps: SFX on each step
      - Hero Entrance: Flash + entrance sound
      - Legendary Weapon: Sword/lightsaber sounds when swinging
      - Life Drama: Looping situational BGM
      - Judgment Time: Instant score/genius/lie cards
      - Reaction Master: Awkward/raspberry/ding-dong soundboard
      - Prank Mode: Timer then surprise sound
      - My Voice Sounds Weird: 5s record then voice modulation

      [Test Focus]
      - All 8 modes launch and play sound correctly
      - Walk/shake sensor accuracy
      - Score card capture and share
      - Ad display

      Send issues to dorisurararara@gmail.com.
    EN
  }
}

LOCALES.each do |loc, data|
  puts "[#{loc}] 생성 중..."
  body = {
    data: {
      type: 'betaAppLocalizations',
      attributes: {
        locale: loc,
        description: data[:description],
        feedbackEmail: FEEDBACK_EMAIL,
      },
      relationships: {
        app: { data: { type: 'apps', id: APP_ID } }
      }
    }
  }
  code, res = api(:post, '/v1/betaAppLocalizations', body)
  case code.to_i
  when 201 then puts "  ✅ 생성 완료"
  when 409 then puts "  ℹ️  이미 존재 (멱등)"
  else
    puts "  FAIL HTTP #{code}: #{res[0..400]}"
  end
end

puts "\n현재 상태:"
code, body = api(:get, "/v1/apps/#{APP_ID}/betaAppLocalizations")
JSON.parse(body)['data'].each do |loc|
  puts "  - #{loc['attributes']['locale']}: feedback=#{loc['attributes']['feedbackEmail']}"
end
