#!/usr/bin/env ruby
# Build #73 — R108 v5 톤 확산 + 알림 3슬롯 + 전생 66편 인터넷소설 장편화
require_relative '_helpers'

BUILD_NO = 73

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

# 3. whatsNew — 전생 장편 + v5 톤 + 알림 슬롯
ko_text = <<~KO.strip
  - 전생 이야기를 완전히 새로 썼어요. 최애와의 전생이 짧은 한 토막이 아니라 한 편의 인터넷소설처럼 길게 펼쳐져요 — 66가지 이야기, 장르도 로맨스·무협·판타지 등 다양하게.
  - 내 사주와 오늘의 사주 풀이를 더 알기 쉽게 바꿨어요. "잘 벼려진 칼 같은 사람" 처럼 구체적인 비유로 풀어요.
  - 알림을 하루 한 번이 아니라 아침·오후·저녁 원하는 시간대로 받을 수 있어요.
  - 영어 모드를 더 보강했어요.
KO

en_text = <<~EN.strip
  - Past-life stories are completely rewritten — your past life with your bias now unfolds like a full web-novel instead of a short blurb. 66 stories across romance, martial-arts, fantasy, and more.
  - Life and daily readings are now easier to grasp, explained through concrete, vivid metaphors.
  - Notifications can now arrive at the morning, afternoon, and evening slots you choose.
  - Bigger English coverage across the app.
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
