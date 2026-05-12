#!/usr/bin/env ruby
# Build #30 — Aesop Luxury redesign + 2026 신년운세 + K-POP 궁합.
# 1) whatsNew (ko + en-US) seed
# 2) 외부 그룹 ganzitester 할당
# 3) Beta App Review 제출
require_relative '_helpers'

# 1. Build #30 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=30&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #30 not found yet. Wait for ASC processing.'
  exit 1
end
b30_id = b['id']
state = b['attributes']['processingState']
puts "[Build #30 id=#{b30_id} state=#{state}]"

if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Re-run after processing completes."
  exit 0
end

# 2. localizations 자동 생성 후 조회 (Apple 가 빌드 처리 후 자동 생성).
code, body = api(:get, "/v1/builds/#{b30_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — Aesop Luxury 전면 재디자인 + 신규 2 기능.
ko_text = <<~KO.strip
  v1.0.1 Build #30 — Aesop Luxury 전면 재디자인 + 신규 기능 2종.

  디자인 — Aesop Luxury 톤
  • 베이지/taupe/ink 팔레트 (cosmic 다크 → 라이트 럭셔리)
  • 텍스트 위주 magazine editorial 레이아웃
  • emoji 전면 제거 → 한자 명패 + UPPERCASE letter-spacing 라벨
  • 카드 그림자 X, 그라데이션 X, 둥근 모서리 0-2px
  • Cormorant Garamond (라틴) + Noto Serif KR (한글) — 폰트 fallback 정합

  신규 기능
  • 2026 신년운세 (병오년) — KASI 12절 + 12달 흐름 + 12 영역
  • K-POP 스타 궁합 — 20+ 셀럽 정통 명리학 점수 (오행 상생 + 천간 五合 + 지지 六合·三合·沖·刑)

  명리학 정확도
  • 2026 KASI 12절 절입시각 KST source-of-truth (lib/services/jol_calendar_2026.dart)
  • 입춘 2/4 05:02, 경칩 3/5 22:58, 망종 6/6 00:48, ... 대설 12/7 11:52
  • test/new_year_2026_test.dart — 12 exact-table + 천체 ±20분 sanity (288/288 통과)
  • 丙년 五虎遁 月干 정확 매핑

  검증
  • flutter analyze: clean
  • flutter test: 288/288 통과
  • codex 6 라운드 audit: 7.2 → 8.4 → 9.2 → 9.7 → 9.8 → 9.9

  테스트 포인트
  1. Splash 命 한자 hero → Input underline TextField → Result
  2. Result hero 한자 일주 + 'A READING' 매거진 본문 + CHART ATTRIBUTES 2×2
  3. Home 72pt score + Four Areas 2×2 + 시간대 hairline grid
  4. Reports → 2026 신년운세 (NEW · 2026 chip)
  5. Reports → K-POP 스타 궁합 (NEW · K-POP chip)
  6. Discover 한자 dayPillar 명단 + Compatibility 다이얼로그
  7. Bottom nav 한자 glyph (日/柱/譜/我) + 1px underline

  이슈 dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.1 Build #30 — Full Aesop Luxury redesign + two new features.

  Design — Aesop Luxury
  • Cream/taupe/ink palette (dark cosmic → light luxury)
  • Text-first magazine editorial layout
  • Emojis removed → Hanja seals + UPPERCASE letter-spacing labels
  • No card shadows, no gradients, 0-2px corner radius
  • Cormorant Garamond (Latin) + Noto Serif KR (Korean) — coherent fallback

  New features
  • 2026 New Year Reading (Year of Bing Wu / Fire Horse) — KASI 12 jol + monthly flow + 12 areas
  • K-POP Star Compatibility — 20+ celebrities scored with 五合/六合/三合/沖/刑

  Myeongli accuracy
  • 2026 KASI 12-jol KST source-of-truth (jol_calendar_2026.dart)
  • Ipchun Feb 4 05:02, Gyeongchip Mar 5 22:58, Mangjong Jun 6 00:48, ... Daeseol Dec 7 11:52
  • test/new_year_2026_test.dart — 12 exact-table + astronomy ±20 min sanity
  • Bing-year 五虎遁 month-stem mapping correct

  Verification
  • flutter analyze: clean / flutter test: 288/288 passing
  • Codex 6-round audit: 7.2 → 8.4 → 9.2 → 9.7 → 9.8 → 9.9

  Test path: splash → input → result → home → reports (2026 + K-POP) → discover → settings.

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
    # 없으면 POST 로 생성
    code, body = api(:post, '/v1/betaBuildLocalizations',
                     {data: {type: 'betaBuildLocalizations',
                             attributes: {locale: locale, whatsNew: text},
                             relationships: {build: {data: {type: 'builds', id: b30_id}}}}})
    puts "  POST #{locale}: HTTP #{code}"
  end
end

# 4. 외부 그룹 ganzitester 할당
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b30_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review 제출 — Apple 이 whatsNew 를 internalize 할 시간 잠시 대기
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b30_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료. ganzitester 외부 베타 24~48h 심사."
when 409
  puts "  ℹ️  이미 제출됨 (멱등). 현재 상태:"
  code2, body2 = api(:get, "/v1/builds/#{b30_id}/betaAppReviewSubmission")
  s = JSON.parse(body2)['data']
  puts "    state=#{s['attributes']['betaReviewState']}" if s
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
