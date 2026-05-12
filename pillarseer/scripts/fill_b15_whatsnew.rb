require_relative '_helpers'
b15 = '0b24806b-15ce-4236-a398-85caec9ffdd4'

# 기존 localizations 조회 → PATCH (아니면 POST)
code, body = api(:get, "/v1/builds/#{b15}/betaBuildLocalizations")
existing = JSON.parse(body)['data']
existing_by_locale = {}
existing.each { |l| existing_by_locale[l['attributes']['locale']] = l['id'] }

texts = {
  'ko' => <<~KO.strip,
    v1.0.0 Build #15 — 사주 앱 1등 quality 12 라운드 iteration 최종판.

    • KASI 만세력 + 진태양시 -32분 보정
    • 음력 → 양력 자동 변환
    • Result 화면 30초 요약 카드 ("당신은 큰 산 같은 사람이에요 🏔️")
    • Day Master / 5행 / 십신 / Life Themes 6카드 / 大運 / 歲運 / Lucky
    • Reports 4종: 궁합·토정비결·택일·해몽
    • Discover: K-pop 셀럽 20명 일주 비교 모달 (KASI 100% 정확)
    • Home: 시간대별 흐름 (지금/다음/저녁) + 카테고리별 일운 4종
    • 매일 8시 알림 (30일 다른 문구)
    • Streak 연속 체크인 🔥
    • ko/en 완전 i18n + 친근 라벨 ("일간"→"당신의 본성 🪨")
    • Privacy/Terms/Support: dorisurararara-crypto.github.io/pillarseer/

    테스트 포인트: 입력 → 결과 → Home → Reports → Discover → Settings 전체 flow.
  KO
  'en-US' => <<~EN.strip,
    v1.0.0 Build #15 — Final round of 12-iteration quality push.

    • KASI manseryeok + Seoul true solar time (-32 min)
    • Auto lunar → solar conversion
    • Result 30-second card ("You are a mountain-like person 🏔️")
    • Day Master / 5 Elements / Ten Gods / 6 Life Themes / 大運 / 歲運 / Lucky
    • 4 Reports: Compatibility · Tojeong · Date Picking · Dream
    • Discover: 20 K-pop celebrities with KASI-correct day pillars + compare modal
    • Home: hourly flow (now/next/evening) + 4 category guides
    • Daily 8 AM push (30 unique daily messages)
    • Daily check-in streak 🔥
    • Full ko/en i18n + friendly labels (Day Master → Your Core Self 🪨)

    Test path: input → result → home → reports → discover → settings.
  EN
}

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
                             relationships: {build: {data: {type: 'builds', id: b15}}}}})
    puts "POST #{locale}: HTTP #{code}"
  end
end

# 재확인
puts "\n─── after update ───"
code, body = api(:get, "/v1/builds/#{b15}/betaBuildLocalizations")
JSON.parse(body)['data'].each do |loc|
  a = loc['attributes']
  puts "  locale=#{a['locale']} whatsNew=#{(a['whatsNew'] || '').length} chars"
end
