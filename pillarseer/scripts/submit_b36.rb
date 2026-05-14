#!/usr/bin/env ruby
# Build #36 — Round 75 codex 9.9+ PASS (2 sprint × avg 9.96).
# Round 75 mandate: 1등 만세력 사이트 1995-10-27 男 → 木16 火21 土17 金41 水4
# 골든 calibration + 십신 음양 10분류 분리 + 한자 jargon 제거.
require_relative '_helpers'

# 1. Build #36 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=36&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #36 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b36_id = b['id']
state = b['attributes']['processingState']
puts "[Build #36 id=#{b36_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b36_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — Round 75 5행 calibration + 십신 음양 10분류
ko_text = <<~KO.strip
  v1.0.0 Build #36 — 5행 비율 정통 calibration + 십신 10분류.

  • 1등 만세력 사이트 기준 골든 일치 (1995-10-27 男 → 金 41% 압도적)
  • 가중치 통근/록 보정 (월령 ×3.0 + 일간 통근 + 정록 보너스)
  • 십신 음양 분리 10분류 (비견·겁재·식신·상관·정재·편재·정관·편관·정인·편인)
  • 의료 권고 톤 정리 (수분·수면 단정 X → 보완 톤)
  • 한자 jargon 제거 (比肩·劫財 등 사용자 노출 X)
  • analyze 0 / test 368 PASS / polarity hedge 0

  codex 9.9+ × 2 sprint (1: 9.92 / 2: 10.0).

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #36 — Five Elements calibrated to authentic ratios.

  • Top Korean saju site golden match (1995-10-27 male → Metal 41 % dominant)
  • Root + Lu weighting (month branch x3.0 + day-master root + exact-Lu bonus)
  • Ten Gods split by yin-yang into 10 classes (Friend/Rival, Producer/Spark, Steady/Big-shot Wealth, Officer/Challenger, Mentor/Insight)
  • Medical-prescription tone removed (no more "drink water, sleep more")
  • Hanja jargon stripped from UI strings
  • analyze 0 / test 368 PASS / polarity hedge 0

  codex 9.9+ across 2 sprints (1: 9.92 / 2: 10.0).

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
                             relationships: {build: {data: {type: 'builds', id: b36_id}}}}})
    puts "  POST #{locale}: HTTP #{code}"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b36_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b36_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
