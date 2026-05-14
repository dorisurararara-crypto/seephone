#!/usr/bin/env ruby
# Build #39 — Round 79: 사주 정확도 대전환 + 화면 분리 (Task A B C D)
# Playwright unsin reverse 6 sample + Community 9 키워드 7 fetch
# H3 본문 wire (PersonalizationEngine 격국·용신·신살 anchor) + /today route 화면 분리
# 9 sprint × codex 9.94 avg / 504 test PASS / 5행 골든 1995-10-27 男 17시 16/21/17/41/4 보존
require_relative '_helpers'

# 1. Build #39 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=39&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #39 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b39_id = b['id']
state = b['attributes']['processingState']
puts "[Build #39 id=#{b39_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b39_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — Round 79 사주 정확도 대전환 + 화면 분리
ko_text = <<~KO.strip
  v1.0.0 Build #39 — Round 79 사주 정확도 대전환 + 화면 분리.

  • Playwright 운세의신 6 sample 분석 — 5행 raw 216 기반 + 일주 일치율 50% 발견
  • Community 9 키워드 + 7 페이지 학파 검증 — 자평진전·적천수·궁통보감 3 학파 종합
  • PersonalReading 격국·용신·신살 anchor 본문 동적화 — bodyKo/actionKo/cautionKo 모두 사주 derive
  • /today route 신규 — 평생사주와 오늘 영역 화면 분리 ("내 사주 = 평생사주만" mandate)
  • DynamicTextResolver shinsaAnchor 8종 (천을귀인·문창귀인·도화·역마·화개·양인·괴강·백호)
  • 만세력 audit docs — 일주 불일치 3 sample 가설 정리 (Round 80 deferred fix)
  • 5행 골든 1995-10-27 男 17시 16/21/17/41/4 절대 보존 / 한자 jargon 0 / 폐기 phrase 0
  • analyze 0 / test 504 PASS (R78 495 → +9 신규 골든)

  codex 9.9+ × 9 sprint (avg 9.94).

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #39 — Round 79: Saju accuracy overhaul + screen split.

  • Playwright unsin.co.kr 6-sample reverse — raw sum=216 base discovered + 50% day-pillar match rate
  • Community 9 keyword + 7 page WebFetch — Japyeong-jinjeon + Jeokcheonsu + Gungtongbogam 3-school synthesis
  • PersonalReading gyeokguk + yongsin + shinsa anchor dynamic body — bodyKo/actionKo/cautionKo all derive from chart
  • New `/today` route — separates lifetime saju from today section ("my saju = lifetime only" mandate)
  • DynamicTextResolver shinsaAnchor 8 types (Cheoneul-Guin/Munchang/Dohwa/Yeokma/Hwagae/Yangin/Gwaegang/Baekho)
  • Manseryeok audit docs — 3 sample day-pillar mismatch hypotheses (Round 80 deferred fix)
  • 1995-10-27 male 17:00 5-element golden 16/21/17/41/4 absolute preservation / 0 hanja jargon / 0 banned phrases
  • analyze 0 / test 504 PASS (R78 495 → +9 new golden)

  codex 9.9+ across 9 sprints (avg 9.94).

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
                             relationships: {build: {data: {type: 'builds', id: b39_id}}}}})
    puts "  POST #{locale}: HTTP #{code}"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b39_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b39_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
