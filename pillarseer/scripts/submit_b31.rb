#!/usr/bin/env ruby
# Build #31 — Round 7~14 codex 감독 다단계 fix.
require_relative '_helpers'

# 1. Build #31 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=31&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #31 not found yet.'
  exit 1
end
b31_id = b['id']
state = b['attributes']['processingState']
puts "[Build #31 id=#{b31_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b31_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew
ko_text = <<~KO.strip
  v1.0.2 Build #31 — codex 다단계 감독 (Round 7~14) UX 대규모 개선.

  콘텐츠 개선
  • 한자 sub-demote — 한국어 메인 + 한자 작은 sub-accent
  • 명리 jargon 풀이 — 어려운 용어 옆에 한 줄 친근 설명
  • Result hero '답 먼저' — '깊은 물 같은 사람입니다' 5초 이해
  • Home 점수 의미 보강 — 상태명 + 색 + 행동 hint + 12시진 best time
  • Home 신규 _TodayDeepReading — 사주 깊이 오늘 풀이 (mood/body/actions/caution)
  • 영문 라벨 → 한국어 메인 (모든 화면 + AppBar title)
  • Reports 7 카드 → 추천 1 + 가볍게 2 + 깊게 4 그룹화

  K-POP 강화
  • TopMatchCard — '내 케미픽: {스타} · {점수}점' 캡쳐용 한 줄 밈
  • 공유 button (SharePlus + Clipboard fallback)
  • 필터 default 'idol' (배우/운동선수 제거)
  • 五合·六合·三合·沖·刑 종합 점수

  Nav 7개 P0/P1 fix
  • bottom_nav sub-route swap (matchedLocation)
  • settings back canPop fallback
  • /settings protected route
  • discover AppBar back button + empty state
  • Home 12시간 흐름 bottom sheet 닫기 IconButton
  • settings _LinkRow ellipsis overflow
  • settings _LanguageRow color+decoration crash fix

  버그 fix
  • 6 sub-report back button — Navigator.pop() → context.go('/reports') (검은화면 해소)
  • Home 점수 Row overflow → 점수 + 풀이 분리
  • 궁합 화면 데모 hint (입력 전 빈 화면 해소)

  검증
  • flutter analyze: clean
  • flutter test: 288/288 통과
  • codex 8 라운드 audit: 3.8 → 6.7 → 7.6 → 8.1 (점진 상승)

  Notes: 프랑스/MZ 사용자용 jargon gloss 등 추가 콘텐츠 작업 진행 예정.
KO

en_text = <<~EN.strip
  v1.0.2 Build #31 — codex multi-stage supervisor rounds 7-14, major UX overhaul.

  Content
  • Hanja sub-demoted to small accent; Korean as main label everywhere
  • Myeongli jargon → in-place plain-language gloss
  • Result hero "answer first" — single line identity statement
  • Home score with status name + color + action hint + best 2-hour window
  • Home new _TodayDeepReading — saju-based deep daily reading
  • English section labels → Korean primary + small English sub
  • Reports 7 cards → recommend 1 / quick 2 / deep 4 grouping

  K-POP
  • TopMatchCard — "My pick: {star} · {score}" share-ready single line
  • Share button (SharePlus + Clipboard fallback)
  • Default filter "idol" (actors/athletes removed from initial view)
  • 5合·6合·3合·沖·刑 comprehensive score

  Nav 7 P0/P1 fixes
  • bottom_nav sub-route swap via matchedLocation
  • Settings back canPop fallback
  • /settings added to protected routes
  • Discover AppBar back + empty state
  • Home 12-hour flow bottom sheet explicit close IconButton
  • Settings _LinkRow ellipsis overflow
  • Settings _LanguageRow color+decoration crash fix

  Bug fixes
  • 6 sub-report back buttons (was Navigator.pop, now context.go('/reports'))
  • Home score Row overflow → score and explanation split
  • Compatibility screen demo hint (replaces empty-form first view)

  Verification
  • flutter analyze: clean
  • flutter test: 288/288 pass
  • codex 8-round audit: 3.8 → 6.7 → 7.6 → 8.1 progressive climb

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
                             relationships: {build: {data: {type: 'builds', id: b31_id}}}}})
    puts "  POST #{locale}: HTTP #{code}"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b31_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b31_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
