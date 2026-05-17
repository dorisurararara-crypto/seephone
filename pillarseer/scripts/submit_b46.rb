#!/usr/bin/env ruby
# Build #46 — R89 sprint 1~4: 60 일주 paragraph + chip nav + dead code 정리 + R87+R88+R89 통합
require_relative '_helpers'

# 1. Build #46 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=46&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #46 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b46_id = b['id']
state = b['attributes']['processingState']
puts "[Build #46 id=#{b46_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b46_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R87+R88+R89 통합
ko_text = <<~KO.strip
  v1.0.0 Build #46 — R87+R88+R89 통합

  R87 sprint 1~4:
  • 더보기 탭 케미 hero
  • 모든 카드 공유 hook
  • 해외 출생지 IANA tz ~150 도시
  • 용신 spoiler

  R88 sprint 1~10 (운세의신 17 카테고리 대전환):
  • deep myeongli 8종 widget 제거 → 인생 분류 17 카테고리 frame
  • LifeParagraphService + LifeOverviewService + SelfConclusionService 3 service
  • "내 사주 큰 그림" + "나는 어떤 사람?" + 17 카테고리 paragraph

  R89 sprint 1~4 (deferred 종결):
  • 60 일주 × 14 unisex + 3 split × M/F = 1380 paragraph
  • 같은 일간 사용자도 일주마다 다른 본문 (R80 sprint 1 회귀 차단)
  • 17 카테고리 chip nav (Aesop minimal)
  • info_saju_calc_screen.dart dead code 완전 삭제

  품질:
  • 843 test PASS / flutter analyze 0 issue
  • 5행 골든 + R69 lock + R71~R88 시그니처 모두 보존

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #46 — R87+R88+R89 combined

  R87 sprint 1~4:
  • K-pop chemistry hero on Discover tab
  • Card share hook everywhere
  • IANA tz for ~150 international cities
  • Yongsin spoiler reveal

  R88 sprint 1~10 (Unsin 17-category transition):
  • Removed 8 deep myeongli widgets — moved to 17 life-category frame
  • New services: LifeParagraphService / LifeOverviewService / SelfConclusionService
  • "Big picture" + "Who you are" + 17-category paragraph

  R89 sprint 1~4 (deferred completion):
  • 60 day-pillars × 14 unisex + 3 split × M/F = 1380 paragraph
  • Same day-stem users now see distinct text per day-pillar (R80 sprint 1 regression blocked)
  • 17-category chip nav (Aesop minimal)
  • info_saju_calc_screen.dart dead code fully removed

  Quality:
  • 843 tests PASS / flutter analyze 0 issue
  • Five-element golden + R69 lock + R71~R88 signatures all preserved

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
                             relationships: {build: {data: {type: 'builds', id: b46_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b46_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b46_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
