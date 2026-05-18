#!/usr/bin/env ruby
# Build #55 — R96: 사용자 mandate 자연 흐름 prose + NaturalProseJoiner 9 service wire (codex 9.9 SHIP)
require_relative '_helpers'

BUILD_NO = 55

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

# 3. whatsNew — R96 사용자 mandate 자연 흐름 prose + 9 service wire
ko_text = <<~KO.strip
  v1.0.0 Build ##{BUILD_NO} — R96 사용자 mandate 자연 흐름 prose

  사용자 verbatim: "오늘의 한줄에 말이 이어져서 나와야하는데 해요로 계속 끝나니까
  툭툭 끊기는 느낌이야 … 정답이에요. 장점을 기억해요. 갑자기 배움이 자리잡는
  흐름이에요 이런식이니까 ai같아 내 앱에서 이런 부분들을 전부 찾아서 수정해줘."

  Root cause: 각 facet 문장이 독립 생성 후 parts.join(' ') 단순 결합 → 연결사 0 → AI 같음.

  추가:
  • 신규 NaturalProseJoiner utility — 4 문장+ 이상이면 connector 자동 inject
    (그래서 / 그 흐름 위에 / 덕분에 / 한편 / 다만 / 동시에 / 거기에 /
     그 분위기 그대로 / 한 발 더 가면 / 그러니까)
  • 종결 변형 (…에요. → …죠 / …네요), 이에요. → 예요. 회귀 가드
  • deterministic — 같은 사주 / 같은 날 = 같은 출력

  Wire (9 service):
  • P0 오늘 탭 — home_screen / today_deep_service / today_event_service
  • P1 인생 — life_paragraph_service / life_overview_service /
    self_conclusion_service / additional_life_service
  • P2 신년 — personalization_engine / new_year_2026_screen
    (_AnnualSummary 7 문단 + _MonthlyFlow + _TwelveAreas)

  품질: codex evaluator 9.9/10 SHIP (P0=10 / P1=10 / P2=9.9 / utility=10) /
  flutter analyze 0 / flutter test 863 PASS / R91 fragment ≥200 + R77 한자 jargon +
  R89 B1~B7 + R78 sprint 7 격국 변별력 + R93 _TwelveAreas 12 area 모두 보존.

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build ##{BUILD_NO} — R96 natural-flow prose connectors

  User verbatim: "The daily one-liner should flow as connected sentences, but every
  sentence ends in '-에요' (-eyo) and feels choppy. 'It's the right answer. Remember
  your strength. Suddenly your learning settles into flow.' — that reads like AI.
  Find every such spot in my app and fix it."

  Root cause: each facet sentence was generated independently then concatenated
  with parts.join(' ') — zero connective tissue → reads like AI.

  Added:
  • New NaturalProseJoiner utility — 4+ sentences auto-inject Korean connectors
    (geuraeseo / geu heureum wie / deokbune / hanpyeon / daman / dongsiae /
     geogie / geu bunwigi geudaero / han bal deo gamyeon / geureonikka)
  • Ending variation (…에요. → …죠 / …네요), guard against 이에요. → 예요. regression
  • Deterministic — same chart / same day = same output

  Wired into 9 services:
  • P0 Today tab — home_screen / today_deep_service / today_event_service
  • P1 Life — life_paragraph_service / life_overview_service /
    self_conclusion_service / additional_life_service
  • P2 New Year — personalization_engine / new_year_2026_screen
    (_AnnualSummary 7 paragraphs + _MonthlyFlow + _TwelveAreas)

  Quality: codex evaluator 9.9/10 SHIP (P0=10 / P1=10 / P2=9.9 / utility=10) /
  flutter analyze 0 / test 863 PASS / R91 fragment ≥200, R77 hanja-jargon scrub,
  R89 B1~B7, R78 sprint 7 격국 differentiation, R93 _TwelveAreas 12-area all preserved.

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
