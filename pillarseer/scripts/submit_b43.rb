#!/usr/bin/env ruby
# Build #43 — R86 sprint 1+2: 카피 위생 + 화면 정리 + _OracleHero 30 ment 해요체 재작성
# 775 test PASS / flutter analyze 0 issue / 5행 골든 + R69 lock + R71~R85 시그니처 보존
require_relative '_helpers'

# 1. Build #43 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=43&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #43 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b43_id = b['id']
state = b['attributes']['processingState']
puts "[Build #43 id=#{b43_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b43_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R86 sprint 1+2 (≤500자 mandate)
ko_text = <<~KO.strip
  v1.0.0 Build #43 — R86 카피 위생 + 화면 정리.

  말투 일소:
  • "오늘 너 = X" AI 등호 패턴 제거
  • 반말/존댓말 혼재 → 해요체 통일
  • "정인격" 등 격국 jargon 본문 노출 0 (의미만 평어로)
  • "금 토끼의 결" 명사화 표현 제거

  K-POP 궁합 개선:
  • 전체 화면 통합 스크롤 (이전: 아래 리스트만)
  • 이름·그룹 검색바 추가

  신년운세:
  • 절기별 12 카드 섹션 제거 (반복 카피 일소)

  품질:
  • 775 test PASS (R86 신규 회귀 가드 9)
  • flutter analyze 0 issue
  • 5행 골든 1995-10-27 男 17시 16/21/17/41/4 보존
  • R69 lock + R71~R85 시그니처 모두 보존

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #43 — R86 copy hygiene + screen cleanup.

  Tone cleanup:
  • Removed "Today you = X" Co-Star-style equals pattern
  • Mixed casual/polite Korean → unified polite (해요체)
  • Ten-gods jargon (정인격 등) no longer surfaced in body — meaning only
  • "Metal Rabbit's grain" nominalized phrase removed

  K-POP compatibility:
  • Whole screen now scrolls together (was: bottom list only)
  • Name / group search bar added

  New-year fortune:
  • 12 solar-term card section removed (repeated copy cleaned)

  Quality:
  • 775 tests PASS (9 new R86 regression guards)
  • flutter analyze 0 issue
  • Five-element golden 1995-10-27 male 17h 16/21/17/41/4 preserved
  • R69 lock + R71~R85 signatures all preserved

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
                             relationships: {build: {data: {type: 'builds', id: b43_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b43_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b43_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
