require_relative '_helpers'
b17 = '6df80630-26e5-48c4-833e-8fcf55f6124e'

code, body = api(:get, "/v1/builds/#{b17}/betaBuildLocalizations")
locs = JSON.parse(body)['data']

ko_text = <<~KO.strip
v1.0.0 Build #17 — 1등 quality 사주 앱, codex 12 라운드 iteration 최종판.

핵심 기능
• KASI 한국천문연구원 만세력 + 진태양시 -32분 보정
• 음력 → 양력 자동 변환 (1391-2050)
• 30초 요약 카드: "당신은 큰 산 같은 사람이에요 🏔️"
• Day Master / 5행 / 십신 / Life Themes 6카드 / 大運 / 歲運 / Lucky
• Reports 4종: 궁합·토정비결·택일·해몽
• Discover: K-pop 셀럽 20명 (IU/BTS/BLACKPINK/김연아/손흥민) 일주 비교 모달
• Home: 시간대별 흐름 + 카테고리별 일운 + Streak 🔥
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
v1.0.0 Build #17 — Top-quality Korean Saju app, finalized after 12 codex review rounds.

Core features
• KASI manseryeok + Seoul true solar time (-32 min)
• Auto lunar → solar conversion (1391-2050)
• 30-second summary: "You are a mountain-like person"
• Day Master / 5 Elements / Ten Gods / 6 Life Themes
• 4 Reports: Compatibility, Tojeong, Date Picking, Dream
• Discover: 20 K-pop celebrities with KASI-correct day pillars
• Home: hourly flow + category guides + daily Streak
• Daily 8 AM push (30 unique messages)
• Full ko/en i18n

Test path: input -> result -> home -> reports -> discover -> settings
EN

locs.each do |l|
  loc_id = l['id']
  locale = l['attributes']['locale']
  text = locale == 'ko' ? ko_text : en_text
  code, body = api(:patch, "/v1/betaBuildLocalizations/#{loc_id}",
                   {data: {type: 'betaBuildLocalizations', id: loc_id,
                           attributes: {whatsNew: text}}})
  puts "PATCH #{locale}: HTTP #{code} (#{text.length} chars)"
end

# 재확인
puts "\n─── 최종 ───"
code, body = api(:get, "/v1/builds/#{b17}/betaBuildLocalizations")
JSON.parse(body)['data'].each do |loc|
  a = loc['attributes']
  puts "  #{a['locale']}: #{(a['whatsNew'] || '').length} chars"
end
