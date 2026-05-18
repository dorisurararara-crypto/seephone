#!/usr/bin/env ruby
# Build #47 — R90: 사주 anchor 5축 다층화 + paragraphForSaju + 일주 prefix 1211 일소
require_relative '_helpers'

# 1. Build #47 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=47&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #47 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b47_id = b['id']
state = b['attributes']['processingState']
puts "[Build #47 id=#{b47_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b47_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R87+R88+R89 통합
ko_text = <<~KO.strip
  v1.0.0 Build #47 — R90 사주 anchor 다층화 fix

  R89 실기기 검증 결함 직발 → R90 즉시 fix:
  • 같은 신묘 일주여도 본인 사주 anchor (월령/십성/격국/5행)가 다르면 본문이 달라져요
  • paragraph 본문에서 "일주 prefix" 1211 string 일소
  • LifeParagraphService 가 사주 전체를 받도록 새 method (paragraphForSaju) 추가
  • 운세의신 사상 정합 — 일간/월령/5행/십성/격국 5축 anchor 다층화
  • LifeOverviewService 6 anchor + 1 gender 마무리 재구성 (essay 600~900자)
  • 새 LifeCategoryFragmentService (130+ fragment) 카테고리×anchor 매트릭스

  품질:
  • 850 test PASS (R89 843 + R90 신규 7) / flutter analyze 0 issue
  • 5행 골든 + R69 lock + R71~R89 시그니처 모두 보존
  • 본인 vs 여친 같은 일주 다른 사주 Jaccard 차별성 ≥ 40% 검증

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #47 — R90 saju anchor layering fix

  R89 device verification flaw → R90 immediate fix:
  • Same Shin-Myo day pillar now produces different paragraphs when other saju anchors (month-rule/ten-gods/gyeokguk/5-elements) differ
  • Removed 1211 "<day-pillar> 일주" prefixes from paragraph bodies
  • New paragraphForSaju method on LifeParagraphService (takes the full SajuResult)
  • Unsin alignment — 5-axis anchor layering (day-stem / month-rule / 5 elements / ten-gods / gyeokguk)
  • LifeOverviewService 6-anchor + gender closing restructure (600~900 char essay)
  • New LifeCategoryFragmentService (130+ fragments) with category × anchor matrix

  Quality:
  • 850 tests PASS (R89 843 + R90 new 7) / flutter analyze 0 issue
  • Five-element golden + R69 lock + R71~R89 signatures all preserved
  • Verified Jaccard diversity ≥ 40% for same day-pillar different saju (boyfriend vs girlfriend)

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
                             relationships: {build: {data: {type: 'builds', id: b47_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b47_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b47_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
