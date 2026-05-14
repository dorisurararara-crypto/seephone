#!/usr/bin/env ruby
# Build #34 — Round 73 codex 9.9+ PASS (6 sprint).
# marketing 1.0.0 위에 새 빌드 (사용자 명시: 이미 승인된 1.0.0 위에 build bump → 심사 빠름).
require_relative '_helpers'

# 1. Build #34 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=34&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #34 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b34_id = b['id']
state = b['attributes']['processingState']
puts "[Build #34 id=#{b34_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b34_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — Round 73 운세의신 수준 정확도 + 영문 leak fix
ko_text = <<~KO.strip
  v1.0.0 Build #34 — Round 73 codex 9.9+ PASS (6 sprint × avg 9.93)

  한국 1위 사주 사이트 운세의신 (스포츠조선 운영) deep analysis (codex 9.97 PASS)
  → 우리 앱 진단 (codex 9.6 4 dim 통과) → 6 sprint 구현:

  1. 영문 모드 한글 leak 6 source fix (SixAxis / FiveDayTrend / MatchBadge / axes / labels / CrossMatch 56 string)
  2. DaewoonService wire 0 → 1 — 초년/중년/말년 라이프스테이지 카드 (life_stage_pool 60 entry)
  3. 8글자 십신 풀이 — 같은 일주여도 천간/지지 십신 분포 다르면 phrase 30%+ 차별 (sipsin_persona 120 entry)
  4. 운세의신 17 섹션 결과 화면 재구성 — 자미두수 숨김 유지 (kIsZiweiUiHidden=true)
  5. 폴라리티 5:4:1 + 행동 처방 23% + 양면 단정 56% + 헷지 0
  6. 직업 추천 + 재테크 3 phase (career_pool 30 + wealth_detail 8×3 entry)

  검증:
  • flutter analyze 0 error
  • flutter test 363/363 PASS (신규 20 + 기존 343)
  • polarity_audit 264 entry PASS (hedge 0 / slop 0 / 폴라리티 43:32:8)
  • 1995-10-27 신묘 case 정인+상관 → 언론인/기고가/작가 의미 매칭 ✅

  차별점 유지 (운세의신 X): 자미두수 / 60갑자 / 무료 today / 6각 radar / _OracleHero / 지장간+월령 ×2.5

  codex 9.9+ 평가:
  • A 디자인+사용자 mandate 9.93
  • B 운세의신 정량 정합 9.95
  • C 십신 풀이 + 기술 9.93
  • D 통합 9.92

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #34 — Round 73 codex 9.9+ PASS (6 sprints × avg 9.93)

  Korea's #1 saju site Unsewui (Sports Chosun) deep analysis (codex 9.97 PASS)
  → our app diagnosis (codex 9.6 4 dim pass) → 6 sprints:

  1. EN mode Korean leak fix at 6 sources (SixAxis / FiveDayTrend / MatchBadge / axes / labels / CrossMatch 56 strings)
  2. DaewoonService wire 0 → 1 — life stage cards (early/mid/late, life_stage_pool 60 entries)
  3. 8-char Ten Gods reading — same day pillar but different stem/branch Ten Gods → 30%+ phrase differentiation (sipsin_persona 120 entries)
  4. 17-section result_screen reconstruction — Ziwei UI hidden (kIsZiweiUiHidden=true)
  5. Polarity 5:4:1 + 23% action prescription + 56% two-sided assertion + 0 hedges
  6. Career recommendation + 3-phase wealth strategy (career_pool 30 + wealth_detail 8×3 entries)

  Verification:
  • flutter analyze 0 errors
  • flutter test 363/363 PASS (20 new + 343 existing)
  • polarity_audit 264 entries PASS (hedge 0 / slop 0 / polarity 43:32:8)
  • 1995-10-27 case 正印+傷官 → journalist/writer/PD semantic match ✅

  Differentiators kept (not in Unsewui): Ziwei / 60-pillar / free today / 6-axis radar / OracleHero / hidden stems × month boost

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
                             relationships: {build: {data: {type: 'builds', id: b34_id}}}}})
    puts "  POST #{locale}: HTTP #{code}"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b34_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b34_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
