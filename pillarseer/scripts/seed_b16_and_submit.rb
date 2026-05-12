require_relative '_helpers'

# 1. Build #16 id 찾기
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=16&limit=1")
build = JSON.parse(body)['data'].first
unless build
  puts 'Build #16 not found'
  exit 1
end
b16_id = build['id']
puts "Build #16 id: #{b16_id}"

# 2. 기존 localization 확인
code, body = api(:get, "/v1/builds/#{b16_id}/betaBuildLocalizations")
existing = JSON.parse(body)['data']
existing_by_locale = {}
existing.each { |l| existing_by_locale[l['attributes']['locale']] = l['id'] }
puts "existing locales: #{existing_by_locale.keys.join(', ')}"

# 3. whatsNew (Build #16 = Round 11 + #15 distribution fix)
texts = {
  'ko' => <<~KO.strip,
    v1.0.0 Build #16 — 1등 quality 사주 앱, codex 12 라운드 iteration 최종판.

    핵심 기능
    • KASI 한국천문연구원 만세력 + 진태양시 -32분 보정
    • 음력 → 양력 자동 변환 (1391-2050)
    • 30초 요약 카드: "당신은 큰 산 같은 사람이에요 🏔️"
    • Day Master / 5행 / 십신 / Life Themes 6카드 / 大運 / 歲運 / Lucky
    • Reports 4종: 궁합·토정비결·택일·해몽
    • Discover: K-pop 셀럽 20명 (IU/BTS/BLACKPINK/김연아/손흥민 등) 일주 비교 모달
    • Home: 시간대별 흐름 + 카테고리별 일운 4종 + Streak 🔥
    • 매일 오전 8시 알림 (30일 다양한 문구)
    • ko/en 완전 i18n + 친근 라벨

    테스트 포인트
    1. 첫 실행 → 생년월일 입력 → Result
    2. Bottom Nav 5탭 모두 진입
    3. Settings → Privacy/Terms/Support 외부 링크
    4. 알림 토글 ON/OFF
    5. Discover 셀럽 비교 모달
  KO
  'en-US' => <<~EN.strip,
    v1.0.0 Build #16 — Top-quality Korean Saju app, finalized after 12 codex review rounds.

    Core
    • KASI manseryeok + Seoul true solar time (-32 min)
    • Auto lunar → solar conversion (1391-2050)
    • 30-second summary: "You are a mountain-like person 🏔️"
    • Day Master / 5 Elements / Ten Gods / 6 Life Themes / 大運 / 歲運 / Lucky
    • 4 Reports: Compatibility, Tojeong, Date Picking, Dream
    • Discover: 20 K-pop celebrities with KASI-correct day pillars
    • Home: hourly flow + 4 category guides + Daily Streak 🔥
    • Daily 8 AM push (30 unique messages)
    • Full ko/en i18n + friendly labels

    Test path: input → result → home → reports → discover → settings.
  EN
}

# 4. POST or PATCH each locale (BEFORE review submit — must be while editable)
texts.each do |locale, whats_new|
  if existing_by_locale[locale]
    code, body = api(:patch, "/v1/betaBuildLocalizations/#{existing_by_locale[locale]}",
                     {data: {type: 'betaBuildLocalizations', id: existing_by_locale[locale],
                             attributes: {whatsNew: whats_new}}})
    puts "PATCH #{locale}: HTTP #{code}"
  else
    code, body = api(:post, '/v1/betaBuildLocalizations',
                     {data: {type: 'betaBuildLocalizations',
                             attributes: {locale: locale, whatsNew: whats_new},
                             relationships: {build: {data: {type: 'builds', id: b16_id}}}}})
    puts "POST #{locale}: HTTP #{code}"
  end
end

# 5. 외부 그룹 할당
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b16_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 6. Beta Review 제출
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b16_id}}}}})
puts "  HTTP #{code}: #{body.slice(0, 200)}"

# 7. 재확인
puts "\n─── after ───"
code, body = api(:get, "/v1/builds/#{b16_id}/betaBuildLocalizations")
JSON.parse(body)['data'].each do |loc|
  a = loc['attributes']
  puts "  locale=#{a['locale']} whatsNew=#{(a['whatsNew'] || '').length} chars"
end
