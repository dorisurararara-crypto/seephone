#!/usr/bin/env ruby
# Build #32 — Round 7~14 codex 감독 다단계 fix.
require_relative '_helpers'

# 1. Build #32 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=32&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #32 not found yet.'
  exit 1
end
b32_id = b['id']
state = b['attributes']['processingState']
puts "[Build #32 id=#{b32_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b32_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew
ko_text = <<~KO.strip
  v1.0.2 Build #32 — 콘텐츠 대규모 확장 (Round 62~64).

  사주 풀이 콜드리딩 주입
  • 60일주 × 7 카테고리 × KO/EN = 840 필드에 자연스러운 콜드리딩 한 줄 삽입
  • Barnum/Forer 기법 — 60일주 모두 unique combo 보장 (중복 0)
  • dayMasterDeep 3-slot triple, love/career/wealth 등 2-slot pair
  • 사용자가 자기 일주 풀이를 "맞다"고 더 깊이 공감

  K-POP 스타 궁합 확장
  • 셀럽 데이터 20 → 62명 (310% 증가)
  • NewJeans 5, IVE 6, LE SSERAFIM 4, ITZY 5, aespa 3, ENHYPEN 7, SEVENTEEN 5, TXT 5, RIIZE 2
  • 35 unique 일주 cover — 어떤 일주든 매칭 다양성 ↑
  • 일주 자동 계산 (klc 라이브러리)

  해몽 사전 대확장
  • 50 → 509 entries (10배)
  • 11 카테고리: 동물 60+, 자연 50+, 물·날씨 30+, 음식 40+, 사람 50+, 신체 30+, 색·숫자 30+, 물건·건물 50+, 활동 40+, 감정 30+, 영적 20+
  • 한국 전통 해몽 사전 기반 + 길흉 분류
  • 각 항목 2-3 문장 의미 풀이

  검증
  • flutter analyze: clean
  • flutter test: 288/288 통과 (content_integrity 중복 검사 포함)

  Notes: 한 번 보고 끝나지 않게 사용자가 매일 들어와 재방문 — 콘텐츠 풍부함 우선.
KO

en_text = <<~EN.strip
  v1.0.2 Build #32 — Major content expansion (Round 62-64).

  Saju Cold Reading Injection
  • 60 day pillars × 7 categories × KO/EN = 840 fields with natural cold reading sentences
  • Barnum / Forer technique — every pillar gets unique combo (zero duplicates)
  • dayMasterDeep uses 3-slot triple; love/career/wealth uses 2-slot pair
  • Users feel "this is me" more deeply when reading their pillar

  K-POP Star Compatibility Expansion
  • Celebrity dataset 20 → 62 (310% growth)
  • NewJeans 5, IVE 6, LE SSERAFIM 4, ITZY 5, aespa 3, ENHYPEN 7, SEVENTEEN 5, TXT 5, RIIZE 2
  • 35 unique day pillars covered — better matching variety
  • Day pillar auto-computed via klc library

  Dream Dictionary Major Expansion
  • 50 → 509 entries (10×)
  • 11 categories: animals 60+, nature 50+, water 30+, food 40+, people 50+, body 30+, color/number 30+, objects 50+, activities 40+, emotions 30+, spiritual 20+
  • Traditional Korean dream interpretation + auspicious/warning classification
  • Each entry has 2-3 sentence interpretation

  Verification
  • flutter analyze: clean
  • flutter test: 288/288 pass (includes content_integrity dedup check)

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
                             relationships: {build: {data: {type: 'builds', id: b32_id}}}}})
    puts "  POST #{locale}: HTTP #{code}"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b32_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b32_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
