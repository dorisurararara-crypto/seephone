require_relative '_helpers'
b16 = '3b51b143-3c41-47b8-8228-15fb717c8b1b'
texts = {
  'ko' => 'f043ff75-26f7-4386-9ebe-41dbaf917c6e',
  'en-US' => '49a7d355-bf25-47f8-9b61-f39704c6f3e1'
}
ko_text = <<~KO.strip
  v1.0.0 Build #16 — 1등 quality 사주 앱, codex 12 라운드 iteration 최종판.

  핵심 기능
  • KASI 한국천문연구원 만세력 + 진태양시 -32분 보정
  • 음력 → 양력 자동 변환 (1391-2050)
  • 30초 요약 카드: "당신은 큰 산 같은 사람이에요 🏔️"
  • Day Master / 5행 / 십신 / Life Themes 6카드 / 大運 / 歲運 / Lucky
  • Reports 4종: 궁합·토정비결·택일·해몽
  • Discover: K-pop 셀럽 20명 (IU/BTS/BLACKPINK/김연아/손흥민) 일주 비교 모달
  • Home: 시간대별 흐름 + 카테고리별 일운 4종 + Streak 🔥
  • 매일 오전 8시 알림 (30일 다양한 문구)
  • ko/en 완전 i18n + 친근 라벨

  테스트 포인트
  1. 첫 실행 → 생년월일 입력 → Result
  2. Bottom Nav 5탭 전체 진입
  3. Settings → Privacy/Terms/Support 외부 링크
  4. 알림 토글 ON/OFF
  5. Discover 셀럽 비교 모달
KO
en_text = <<~EN.strip
  v1.0.0 Build #16 — Top-quality Korean Saju app, finalized after 12 codex review rounds.

  Core features
  • KASI manseryeok + Seoul true solar time (-32 min)
  • Auto lunar → solar conversion (1391-2050)
  • 30-second summary: "You are a mountain-like person 🏔️"
  • Day Master / 5 Elements / Ten Gods / 6 Life Themes / 大運 / 歲運 / Lucky
  • 4 Reports: Compatibility · Tojeong · Date Picking · Dream
  • Discover: 20 K-pop celebrities (IU/BTS/BLACKPINK/Yuna Kim/Son Heung-min)
  • Home: hourly flow + 4 category guides + daily Streak 🔥
  • Daily 8 AM push (30 unique messages)
  • Full ko/en i18n + friendly labels

  Test path
  1. First launch → birth input → result
  2. Bottom nav 5 tabs
  3. Settings → external Privacy/Terms/Support
  4. Notification toggle on/off
  5. Discover celebrity compare modal
EN

[['ko', ko_text, texts['ko']], ['en-US', en_text, texts['en-US']]].each do |locale, text, loc_id|
  code, body = api(:patch, "/v1/betaBuildLocalizations/#{loc_id}",
                   {data: {type: 'betaBuildLocalizations', id: loc_id,
                           attributes: {whatsNew: text}}})
  puts "PATCH #{locale}: HTTP #{code} (#{text.length} chars)"
end

# 재확인
puts "\n─── 최종 상태 ───"
code, body = api(:get, "/v1/builds/#{b16}/betaBuildLocalizations")
JSON.parse(body)['data'].each do |loc|
  a = loc['attributes']
  puts "  locale=#{a['locale']} whatsNew=#{(a['whatsNew'] || '').length} chars"
  puts "    preview: #{(a['whatsNew'] || '').slice(0, 80)}..."
end
