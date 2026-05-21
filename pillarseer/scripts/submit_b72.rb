#!/usr/bin/env ruby
# Build #72 — R107 사주 정확도 audit + 영어 갭 — 스플래시 +1초 + Android 런처/알림 아이콘 신 디자인 재생성
require_relative '_helpers'

BUILD_NO = 72

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

# 3. whatsNew — 스플래시 + Android 아이콘
ko_text = <<~KO.strip
  - 사주 풀이 정확도를 전반적으로 손봤어요. 내 사주의 각 운세 카테고리가 더 또렷이 구별되고, 궁합·신년운세·오늘의 사주도 더 개인화됐어요.
  - K-pop 궁합은 셀럽의 실제 생년월일로 사주를 계산하도록 바꿨어요.
  - 영어를 더 보강했어요 — 영어 모드 내 사주가 사주별로 개인화되고, 오늘의 사주도 영어로 나와요.
KO

en_text = <<~EN.strip
  - Sharpened reading accuracy across the app — life-fortune categories now read more distinctly, and compatibility, new-year, and daily readings are more personalized.
  - K-pop compatibility now computes each celebrity's saju from their real birth date.
  - Bigger English coverage — a personalized English life reading and an English daily reading.
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
