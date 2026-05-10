#!/usr/bin/env ruby
# protagonist 외부 베타 그룹 할당 + Beta App Review 제출
require_relative '_helpers'

# 1. 가장 최근 빌드 ID 조회
target_version = ARGV[0]
filter = target_version ? "&filter[version]=#{target_version}" : ''
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&sort=-version&limit=10#{filter}")
build = JSON.parse(body)['data'].first
unless build
  puts '빌드 없음'
  exit 1
end
build_id = build['id']
build_v = build['attributes']['version']
state = build['attributes']['processingState']
puts "[빌드 #{build_v} → state=#{state}, id=#{build_id}]"

if state != 'VALID'
  puts "⚠️  VALID 가 아님. processing 끝나고 다시 실행해줘."
  exit 0
end

# 2. 외부 그룹 할당 (멱등 — 이미 할당됐으면 OK)
puts "외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{build_id}/relationships/betaGroups",
                 { data: [{ type: 'betaGroups', id: EXTERNAL_GROUP_ID }] })
puts "  HTTP #{code}"

# 3. Beta App Review 제출 (멱등 — 이미 제출됐으면 409 정상)
puts "Beta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 { data: { type: 'betaAppReviewSubmissions',
                           relationships: { build: { data: { type: 'builds', id: build_id } } } } })
case code.to_i
when 201
  puts "✅ 제출 완료. 외부 그룹 ganzitester 첫 빌드는 24~48h 심사."
when 409
  puts "ℹ️  이미 제출됨 (멱등). 현재 상태 확인:"
  code2, body2 = api(:get, "/v1/builds/#{build_id}/betaAppReviewSubmission")
  s = JSON.parse(body2)['data']
  puts "    state=#{s['attributes']['betaReviewState']}" if s
else
  puts "FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
