#!/usr/bin/env ruby
# Build #38 — Round 78: 하드코딩 13 hotspot 일소 + 운세의신 (unsin.co.kr) 2차 deep analysis
# SajuContext 합성 (천간·오행·대운·십신·신살) → DynamicTextResolver 4단계 chain
# 격국 anchor / 용신 5축 (색·방향·음식·시간대·요일) / 합충 36 / 신살 24 / 공망 wire
# 8 sprint × codex 9.93 avg / 495 test PASS / 5행 골든 1995-10-27 男 16/21/17/41/4 보존
require_relative '_helpers'

# 1. Build #38 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=38&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #38 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b38_id = b['id']
state = b['attributes']['processingState']
puts "[Build #38 id=#{b38_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b38_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — Round 78 하드코딩 일소 + 운세의신 2차
ko_text = <<~KO.strip
  v1.0.0 Build #38 — Round 78 하드코딩 13 hotspot 일소 + 운세의신 2차 분석.

  • SajuContext 합성 — 천간·오행%·대운·십신 강약·신살을 한 곳에 모아 본문 분기 입력으로
  • DynamicTextResolver 4단계 chain — 격국 → 용신 → 일간 → 기본 순서로 fallback
  • 격국 anchor 도입 — 같은 천간이라도 격국 다르면 today_deep 본문 갈래 다름
  • 용신 5축 행동 처방 — 색/방향/음식/시간대/요일 한 줄 멘트
  • 대운 십신 wire — 현재 대운 10년 단계가 본문에 자연스럽게 녹음
  • 합·충·형·파·해 36 + 신살 24 + 공망 wire — today_event 분석 깊이 확장
  • 신년 12달 격국 derive — new_year_2026 본문에 사주별 분기
  • 운세의신 2차 deep analysis (V1~V8) — 격국×십신×용신 join / 후기 톤 흡수
  • 5행 골든 1995-10-27 男 16/21/17/41/4 보존 / R71 invariant 회귀 0
  • analyze 0 / test 495 PASS (R77 433 → +62)

  codex 9.9+ × 8 sprint (avg 9.93).

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #38 — Round 78: 13 hardcoded hotspots cleared + unsin.co.kr 2nd deep analysis.

  • SajuContext aggregation — heavenly stem, five-element %, Daewoon, ten-god strength, shinsa in one input for body branching
  • DynamicTextResolver 4-step chain — gyeokguk → yongsin → day-master → default fallback
  • Gyeokguk anchor — same stem can now produce different today_deep narratives depending on chart formation
  • Yongsin 5-axis prescriptions — color, direction, food, time-of-day, weekday one-liner
  • Daewoon ten-god wiring — current 10-year cycle stage naturally woven into body
  • Hap/Chung/Hyeong/Pa/Hae 36 + Shinsa 24 + Gongmang wired into today_event depth
  • New-year 2026 12-month gyeokguk derivation — branches by chart
  • unsin.co.kr 2nd deep analysis (V1~V8) — gyeokguk × ten-god × yongsin join, review-tone absorption
  • 1995-10-27 male 5-element golden 16/21/17/41/4 preserved / R71 invariants intact
  • analyze 0 / test 495 PASS (R77 433 → +62)

  codex 9.9+ across 8 sprints (avg 9.93).

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
                             relationships: {build: {data: {type: 'builds', id: b38_id}}}}})
    puts "  POST #{locale}: HTTP #{code}"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b38_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b38_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
