require_relative '_helpers'
b17 = '6df80630-26e5-48c4-833e-8fcf55f6124e'

code, body = api(:get, "/v1/builds/#{b17}/betaBuildLocalizations")
ko_loc = JSON.parse(body)['data'].find { |l| l['attributes']['locale'] == 'ko' }
ko_id = ko_loc['id']

ko_text = "v1.0.0 Build #17 - 1등 quality 사주 앱, codex 12 라운드 iteration 최종판.\n\n핵심: KASI 만세력 + 진태양시 + 음력 자동 + 30초 요약 카드 + Day Master + 5행 + 십신 + Life Themes 6카드 + 大運 + 歲運 + Reports 4종 (궁합/토정/택일/해몽) + Discover K-pop 셀럽 20명 + 시간대별 흐름 + 매일 8시 알림 + Streak + ko/en 완전 i18n + 친근 라벨.\n\n테스트: 입력->결과->Home->Reports->Discover->Settings 전체 flow."

3.times do |i|
  code, body = api(:patch, "/v1/betaBuildLocalizations/#{ko_id}",
                   {data: {type: 'betaBuildLocalizations', id: ko_id,
                           attributes: {whatsNew: ko_text}}})
  puts "ko attempt #{i+1}: HTTP #{code}"
  break if code.to_i < 400
  sleep 2
end

code, body = api(:get, "/v1/builds/#{b17}/betaBuildLocalizations")
JSON.parse(body)['data'].each do |loc|
  a = loc['attributes']
  puts "  #{a['locale']}: #{(a['whatsNew'] || '').length} chars"
end
