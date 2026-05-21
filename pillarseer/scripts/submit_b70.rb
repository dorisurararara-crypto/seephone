#!/usr/bin/env ruby
# Build #70 — R106: 홈 '오늘의 한 줄' (_OracleHero) 사주 미스터리형 전환
# (작성 시점 ASC 에 build 69 가 이미 별도 존재 → 본 IPA 는 build 70 으로 등록됨)
require_relative '_helpers'

BUILD_NO = 70

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

# 3. whatsNew — R106 Oracle Hero 미스터리형
ko_text = <<~KO.strip
  - 홈 화면 '오늘의 한 줄'을 사주 미스터리형으로 새로 썼어요. 오늘 일진의 글자를 신비롭게 던지고, 그 기운이 당신의 사주와 어떻게 맞물리는지(충/합/엇갈림/스쳐감) 구조로 풀어줘요.
  - 단정적인 점괘 대신 '이 자리엔 이런 결'로, 더 정확하고 편하게 읽히도록 다듬었어요.
KO

en_text = <<~EN.strip
  - Rewrote the home screen's "Today's Line" as a Saju mystery. It casts today's pillar character with intrigue and shows how that energy meets your chart — clash, harmony, near-miss, or passing by.
  - Less flat fortune-telling, more "in this kind of spot, this is the grain" — phrased to read accurate and easy.
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
