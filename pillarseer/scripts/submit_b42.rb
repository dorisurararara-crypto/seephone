#!/usr/bin/env ruby
# Build #42 — R85 메뉴 정리 + 오늘 사주 총평 first-fold
# 766 test PASS / flutter analyze 0 issue / 5행 골든 + R69 lock + R71~R84 시그니처 보존
require_relative '_helpers'

# 1. Build #42 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=42&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #42 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b42_id = b['id']
state = b['attributes']['processingState']
puts "[Build #42 id=#{b42_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b42_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R85 (≤500자 mandate)
ko_text = <<~KO.strip
  v1.0.0 Build #42 — R85 메뉴/홈 정리.

  메뉴 단순화:
  • 하단 탭에서 한자 보조 글리프 제거 (가독성 ↑)
  • "리포트" → "더 보기" 로 변경
  • 더 보기 화면을 4 카드로 정리 (궁합 / 2026 신년운세 / 해몽 / K-POP 궁합)

  홈 첫 화면 개선:
  • "오늘 사주 총평" 카드를 가장 위로 — 5문장 이상 한자 jargon 0
  • 이전의 인사말 / 일주 카드 / "오늘 추천" 섹션은 정리

  오늘 탭:
  • 오늘 사주 총평을 사건 가능성 카드보다 위로

  l10n:
  • 한국어 + 영어 신규 카피 동기화

  품질:
  • 766 test PASS (R85 신규 회귀 가드 2)
  • flutter analyze 0 issue
  • 5행 골든 1995-10-27 男 17시 16/21/17/41/4 보존
  • R69 lock + R71~R84 시그니처 모두 보존

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #42 — R85 menu & home polish.

  Menu cleanup:
  • Removed hanja helper glyphs from bottom tab bar
  • "Reports" renamed to "More"
  • More screen trimmed to 4 cards (Compat / 2026 New Year / Dream / K-POP Compat)

  Home first-fold:
  • "Today's Saju Summary" card moved to the very top — 5+ sentences, zero hanja jargon
  • Previous greeting / pillar-of-the-day / "try today" sections cleaned up

  Today tab:
  • Today's Saju Summary now appears above the event-likelihood card

  Locale:
  • Korean + English new copy synced

  Quality:
  • 766 tests PASS (R85 2 new regression guards)
  • flutter analyze 0 issue
  • Five-element golden 1995-10-27 male 17h 16/21/17/41/4 preserved
  • R69 lock + R71~R84 signatures all preserved

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
                             relationships: {build: {data: {type: 'builds', id: b42_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b42_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b42_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
