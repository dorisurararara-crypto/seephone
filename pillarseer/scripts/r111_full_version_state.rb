#!/usr/bin/env ruby
require_relative '_helpers'

VERSION_ID = '2084f5bc-9577-427d-b6d7-0420cb750b31'

# 1. 전체 detail
puts "=== Version ==="
c, b = api(:get, "/v1/appStoreVersions/#{VERSION_ID}?include=build,ageRatingDeclaration,appStoreReviewDetail,appStoreVersionLocalizations,appStoreVersionPhasedRelease,appStoreVersionExperimentsV2")
parsed = JSON.parse(b)
puts JSON.pretty_generate(parsed['data']['attributes'])
puts "\n--- Relationships ---"
parsed['data']['relationships'].each do |k, v|
  d = v['data']
  if d.is_a?(Hash)
    puts "  #{k}: id=#{d['id']}"
  elsif d.is_a?(Array)
    puts "  #{k}: #{d.size} items"
  end
end

# 2. Build relationship 확인
puts "\n=== Current Build ==="
c, b = api(:get, "/v1/appStoreVersions/#{VERSION_ID}/build")
puts b[0..500]

# 3. Screenshot sets 상태
puts "\n=== Screenshot sets (ko) ==="
c, b = api(:get, "/v1/appStoreVersionLocalizations/7b4bd70c-1ee7-4773-bdb5-eaa36f9705c1/appScreenshotSets")
parsed = JSON.parse(b)
puts "  count=#{parsed['data']&.size || 0}"
parsed['data']&.each do |ss|
  puts "    set id=#{ss['id']}  type=#{ss['attributes']['screenshotDisplayType']}"
end

# 4. appInfo state
puts "\n=== appInfo ==="
c, b = api(:get, "/v1/apps/#{APP_ID}/appInfos")
JSON.parse(b)['data'].each do |inf|
  a = inf['attributes']
  puts "  id=#{inf['id']}  state=#{a['appStoreState']}  createdDate=#{a['createdDate']}"
end
