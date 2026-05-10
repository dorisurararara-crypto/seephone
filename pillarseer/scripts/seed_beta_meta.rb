#!/usr/bin/env ruby
# 베타 앱 설명·피드백 이메일 채우기 (한국어 + 영어)
require_relative '_helpers'

FEEDBACK_EMAIL = 'dorisurararara@gmail.com'

LOCALES = {
  'ko' => {
    description: <<~KO.strip,
      Pillar Seer — 글로벌 영어권 K-컬처 사주 앱

      생년월일·시간·출생지 입력하면 4기둥 (年月日時) 8자, 5행 분포, 일간 (Day Master) 분석.
      매일 일진 vs 사용자 사주 충합으로 100점 만점 점수 + Lucky Color/Number/Direction.

      [화면]
      - Splash → Input → Result (Birth chart)
      - Home (Today's Energy): 매일 점수 + 4 카테고리 + Lucky 카드
      - Reports / Discover / Profile (Phase 2 추가 예정)

      [기술]
      - Julian Day Number 기반 일주 계산 (1900-01-01 = 甲戌 epoch)
      - 5행 상생/상극 점수 산정 (河圖洛書)
      - 60일주 × 5 fields 콘텐츠 (300 entries, 영어)
      - 다크 코스믹 + 골드 (#D4AF37) 디자인 (mockup 17화면 중 7화면 구현)

      [테스트 포인트]
      - Splash 자동 전환 → Input 입력 → Find My Destiny 버튼 동작
      - Result 4기둥 한자 + 영어 dayMaster + 5행 progress bar
      - Bottom Nav 5탭 라우팅
      - Continue to Daily Reading → Home

      문제 발견 시 dorisurararara@gmail.com 으로 회신 부탁드립니다.
    KO
  },
  'en-US' => {
    description: <<~EN.strip,
      Pillar Seer — Korean Saju (Four Pillars of Destiny) for Global Gen Z

      Enter birth date, time, and place to receive your Four Pillars (Year/Month/Day/Hour),
      Five Element distribution, and Day Master analysis.
      Daily energy score (out of 100) based on today's pillar vs your chart, plus Lucky Color, Number, and Direction.

      [Screens]
      - Splash → Input → Result (Birth chart with 4 pillars)
      - Home (Today's Energy): daily score + 4 categories + Lucky card
      - Reports / Discover / Profile (Phase 2)

      [Tech]
      - Julian Day Number based pillar calculation (1900-01-01 = 甲戌 epoch)
      - Five Elements interaction scoring (河圖洛書 / He Tu Luo Shu)
      - 60 day-pillar × 5 content fields (300 entries, English, mysterious K-pop tone)
      - Dark cosmic + Celestial Gold (#D4AF37) design (7 of 17 mockup screens implemented)

      [Test Focus]
      - Splash auto-navigates → Input → Find My Destiny submit
      - Result shows 4 pillars (Hanja), Day Master in English, Five Element bars
      - Bottom Nav 5-tab routing works
      - Continue to Daily Reading → Home flow

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
