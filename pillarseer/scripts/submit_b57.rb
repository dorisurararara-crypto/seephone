#!/usr/bin/env ruby
# Build #57 — R96 sprint 1: 최애 케미 본문 복붙 fix — verdict variant pool 8×6×2=96 + per-celeb FNV-1a seed (codex 8.6→9.5 GO)
require_relative '_helpers'

BUILD_NO = 57

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

# 3. whatsNew — R96 sprint 1 사용자 verbatim mandate (최애 케미 복붙 fix)
ko_text = <<~KO.strip
  v1.0.0 Build ##{BUILD_NO} — R96 sprint 1 최애 케미 복붙 fix

  사용자 verbatim:
  "최애와의 케미가 아직도 다 복사 붙여넣기네 그냥 이름만 다르고 ?"

  Root cause (codex 8.6→9.5): _composeVerdict 가 relation 별 4 templates 풀 +
  셀럽 이름만 inject → 같은 일주 셀럽 7명이 동일한 relation line 을 받음
  ("그냥 이름만 다른 복붙").

  R96 sprint 1 fix:
  • verdict variant pool 8 × 6 relation × KO/EN = 96 templates (이전 48)
    — relation 별 ko/en 풀 모두 ≥6 entry
  • _verdictSeed FNV-1a hash 추가 (star.id + dayPillar + birth + 본인 천간·지지
    + 셀럽 천간·지지 + relation idx + 강·약 anchor 갯수) — 셀럽별 deterministic
    32bit seed → 같은 일주여도 본문 unique
  • closerVariant 5 KO + 5 EN, seed-shifted (relation idx 와 decorrelate)
  • anchor 한국어 노출 제거:
    "강한 anchor" → "강하게 끌어주는 자리"
    "약한 anchor" → "조심해야 할 자리"
    "직접 걸린 anchor 없이" → "직접 걸린 큰 자극 없이"
  • "결" jargon softening (6 위치): "시너지가 가장 큰 결" → "시너지가 가장 큰
    흐름" / "깊어지는 결" → "깊어지는 관계" 등
  • 잔존 minor 2 fix: "조심해야 할 자리 0개" conditional 처리 (strong/weak 가
    0 일 때 phrase 자체 제외) + "직접 걸리는/걸린" 시제 통일

  검증:
  • 戊戌 7명 unique seed 7/7
  • relation line 5/7 unique (collision 시 identityLead + closer 결합으로 verdict
    body 전체 unique)
  • flutter analyze 0 / flutter test 871/871 PASS
  • R71/R93/R95/R97 baseline 모두 보존

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build ##{BUILD_NO} — R96 sprint 1 K-pop chemistry copy-paste fix

  User verbatim:
  "Still copy-pasted text for chemistry with stars — only the name changes?"

  Root cause (codex 8.6→9.5): _composeVerdict offered only 4 templates per
  relation + injected the celebrity name — 7 stars sharing the same day-pillar
  ended up reading the exact same relation line ("only the name changes").

  R96 sprint 1 fix:
  • verdict variant pool expanded to 8 × 6 relations × KO/EN = 96 templates
    (was 48); every relation pool now has ≥6 entries in both languages
  • added _verdictSeed FNV-1a hash (star.id + dayPillar + birth + my stem+branch
    + star stem+branch + relation idx + strong/weak anchor counts) → deterministic
    32-bit per-celebrity seed, so same day-pillar still varies the body
  • closerVariant: 5 KO + 5 EN, seed-shifted to decorrelate from the relation idx
  • removed Korean "anchor" jargon:
    "강한 anchor" → "강하게 끌어주는 자리"
    "약한 anchor" → "조심해야 할 자리"
    "직접 걸린 anchor 없이" → "직접 걸린 큰 자극 없이"
  • softened "결" jargon in 6 places: "시너지가 가장 큰 결" → "시너지가 가장
    큰 흐름" / "깊어지는 결" → "깊어지는 관계" etc.
  • two residual minor fixes: skip "조심해야 할 자리 0개" entirely when the count
    is 0 (no more zero-count phrasing) + tense unified on "직접 걸린"

  Verification:
  • 7 戊戌 stars produced 7 unique seeds
  • 5/7 unique relation lines (collisions still differ via identityLead + closer
    so the full verdict body stays unique)
  • flutter analyze 0 / flutter test 871/871 PASS
  • R71/R93/R95/R97 baselines all preserved

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
