#!/usr/bin/env ruby
# Build #56 — R97: NaturalProseJoiner connector inject 제거 + 4 broken phrase fix + 4 variant pool (codex 9.55 GO)
require_relative '_helpers'

BUILD_NO = 56

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

# 3. whatsNew — R97 사용자 verbatim hotfix (R96 ship 직후 실기기 검증 reject)
ko_text = <<~KO.strip
  v1.0.0 Build ##{BUILD_NO} — R97 자연 prose hotfix

  사용자 verbatim (R96 1.0.0+55 실기기 검증 후):
  "말 자체가 어색한데 본인스타일대로 가서 사람들이 나를 기억한다? 그 흐름위에
  그게 장점이라고?? Codex한테 9.9 테스트 받은거 맞아???"

  Root cause: NaturalProseJoiner (R96 도입) 가 무관 sentence pool 에 connector
  강제 inject → "그래서/그 흐름 위에/덕분에/한편" 가 fake causation 생성.
  "정답이에요 → 그 흐름 위에 사람들이 기억해요" 는 진짜 인과 아님 = AI 같음.

  R97 fix:
  • NaturalProseJoiner connector inject 제거 (Option E)
    — join/append/polish 는 trim / 공백 / 마침표 / dedup 만
    — 종결 변형 (…에요. → …죠) 도 제거
  • 오늘 사주 총평 sentence 5 → 3~4 개로 감축
  • 4 broken phrase 직접 fix:
    — "잠잠하다" → "오늘은 자리 관련 얘기가 비교적 잠잠해요"
    — "비교·경쟁 신호" → "괜히 비교가 신경 쓰일 수 있는 날"
    — "수입·약속 안정감" → "수입이나 약속이 안정적으로 자리 잡는 날"
    — "새 일 떠맡기에" → "새 일을 떠맡기엔 어울리지 않는 날"
  • 반복감 해소 — 4 variant pool 추가:
    — branch neutral 5-pool (10 sample 중복 7 → 3)
    — geopjae 비교 3-pool (5 → 2)
    — mixedDay moodHook 3-pool (5 → 3)
    — mixedDay opening seed FNV-1a + 2단 avalanche (3 bucket → 4 bucket)

  품질: codex round 3 = 9.55/10 GO (round 1 6.5 → round 2 9.2 → round 3 9.55) /
  flutter analyze 0 / flutter test 868 PASS / R71/R77/R78/R82~R86 baseline 모두 보존.

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build ##{BUILD_NO} — R97 natural-prose hotfix

  User verbatim (after on-device check of R96 1.0.0+55):
  "The wording itself is awkward — 'Goes their own style, so people remember me'?
  'On that flow, that's the strength'?? You sure codex gave that a 9.9?"

  Root cause: the NaturalProseJoiner shipped in R96 was force-injecting Korean
  connectors ("그래서 / 그 흐름 위에 / 덕분에 / 한편") into unrelated sentence
  pools, fabricating fake causation. "It's the right answer → on that flow, people
  remember you" is not real causation — it reads like AI.

  R97 fix:
  • Removed connector injection from NaturalProseJoiner (Option E)
    — join/append/polish now only trim / dedup / period-normalise
    — also removed sentence-ending variation (…에요. → …죠)
  • Daily total-summary cut from 5 → 3~4 sentences
  • 4 broken phrases fixed verbatim:
    — "잠잠하다" → "오늘은 자리 관련 얘기가 비교적 잠잠해요"
    — "비교·경쟁 신호" → "괜히 비교가 신경 쓰일 수 있는 날"
    — "수입·약속 안정감" → "수입이나 약속이 안정적으로 자리 잡는 날"
    — "새 일 떠맡기에" → "새 일을 떠맡기엔 어울리지 않는 날"
  • Repetition relief — 4 variant pools added:
    — branch-neutral 5-pool (dupes 7/10 → 3/10)
    — geopjae comparison 3-pool (5 → 2)
    — mixedDay moodHook 3-pool (5 → 3)
    — mixedDay opening seeded by FNV-1a + 2-stage avalanche (3 bucket → 4 bucket)

  Quality: codex round 3 = 9.55/10 GO (round 1 6.5 → round 2 9.2 → round 3 9.55) /
  flutter analyze 0 / flutter test 868 PASS / R71/R77/R78/R82~R86 all preserved.

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
