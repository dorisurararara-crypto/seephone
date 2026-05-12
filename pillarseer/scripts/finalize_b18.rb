require_relative '_helpers'
require 'net/http'
require 'json'

# 1. Build #18 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=18&limit=1")
b18 = JSON.parse(body)['data'].first['id']
puts "Build #18 id: #{b18}"

# 2. whatsNew (실기 버그 fix 안내)
ko = <<~KO.strip
v1.0.0 Build #18 — 실기 사용자 피드백 반영 한·영 분리 + DatePicker 개선

이번 빌드 핵심 수정
• 한국어 모드에서 영어 문구 노출 제거 (오늘 한 줄 한국어, 일주 부제 "금 토끼" 한국어)
• 60일주 본문에서 "Metal Rabbit" 등 영문 자동 sanitize
• "가을" 라벨 "출생 계절(가을)" 명시 — 오늘 계절이 아님
• DatePicker 텍스트 직접 입력 (1996-05-16 같이 타이핑 가능) + 캘린더 fallback
• Home 카드 순서 정리

기존 핵심 (Build #17까지)
• KASI 만세력 + 진태양시 + 음력 자동 변환
• 30초 요약 + 5행 + 십신 + Life Themes + 大運/歲運
• Reports 4종 (궁합·토정·택일·해몽)
• Discover K-pop 셀럽 20명 비교 모달
• 매일 8시 알림 + Streak

테스트: 입력 → 결과 → 홈 → 리포트 → 탐색 → 프로필 전체 flow
KO

en = <<~EN.strip
v1.0.0 Build #18 - real-device feedback fixes + DatePicker UX

This build:
- Korean-mode: removed leaked English phrases (daily one-line, pillar subtitle)
- Auto-sanitize "Metal Rabbit" etc from Korean body text
- "Autumn" label clarified as "your birth season (autumn)" - not today's date
- DatePicker: direct text input (1996-05-16) + calendar fallback
- Home card order tidied

Existing (since Build #17):
- KASI manseryeok + true solar time + lunar auto conversion
- 30-second summary + 5 Elements + Ten Gods + Life Themes + 10-Year + This Year
- 4 Reports (Compatibility, Tojeong, Date Picking, Dream)
- Discover with 20 K-pop celebrities compare modal
- Daily 8 AM push + Streak

Test path: input -> result -> home -> reports -> discover -> profile
EN

# 3. locales 조회
code, body = api(:get, "/v1/builds/#{b18}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
locs.each do |l|
  loc_id = l['id']
  locale = l['attributes']['locale']
  text = locale == 'ko' ? ko : en
  3.times do |i|
    code, body = api(:patch, "/v1/betaBuildLocalizations/#{loc_id}",
                     {data: {type: 'betaBuildLocalizations', id: loc_id,
                             attributes: {whatsNew: text}}})
    puts "PATCH #{locale} attempt #{i+1}: HTTP #{code} (#{text.length} chars)"
    break if code.to_i < 400
    sleep 2
  end
end

# 4. 그룹 swap: remove v17, add v18
def del_build(b_id)
  u = URI("https://api.appstoreconnect.apple.com/v1/builds/#{b_id}/relationships/betaGroups")
  req = Net::HTTP::Delete.new(u)
  req['Authorization'] = "Bearer #{jwt_token}"
  req['Content-Type'] = 'application/json'
  req.body = {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]}.to_json
  h = Net::HTTP.new(u.host, u.port); h.use_ssl = true
  res = h.request(req)
  [res.code, res.body]
end

b17 = '6df80630-26e5-48c4-833e-8fcf55f6124e'
code, body = api(:post, "/v1/builds/#{b18}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "\nadd v18: HTTP #{code}"
code, body = del_build(b17)
puts "remove v17: HTTP #{code}"

# 5. Beta review 제출
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b18}}}}})
puts "submit v18: HTTP #{code}"

# 6. 잔여 확인
sleep 1
code, body = api(:get, "/v1/betaGroups/#{EXTERNAL_GROUP_ID}/builds")
puts "\nGroup builds:"
JSON.parse(body)['data'].each do |b|
  code2, body2 = api(:get, "/v1/builds/#{b['id']}")
  attrs = JSON.parse(body2)['data']['attributes']
  puts "  v#{attrs['version']}"
end
