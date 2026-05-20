#!/usr/bin/env ruby
# Build #66 — R105: "최애의 사주" 신규 메뉴 (셀럽 실제 사주 + 위키 검증 사실, Top 30)
require_relative '_helpers'

BUILD_NO = 66

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

# 3. whatsNew — R105
ko_text = <<~KO.strip
  - ‘최애의 사주’ 메뉴를 새로 추가했어요. 좋아하는 연예인을 고르면 그 사람의 실제 생년월일로 본 사주를 풀어드려요.
  - 사주 풀이에 위키백과로 검증한 알려진 사실을 자연스럽게 녹여, 사주가 그 사람의 삶을 짚어내는 재미를 담았어요.
  - 아이유·RM·정국·제니·카리나 등 30명부터 시작해 점차 늘려갈게요.
KO

en_text = <<~EN.strip
  - Added a new "Bias's Saju" menu — pick a celebrity and see a reading of their four pillars from their real birth date.
  - Each reading weaves in Wikipedia-verified public facts so the saju naturally echoes the person's real life.
  - Starts with 30 celebrities including IU, RM, Jungkook, Jennie, and Karina, expanding over time.
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
