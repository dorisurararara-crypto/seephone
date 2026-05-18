#!/usr/bin/env ruby
# Build #54 — R95: 사용자 3 mandate + 중복 패턴 4 영역 fix (codex 9.95 SHIP)
require_relative '_helpers'

BUILD_NO = 54

# 1. Build id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=#{BUILD_NO}&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts "❌ Build ##{BUILD_NO} not found yet. (Apple processing 5~15분 대기 후 재시도)"
  exit 1
end
b_id = b['id']
state = b['attributes']['processingState']
puts "[Build ##{BUILD_NO} id=#{b_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R95 사용자 3 mandate + 중복 패턴 4 영역 fix
ko_text = <<~KO.strip
  v1.0.0 Build ##{BUILD_NO} — R95 사용자 3 mandate + 중복 패턴 4 영역 fix

  R94 1.0.0+53 실기기 검증 후 받은 사용자 verbatim 3 mandate + "중복 패턴 다 수정":

  1. 입력 화면 첫 커서 — 이름 필드 autofocus
     • "처음에 내 운명 입력할때 커서가 맨위인 이름에 가야하는데" → input_screen autofocus 이름 필드

  2. 최애와의 케미 첫 문장 셀럽별 변별
     • "맨 첫문장이 다 똑같아 점수로 매칭하지 말라니까 각각 궁합보듯이" → _starIdentityLead helper
     • p1/p2/p3 셀럽별 일주·일간·연주 anchor 분기 첫 문장 생성

  3. harness 방식 정통 적용
     • "harness방식으로 작업한거맞아?" → 본 R95 부터 codex planner/evaluator + Claude 메신저 + 서브에이전트 코딩 방식

  4. 중복 패턴 4 영역 일소 ("중복된 패턴있으면 다 수정")
     • compatibility _analyze() — element/branch/stem pair microcopy 25+12+5
     • new_year_2026 _AnnualSummary — 일지 vs 午 microcopy 분기
     • new_year_2026 _TwelveAreas — _buildAreaReadings 완전 동적화

  품질: codex evaluator 9.95/10 SHIP / flutter analyze 0 / flutter test 861/861 PASS / R94 baseline (loveMarriage / 4 TextField / _yearMicroAdjust) 보존.

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build ##{BUILD_NO} — R95 three user mandates + duplicate pattern fixes (4 areas)

  Post-device feedback on 1.0.0+53 — three verbatim mandates + "fix all duplicate patterns":

  1. Input screen first cursor — name field autofocus
     • "When I first enter my fate, cursor should be on the top name field" → input_screen autofocus name

  2. K-POP chemistry — first sentence varies per celeb
     • "First sentence is all identical — don't match by score, read each like a proper compatibility check"
     • _starIdentityLead helper branches by p1/p2/p3 celeb day-pillar / day-master / year-pillar anchors

  3. Harness workflow adopted
     • From R95 onward: codex = planner/evaluator, Claude = messenger, subagents = coders

  4. Duplicate patterns purged in 4 areas
     • compatibility _analyze() — element/branch/stem pair microcopy 25+12+5
     • new_year_2026 _AnnualSummary — day-branch vs 午 microcopy branch
     • new_year_2026 _TwelveAreas — _buildAreaReadings fully dynamic

  Quality: codex evaluator 9.95/10 SHIP / flutter analyze 0 / test 861/861 PASS / R94 baselines preserved (loveMarriage / 4 TextField / _yearMicroAdjust).

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
                             relationships: {build: {data: {type: 'builds', id: b_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
