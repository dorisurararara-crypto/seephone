#!/usr/bin/env ruby
# Build #75 — R110 수익화 B안: 프리미엄팩 non-consumable IAP + 9기능 무료/프리미엄 게이트 + paywall
require_relative '_helpers'

BUILD_NO = 75

# 1. Build id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=#{BUILD_NO}&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts "❌ Build ##{BUILD_NO} not found."
  exit 1
end
b_id = b['id']
state = b['attributes']['processingState']
puts "[Build ##{BUILD_NO} id=#{b_id} state=#{state}]"
exit 0 if state != 'VALID' && (puts "⚠️  Not VALID yet (state=#{state})."; true)

# 2. localizations
code, body = api(:get, "/v1/builds/#{b_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R110 프리미엄팩
ko_text = <<~KO.strip
  - 프리미엄팩(₩5,900 단건 구매) 도입 — 내 사주 17카테고리·전생 66편·신년 12개월·궁합 심화·자미두수 상세 한 번에 해금.
  - 무료 콘텐츠는 그대로 — 핵심 5카테고리·오늘 운세·궁합·신년 3개월·셀럽 Top30·전생 1편.
  - 구매 복원: paywall 하단 + 설정 화면.
KO

en_text = <<~EN.strip
  - New Premium Pack (one-time $4.99 purchase) — unlock all 17 Saju categories, 66 past-life stories, full 12-month outlook, deeper compatibility, and Zi Wei details.
  - Free experience unchanged — 5 core categories, today's reading, basic compatibility, Top 30 celebs, one past-life story.
  - Restore purchase from the paywall or Settings.
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

# 4. External group ganzitester
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
