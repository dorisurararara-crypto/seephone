#!/usr/bin/env ruby
# Build #50 — R92: entry 단위 codex 9.9+ 목표 quality 정제 4 round
require_relative '_helpers'

BUILD_NO = 50

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

# 3. whatsNew — R92 entry 단위 codex 9.9+ 목표 정제
ko_text = <<~KO.strip
  v1.0.0 Build ##{BUILD_NO} — R92 entry-단위 quality 정제

  R91 saturation peak 8.23 → R92 4 round 정제:
  • entry-간 첫 문장 중복 245→1 (천간별 6 trait × 17 cat modifier × 받침 grammar 정확)
  • R88 generator artifact 일소 (562 substitution: "강해서" 잔존 패턴 / 30대 후반면 등)
  • MZ K-POP 어휘 inject (1200 entry × 1st + 2nd sentence: 단톡/덕질/플레이리스트/응원봉/팬싸/본진)
  • 천간 deep persona append (10 천간 × 3 phrase × 1020 entry)
  • 3 critical broken entry fix (갑오 dedup 오탈자 / 정사 의미불명 / 무인 황금기 구문)
  • 자리잡 family cumulative dedup (자리잡아요/자리잡는/자리잡으면/자리잡힐)

  품질:
  • 855 test PASS / flutter analyze 0 issue
  • codex sample 30 entry 평균 8.4 (R91 7.87 saturation peak 대비 +0.5)
  • R88+R90+R91 baseline 모두 보존 (5행 골든 + R69 lock + R71~R91 시그니처)
  • R77 한자 jargon 0 / R89 B4 직장인 jargon 0

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build ##{BUILD_NO} — R92 entry-level quality polish

  R91 saturation peak 8.23 → R92 four-round refinement:
  • Cross-entry first-sentence dup 245→1 (6 trait per stem × 17 cat modifier × particle grammar)
  • R88 generator artifact sweep (562 substitutions: "강해서" residuals / "후반면" / etc.)
  • MZ K-POP vocab inject (1200 entries × 1st + 2nd sentence: 단톡/덕질/플레이리스트/응원봉/팬싸/본진)
  • Heavenly-stem deep persona append (10 stems × 3 phrases × 1020 entries)
  • 3 critical broken entries fixed (갑오 dedup typo / 정사 unclear / 무인 wealth phrasing)
  • 자리잡 family cumulative dedup

  Quality:
  • 855 tests PASS / flutter analyze 0 issue
  • codex sample 30 entries avg 8.4 (R91 peak 7.87, +0.5 improvement)
  • R88+R90+R91 baselines all preserved
  • R77 hanja jargon 0 / R89 B4 workplace jargon 0

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
