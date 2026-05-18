#!/usr/bin/env ruby
# Build #53 — R92: entry 단위 codex 9.9+ 목표 quality 정제 4 round
require_relative '_helpers'

BUILD_NO = 53

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

# 3. whatsNew — R94 사용자 4 mandate 반영
ko_text = <<~KO.strip
  v1.0.0 Build ##{BUILD_NO} — R94 실기기 4 mandate

  R93 1.0.0+52 실기기 검증 후 받은 사용자 verbatim 4 mandate:

  1. 케미 같은 일주 셀럽 7명 동일 본문·92점 → 셀럽별 차별화
     • 戊戌 일주 (아이린/민니/여상/정한/소희/나띠/벨) 모두 92점 + 본문 동일했음
     • 셀럽 birth year stem vs 사용자 일간 5합/극/같음 → ±2~5 점 변별
     • 본문 4번째 paragraph 추가 — 셀럽 blurbKo + 두 사람 시그니처 케미 한 줄

  2. 전체/남자/여자 gender 필터 chip 추가
     • "내 기준 / 전체 / 남자 / 여자" 4 chip row
     • 기존 자동 reverse 필터 (R82 sprint 9) default 유지 + manual override 가능

  3. 궁합 답변 ×3 더 길게 + 연애·결혼·자녀 새 섹션
     • TEXTURE / ATTRACTS / FRICTION 모두 1 paragraph 200자 → 2 paragraph 600~900자
     • LOVE & MARRIAGE 새 섹션 (연애/결혼/자녀 3 sub anchor 별 분기)
     • ACTIONS 3개 → 5~7개 + 각 100자 자세 설명
     • 본문 1000~2000자 → 3000~5000자

  4. 케미 검색 한글 IME 조합 fix
     • "ㅋ 만 치니까 검색이 되버리는" 버그 → 280ms debounce
     • IME 조합 중에는 필터 발화 안 되어 커서 유지

  품질: flutter analyze 0 / flutter test 854/854 PASS / 모든 baseline 보존.

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build ##{BUILD_NO} — R94 four post-device user-mandate updates

  1. K-POP chemistry — same-pillar celebs now differ
     • 戊戌 day pillar (7 celebs) all showed identical 92 + identical body → fixed
     • Birth year stem vs day master 5-union/overcome/same → ±2~5 score variance
     • 4th paragraph adds celeb blurb + signature chemistry line

  2. Gender filter chip (default / all / male / female)
     • 4 chip row override; default = reverse-gender (R82 sprint 9 preserved)

  3. Compatibility body ×3 longer + new LOVE/MARRIAGE/CHILDREN section
     • TEXTURE / ATTRACTS / FRICTION all 200 → 600~900 char
     • New LOVE & MARRIAGE section with 3 sub-anchors
     • ACTIONS 3 → 5~7 with rich descriptions
     • Body 1000~2000 → 3000~5000 char

  4. Search Hangul IME composition fix
     • "single ㅋ triggers search" bug → 280ms debounce; cursor preserved during composition

  Quality: flutter analyze 0 / test 854/854 PASS.

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
