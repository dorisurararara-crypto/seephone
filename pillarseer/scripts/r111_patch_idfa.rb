#!/usr/bin/env ruby
# R111 — version 의 usesIdfa null → false 로 PATCH (fastlane #20065 silent blocker)
require_relative '_helpers'

VERSION_ID = '2084f5bc-9577-427d-b6d7-0420cb750b31'

# 1. 현재 attrs 확인
c, b = api(:get, "/v1/appStoreVersions/#{VERSION_ID}")
attrs = JSON.parse(b)['data']['attributes']
puts "현재 attrs:"
puts "  usesIdfa: #{attrs['usesIdfa'].inspect}"
puts "  downloadable: #{attrs['downloadable'].inspect}"

# 2. usesIdfa: false PATCH (광고/추적 없음)
c, b = api(:patch, "/v1/appStoreVersions/#{VERSION_ID}", {
  data: {
    type: 'appStoreVersions',
    id: VERSION_ID,
    attributes: { usesIdfa: false }
  }
})
puts "\nPATCH usesIdfa=false → HTTP #{c}"
puts b[0..400]

# 3. appInfo 의 contentRightsDeclaration 도 확인 & set
INFO_ID = '0145d57b-6999-4207-a790-a2e6f751a00c'
c, b = api(:get, "/v1/appInfos/#{INFO_ID}")
attrs = JSON.parse(b)['data']['attributes']
puts "\nappInfo attrs:"
puts "  privacyPolicyText: #{attrs['privacyPolicyText']}"
puts "  privacyPolicyUrl: #{attrs['privacyPolicyUrl']}"
puts attrs.to_json[0..400]

# App 자체의 contentRightsDeclaration
c, b = api(:get, "/v1/apps/#{APP_ID}")
attrs = JSON.parse(b)['data']['attributes']
puts "\napp attrs:"
puts "  contentRightsDeclaration: #{attrs['contentRightsDeclaration']}"

if attrs['contentRightsDeclaration'].nil?
  puts "\n▶︎ contentRightsDeclaration PATCH (third party content 없음 → DOES_NOT_USE_THIRD_PARTY_CONTENT)"
  c, b = api(:patch, "/v1/apps/#{APP_ID}", {
    data: {
      type: 'apps',
      id: APP_ID,
      attributes: { contentRightsDeclaration: 'DOES_NOT_USE_THIRD_PARTY_CONTENT' }
    }
  })
  puts "HTTP #{c}: #{b[0..300]}"
end
