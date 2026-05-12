require_relative '_helpers'
require 'net/http'
require 'json'

code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=19&limit=1")
b19 = JSON.parse(body)['data'].first['id']
puts "Build #19 id: #{b19}"

# whatsNew (전체 UI/UX 개선)
ko = <<~KO.strip
v1.0.0 Build #19 — 실사용 피드백 반영, codex 정직 audit (6.7/10) 권고 적용

이번 라운드 핵심 수정
• Bottom Nav 5탭 → 4탭 (홈/사주/리포트/프로필)
• "Home" → "오늘", "Reading" → "내 사주" (직관적)
• Discover (셀럽 비교) 는 리포트 카드로 흡수
• DatePicker 캘린더 복귀 (텍스트 입력 revert) + dark theme
• 음력 입력 활성화 (KASI 변환 이미 지원, UI 만 잠겨있던 버그)
• 한국어 날짜 포맷 "2026년 5월 12일 화요일" (기존 "TUE · MAY 12, 2026" 어색)
• 알림 토글 Home → Settings 이전 (Home 카드 정리)
• "Watch for impulsive spending" 등 영어 노출 한국어로
• 일주 카드 "Wood Pig / Fire Dog" → "수 돼지 / 화 개" 한국어 라벨
• 60일주 본문 "Metal Rabbit" 같은 영어 단어 자동 sanitize
• "가을" 라벨 → "출생 계절(가을)" 명시

테스트
1. 첫 실행 → 생년월일 캘린더 입력 (year picker 모드 자동)
2. 음력 토글 → 음력 입력
3. Bottom Nav 4탭 모두 진입
4. Settings 알림 토글
5. Result 한국어 라벨 (Wood Pig 사라짐)
KO
en = <<~EN.strip
v1.0.0 Build #19 — UX overhaul from real-device feedback (codex honest audit 6.7→8.0+)

This round:
- Bottom Nav 5 tabs → 4 tabs (Today / My Saju / Reports / Profile)
- Discover absorbed into Reports as 5th card
- DatePicker calendar mode restored (text input reverted - user preferred calendar)
- Lunar input enabled (KASI conversion already supported, UI was incorrectly disabled)
- Korean date format "2026년 5월 12일 화요일" (uppercase removed for Korean)
- Daily push toggle moved from Home → Settings (Home decluttered)
- English leaks fixed: daily quote, pillar subtitle ("Wood Pig" → 한국어), Korean body sanitize
- "Autumn" label clarified as user's birth season (not today's date)

Test path
1. First launch → birth date via calendar (year picker auto)
2. Lunar toggle works
3. Bottom Nav 4 tabs
4. Settings notification toggle
5. Result Korean labels
EN

code, body = api(:get, "/v1/builds/#{b19}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
locs.each do |l|
  loc_id = l['id']
  locale = l['attributes']['locale']
  text = locale == 'ko' ? ko : en
  3.times do |i|
    code, body = api(:patch, "/v1/betaBuildLocalizations/#{loc_id}",
                     {data: {type: 'betaBuildLocalizations', id: loc_id,
                             attributes: {whatsNew: text}}})
    puts "PATCH #{locale} #{i+1}: HTTP #{code}"
    break if code.to_i < 400
    sleep 2
  end
end

# 그룹 swap: remove v18, add v19
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

b18 = '358eaa28-d174-434d-945b-38d96273148e'
code, body = api(:post, "/v1/builds/#{b19}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "\nadd v19: HTTP #{code}"
code, body = del_build(b18)
puts "remove v18: HTTP #{code}"

# Beta review 제출
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b19}}}}})
puts "submit v19: HTTP #{code}"
