#!/usr/bin/env ruby
# Build #45 — R86 sprint 4: 오늘 사주 총평 모순 + 십신 jargon 일소
# 785 test PASS / flutter analyze 0 issue / 5행 골든 + R69 lock + R71~R85 시그니처 보존
require_relative '_helpers'

# 1. Build #45 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=45&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #45 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b45_id = b['id']
state = b['attributes']['processingState']
puts "[Build #45 id=#{b45_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b45_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R86 sprint 4 (≤500자 mandate)
ko_text = <<~KO.strip
  v1.0.0 Build #45 — R86 오늘 사주 총평 fix.

  모순 일소:
  • "부딪칠 일이 생겨요" + "큰 충돌 없이" 동시 노출 모순 해결
  • 충돌 강도 약화 → 비교·경쟁 신호가 신경 쓰일 수 있어요
  • neutral 톤 — 자기 페이스대로 흘러가는 평탄한 날

  십신 jargon 평어화:
  • "식신/겁재/정관 대운 안에 있는 지금" → "지금 대운에서는, …"
  • 10 십신 단어 본문 노출 0
  • 의미만 자연 한국어로 풀이

  품질:
  • 785 test PASS (R86 sprint 4 신규 회귀 가드 4)
  • flutter analyze 0 issue
  • 5행 골든 1995-10-27 男 17시 16/21/17/41/4 보존
  • R69 lock + R71~R85 시그니처 + R78 대운 anchor wire 보존

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #45 — R86 today saju summary fix.

  Contradiction cleanup:
  • Resolved "may clash" + "without clash" body collision
  • Softer wording: comparison/competition signals may catch attention
  • Neutral tone: the day flows at your usual pace

  Ten-gods jargon plain language:
  • Dropped "Output/Rival/Stable Office cycle" jargon
  • Each phrase reads as plain Korean meaning ("right now in this big cycle, …")
  • Ten-gods name not surfaced in body

  Quality:
  • 785 tests PASS (4 new R86 sprint 4 regression guards)
  • flutter analyze 0 issue
  • Five-element golden 1995-10-27 male 17h 16/21/17/41/4 preserved
  • R69 lock + R71~R85 + R78 daewoon anchor wire all preserved

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
                             relationships: {build: {data: {type: 'builds', id: b45_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b45_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b45_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
