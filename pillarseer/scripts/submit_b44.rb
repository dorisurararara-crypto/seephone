#!/usr/bin/env ruby
# Build #44 — R86 sprint 3: Mock B 비비드 五行 아이콘/스플래시 적용
# 781 test PASS / flutter analyze 0 issue / 5행 골든 + R69 lock + R71~R85 시그니처 보존
require_relative '_helpers'

# 1. Build #44 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=44&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #44 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b44_id = b['id']
state = b['attributes']['processingState']
puts "[Build #44 id=#{b44_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b44_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R86 sprint 3 (≤500자 mandate)
ko_text = <<~KO.strip
  v1.0.0 Build #44 — R86 비비드 五行 아이콘/스플래시.

  아이콘:
  • 페이퍼 베이지 위 ink 원환 + 중앙 "柱" 한자
  • 5색 점 비비드 (emerald·vermilion·amber·platinum·cobalt)
  • iOS 15 size · macOS 7 size 일괄 갱신

  스플래시:
  • 배경 white → paper (#efe6d2) 갱신
  • 같은 ring + 柱 정사각 logo 사용 (브랜드 일관성)

  품질:
  • 781 test PASS (R86 sprint 3 신규 회귀 가드 6)
  • flutter analyze 0 issue
  • 5행 골든 1995-10-27 男 17시 16/21/17/41/4 보존
  • R69 lock + R71~R85 시그니처 모두 보존

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #44 — R86 vivid five-element icon & splash.

  App icon:
  • Paper ivory bg with ink circle + center "柱" hanja
  • Five vivid color dots (emerald · vermilion · amber · platinum · cobalt)
  • iOS 15 sizes + macOS 7 sizes all regenerated

  Splash:
  • Launch background white → paper (#efe6d2)
  • Same ring + 柱 square logo for brand consistency

  Quality:
  • 781 tests PASS (6 new R86 sprint 3 regression guards)
  • flutter analyze 0 issue
  • Five-element golden 1995-10-27 male 17h 16/21/17/41/4 preserved
  • R69 lock + R71~R85 signatures all preserved

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
                             relationships: {build: {data: {type: 'builds', id: b44_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b44_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b44_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
