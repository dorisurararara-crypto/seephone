#!/usr/bin/env ruby
# Build #62 — R101 sprint 1-7: 1.0.0 marketing 되돌림 + 팬심 카테고리 재정의
require_relative '_helpers'

BUILD_NO = 62

# 1. Build id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=#{BUILD_NO}&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts "❌ Build ##{BUILD_NO} not found yet. (Apple processing 5~15분 대기 후 재시도)"
  exit 1
end
b_id = b['id']
state = b['attributes']['processingState']
puts "[Build ##{BUILD_NO} id=#{b_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R101 사용자 mandate verbatim
ko_text = <<~KO.strip
  팬심 카테고리를 새로 정리했어요. 전생의 악연·인연 시나리오, 디지털 기운 처방전, 최애와의 궁합보기가 추가됐고, 한국어 본문에 섞여 보이던 영어 표현도 함께 다듬었어요.
KO

en_text = <<~EN.strip
  We rebuilt the Fan picks category. Added past-life scenarios, a digital energy prescription, and idol compatibility, while cleaning up English phrases that had slipped into Korean text.
EN

[['ko', ko_text], ['en-US', en_text]].each do |locale, text|
  loc_id = by_locale[locale]
  if loc_id
    code, body = api(:patch, "/v1/betaBuildLocalizations/#{loc_id}",
                     {data: {type: 'betaBuildLocalizations', id: loc_id,
                             attributes: {whatsNew: text}}})
    puts "  PATCH #{locale}: HTTP #{code} (#{text.length} chars)"
  else
    code, body = api(:post, '/v1/betaBuildLocalizations',
                     {data: {type: 'betaBuildLocalizations',
                             attributes: {locale: locale, whatsNew: text},
                             relationships: {build: {data: {type: 'builds', id: b_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
