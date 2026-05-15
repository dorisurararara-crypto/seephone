#!/usr/bin/env ruby
# Build #41 — R84 codex 작업 (셀럽 DB 글로벌 한류 확장 + 십신/자미 crossmatch 리파인)
# 760 test PASS / 5행 골든 + R69 lock + R71~R83 시그니처 보존
require_relative '_helpers'

# 1. Build #41 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=41&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #41 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b41_id = b['id']
state = b['attributes']['processingState']
puts "[Build #41 id=#{b41_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b41_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R84 (≤500자 mandate)
ko_text = <<~KO.strip
  v1.0.0 Build #41 — R84 codex 사이클.

  셀럽 DB 글로벌 한류 대폭 확장:
  • K-POP 멤버 + 글로벌 한류 배우·가수 추가
  • 출생 시간 미상 라벨 (R83 신뢰도 정책 보존)

  카피 리파인:
  • 십신 페르소나 본문 어색 어휘 일소
  • 자미두수 궁합 풀이 자연스러운 한국어 톤
  • 6각 radar 색 변별력 미세 조정

  엔진 보강:
  • 사주 context 필드 추가 → "오늘" 탭 풀이 정확도 ↑
  • home / today 화면 wire 강화

  l10n:
  • 한국어 + 영어 신규 카피 동기화

  품질:
  • 760 test PASS (R84 신규 회귀 가드 2)
  • 5행 골든 1995-10-27 男 17시 16/21/17/41/4 보존
  • R69 lock + R71~R83 시그니처 모두 보존

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #41 — R84 codex cycle.

  Celebrity DB global Hallyu expansion:
  • K-POP members + global Korean wave actors/singers added
  • Unknown birth-time labels (R83 trust policy preserved)

  Copy refinement:
  • Ten-gods persona awkward wording cleaned
  • Ziwei (purple-star) compatibility copy more natural Korean tone
  • Six-axis radar color discrimination fine-tuned

  Engine:
  • Saju context fields added → Today tab accuracy ↑
  • Home / today screen wire strengthened

  Locale:
  • Korean + English new copy synced

  Quality:
  • 760 tests PASS (R84 2 new regression guards)
  • Five-element golden 1995-10-27 male 17h 16/21/17/41/4 preserved
  • R69 lock + R71~R83 signatures all preserved

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
                             relationships: {build: {data: {type: 'builds', id: b41_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b41_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b41_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
