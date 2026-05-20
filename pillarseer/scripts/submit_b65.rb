#!/usr/bin/env ruby
# Build #65 — R104: 전생 story arc 재설계(기승전결) + 다시뽑기 제거 + picker hide
#   + pre-existing 8건 fix + 조사/오염 토큰 복원
require_relative '_helpers'

BUILD_NO = 65

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

# 3. whatsNew — R104
ko_text = <<~KO.strip
  - 전생 이야기를 기승전결이 또렷한 한 편의 완결 시나리오로 새로 썼어요. 시대·신분·사건이 하나로 이어지도록 64편을 새로 작성했어요.
  - 최애를 선택하면 목록이 접히고 전생 이야기가 바로 나오도록 화면을 정리했어요. ‘다시 뽑기’ 버튼은 없앴어요.
  - 평생사주 본문의 어색한 표현·반복·오타를 곳곳에서 자연스럽게 다듬었어요.
KO

en_text = <<~EN.strip
  - Rewrote every past-life story as one complete narrative with a clear setup, build-up, twist, and ending — 64 fresh scenarios.
  - Streamlined the screen so picking your bias collapses the list and shows the story right away; removed the re-roll button.
  - Polished awkward phrasing, repetition, and typos throughout the life readings.
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
