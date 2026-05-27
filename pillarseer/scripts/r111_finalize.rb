#!/usr/bin/env ruby
# R111 — Build 77 attach + whatsNew + reviewSubmission 한 번에
# 사용법: ruby scripts/r111_finalize.rb  (build 77 이 VALID 인 상태 가정)
require_relative '_helpers'

BUILD_NO = 77
VERSION_ID = '2084f5bc-9577-427d-b6d7-0420cb750b31'
LOC_EN = 'c5d2f6cc-7c45-4e9b-bb94-e4a96f086b80'
LOC_KO = '7b4bd70c-1ee7-4773-bdb5-eaa36f9705c1'

# 1. Build id 확인
puts "▶︎ Build ##{BUILD_NO} 조회"
c, b = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=#{BUILD_NO}&limit=1")
data = JSON.parse(b)['data']
if data.empty?
  puts "  ❌ Build ##{BUILD_NO} 미존재. altool upload 부터 진행."
  exit 1
end
b_id = data.first['id']
state = data.first['attributes']['processingState']
puts "  id=#{b_id}  state=#{state}"
unless state == 'VALID'
  puts "  ⚠️  VALID 아님. 처리 끝나고 재실행."
  exit 1
end

# 2. Version 의 build relationship attach
puts "▶︎ AppStoreVersion 에 build attach"
c, b = api(:patch, "/v1/appStoreVersions/#{VERSION_ID}/relationships/build", {
  data: { type: 'builds', id: b_id }
})
case c.to_i
when 204 then puts "  ✅ attached"
when 200 then puts "  ✅ attached"
else
  puts "  ❌ HTTP #{c} body=#{b[0..400]}"
  exit 1
end

# 3. whatsNew patch (build attach 후 가능)
en_whatsnew = File.read('/tmp/r111_whatsnew_en.txt')
ko_whatsnew = File.read('/tmp/r111_whatsnew_ko.txt')

[[LOC_EN, 'en-US', en_whatsnew], [LOC_KO, 'ko', ko_whatsnew]].each do |id, label, text|
  c, b = api(:patch, "/v1/appStoreVersionLocalizations/#{id}", {
    data: { type: 'appStoreVersionLocalizations', id: id, attributes: { whatsNew: text } }
  })
  ok = c.to_i == 200
  puts "▶︎ whatsNew [#{label}] HTTP #{c}  #{ok ? '✅' : '❌'}"
  puts "  body=#{b[0..300]}" unless ok
end

# 4. ReviewSubmission 생성 + IAP + submit (submit_for_review.rb 패턴)
IAP_ID = '6772283210'

puts "\n▶︎ ReviewSubmission 생성"
c, b = api(:post, '/v1/reviewSubmissions', {
  data: {
    type: 'reviewSubmissions',
    attributes: { platform: 'IOS' },
    relationships: { app: { data: { type: 'apps', id: APP_ID } } }
  }
})
raise "submission create FAIL #{c}: #{b[0..400]}" unless c.to_i == 201
sub_id = JSON.parse(b)['data']['id']
puts "  id=#{sub_id}"

# Add app version
c, b = api(:post, '/v1/reviewSubmissionItems', {
  data: {
    type: 'reviewSubmissionItems',
    relationships: {
      reviewSubmission: { data: { type: 'reviewSubmissions', id: sub_id } },
      appStoreVersion: { data: { type: 'appStoreVersions', id: VERSION_ID } }
    }
  }
})
puts "  appStoreVersion item HTTP #{c}"

# Add IAP
c, b = api(:post, '/v1/reviewSubmissionItems', {
  data: {
    type: 'reviewSubmissionItems',
    relationships: {
      reviewSubmission: { data: { type: 'reviewSubmissions', id: sub_id } },
      inAppPurchaseV2: { data: { type: 'inAppPurchases', id: IAP_ID } }
    }
  }
})
puts "  IAP item HTTP #{c}  (#{c.to_i == 201 ? 'new' : (c.to_i == 409 ? 'already bundled' : 'check')})"

# Submit
c, b = api(:patch, "/v1/reviewSubmissions/#{sub_id}", {
  data: { type: 'reviewSubmissions', id: sub_id, attributes: { submitted: true } }
})
if c.to_i == 200
  s = JSON.parse(b)['data']['attributes']['state']
  puts "\n🎉 제출 완료. state=#{s}"
  puts "Apple 응답 24~48시간 예상."
else
  puts "\n❌ submit FAIL HTTP #{c}: #{b[0..400]}"
end
