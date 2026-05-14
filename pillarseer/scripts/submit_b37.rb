#!/usr/bin/env ruby
# Build #37 — Round 77 codex 9.9+ × 8 sprint (avg 9.94).
# Round 77 = 4선수 (codex×2 + opus×2) 부자연 표현·오류·UX 대결 (R1/R2/R3 × 1게임)
# → 115 진짜 발견 (false positive 0) → 8 sprint × harness → 110+ fix.
# Sprint 1 사주 엔진 / 2 데이터 wire / 3 Apple guideline / 4 한국어 톤 + 60일주 1440 phrase
# Sprint 5 영문 grammar 500+ / 6-7 UX MZ K-POP / 8 cleanup + 회귀 가드.
require_relative '_helpers'

# 1. Build #37 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=37&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #37 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b37_id = b['id']
state = b['attributes']['processingState']
puts "[Build #37 id=#{b37_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b37_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — Round 77 4선수 대결 → 8 sprint
ko_text = <<~KO.strip
  v1.0.0 Build #37 — 4선수 대결 115 발견 / 8 sprint × codex 9.94.

  • 사주 엔진 8 fix (월주 fallback / 음력 처리 / 대운 절기 거리 / 일간 비견 / 자형 / 천안 좌표 / 절기 boundary)
  • 데이터·Wire (셀럽 gender·today_event_pool 90 entries wire·빈 괄호 누출·"당신" 호칭 통일)
  • Apple guideline 60+ 헷지 (의료·금융·사망 단정 → 가능성)
  • 한국어 톤 50+ + 60일주 1440 phrase 해요체 (한자 jargon 제거)
  • 영문 grammar 500+ (ChatGPT 슬롭 / 60갑자 "for" 비문)
  • UX MZ K-POP — First fold OracleHero+TodayEvent / 별점 색 게이지 / 상단 공유 / K-POP 1순위 / 셀럽 chip / skeleton / 알림 MZ 50개 / Profile 1080×1080 PNG 공유
  • Cleanup + 회귀 가드 test (10 assertion) + 1995-10-27 男 골든 5행 16/21/17/41/4 보존
  • analyze 0 / test 433 PASS

  codex 9.9+ × 8 sprint (avg 9.94 / 10.0 만점 1회).

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #37 — 4-player audit + 8 sprints × codex 9.94.

  • Saju engine 8 fixes (month pillar fallback / lunar age / Daewoon start age / day-master Friend / self-clash / Cheonan coords / solar-term boundary)
  • Data + wiring (celebrity gender / today_event_pool 90 entries / empty-paren leak / "you" tone unified)
  • Apple guideline hedging on 60+ medical, financial, mortality lines
  • Korean tone mandate 50+ + 60-pillar 1440 phrases rewritten in friendly "yo" style
  • English grammar 500+ (ChatGPT slop / 60-pillar "for" sentence fragments)
  • UX for Korean Gen-Z K-pop fans — First-fold = OracleHero + TodayEvent, color gauge, top share, K-pop compatibility promoted, celeb chips, skeletons, 50 MZ-flavored notifications, 1080×1080 profile share card
  • Cleanup + regression guard test (10 assertions) + 1995-10-27 male golden 16/21/17/41/4 preserved
  • analyze 0 / test 433 PASS

  codex 9.9+ across 8 sprints (avg 9.94 / one perfect 10.0).

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
                             relationships: {build: {data: {type: 'builds', id: b37_id}}}}})
    puts "  POST #{locale}: HTTP #{code}"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b37_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b37_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
