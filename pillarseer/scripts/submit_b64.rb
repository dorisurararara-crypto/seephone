#!/usr/bin/env ruby
# Build #64 — R103 sprint 1-5: 전생 본문 재설계 + 입력 focus chain + 곡 73건 정정 + collision hotfix
require_relative '_helpers'

BUILD_NO = 64

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

# 3. whatsNew — R103 codex head mandate verbatim
ko_text = <<~KO.strip
  - 전생 이야기 본문을 10~14문장 구조로 재설계하고, 사건 전개와 이번 생 연결감을 강화했어요.
  - 전생 결과의 반복 표현을 줄이고, 더 다양한 역할·시대·상황 조합이 나오도록 풀을 확장했어요.
  - 사주 입력 화면에서 시간 입력 후 지역 입력으로 자연스럽게 넘어가고, 지역 입력 완료 시 키보드가 닫히도록 개선했어요.
  - 전생 메뉴의 셀럽 목록 스크롤이 더 자연스럽게 동작하도록 수정했어요.
  - 디지털 처방전 곡 데이터 73건을 정정했어요. BABYMONSTER Pharita, STAYC J 등 일부 곡명이 더 정확해졌어요.
KO

en_text = <<~EN.strip
  - Redesigned past-life stories into richer 10-14 sentence narratives with stronger event flow and present-life callbacks.
  - Expanded the past-life content pool to reduce repetition across roles, eras, and story situations.
  - Improved the birth input flow so focus moves naturally from time to city, with the keyboard dismissing after city entry.
  - Fixed smoother scrolling behavior in the past-life celebrity picker.
  - Corrected 73 digital prescription song entries, including updates for BABYMONSTER Pharita and STAYC J.
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
