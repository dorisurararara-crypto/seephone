#!/usr/bin/env ruby
# Build #35 — Round 74 codex 9.9+ PASS (6 sprint × avg 9.93).
# Round 74 mandate: 한국어 본문 어색 표현 일소 + 12시간 흐름 home 첫 fold 승격.
require_relative '_helpers'

# 1. Build #35 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=35&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #35 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b35_id = b['id']
state = b['attributes']['processingState']
puts "[Build #35 id=#{b35_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b35_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — Round 74 한국어 본문 어색 일소 + 12시간 흐름 first-fold 승격
ko_text = <<~KO.strip
  v1.0.0 Build #35 — 한국어 본문 어색 표현 일소.

  • _OracleHero 30 멘트 일상톤 재작성 (사람 X 동사·시적 표현 제거)
  • today_deep 6 구문 + restDay 분기 sweep (일지 jargon 제거)
  • personalization 합니다체+해요체 혼용 → 해요체 통일
  • 12시간 흐름 home 첫 fold 승격
  • 영문 hedging 0
  • analyze 0 / test 363 PASS / polarity hedge 0

  codex 9.9+ × 6 sprint.

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #35 — awkward Korean copy fully swept.

  • OracleHero 30 ko ments rewritten plain-talk
  • today_deep 6 phrases + restDay branches swept
  • personalization speech levels unified
  • Hourly Flow promoted to home first-fold
  • English hedging 0 (fade quietly / stay far away / settle down)
  • analyze 0 / test 363 PASS / polarity hedge 0

  codex 9.9+ across 6 sprints.

  Issues: dorisurararara@gmail.com
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
                             relationships: {build: {data: {type: 'builds', id: b35_id}}}}})
    puts "  POST #{locale}: HTTP #{code}"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b35_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b35_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
