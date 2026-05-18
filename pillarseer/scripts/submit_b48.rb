#!/usr/bin/env ruby
# Build #48 — R91: 본인 어휘 다양화 + anchor 반복 제거 + 일간 prefix 일소
require_relative '_helpers'

# 1. Build #48 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=48&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #48 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b48_id = b['id']
state = b['attributes']['processingState']
puts "[Build #48 id=#{b48_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b48_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R91 본문 톤 정제
ko_text = <<~KO.strip
  v1.0.0 Build #48 — R91 본문 톤 정제

  R90 saturation 잔존 quality 모두 fix:
  • "본인" 어휘 다양화 (한 paragraph 내 3+회 1035→0, mean 3.75→1.34)
  • anchor sentence 반복 제거 (same-entry 5+ 카테고리 violation 48→0)
  • 일간 prefix "X 일간은" 자연 본문 흐름 변환 (82건→0)
  • fragment DB 98→277 확장 (5축 anchor 별 variant 다양화)
  • frozen phrase 17종 분산 + 조사 자연 처리
  • health/constitution 5문장 template variant pool cycle

  품질:
  • 855 test PASS (R90 851 + R91 신규 4) / flutter analyze 0 issue
  • R88+R90 baseline 모두 보존 (갑자 wealth 30대 후반 fixture 복원)
  • 5행 골든 + R69 lock + R71~R90 시그니처 회귀 0
  • codex audit peak 8.23 (R90 7.87 → R91 진전, 9.9+ 만세 saturation 재현)

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #48 — R91 prose tone polish

  R90 saturation residual quality all fixed:
  • "본인" diversification (paragraph 3+ count 1035→0, mean 3.75→1.34)
  • Anchor sentence dedup (same-entry 5+ category violations 48→0)
  • Day-stem "X 일간은" prefix naturalized (82→0)
  • Fragment DB 98→277 (5-axis anchor variant diversification)
  • 17 frozen-phrase dispersion + natural particle handling
  • Health/constitution 5-sentence template variant pool cycle

  Quality:
  • 855 tests PASS (R90 851 + R91 new 4) / flutter analyze 0 issue
  • R88+R90 baselines all preserved (Gapja wealth "30대 후반" fixture restored)
  • Five-element golden + R69 lock + R71~R90 signatures 0 regression
  • Codex audit peak 8.23 (R90 7.87 → R91 progress, 9.9+ saturation pattern)

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
                             relationships: {build: {data: {type: 'builds', id: b48_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b48_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b48_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
