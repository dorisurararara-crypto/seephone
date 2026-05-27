#!/usr/bin/env ruby
require_relative '_helpers'

VERSION_ID = '2084f5bc-9577-427d-b6d7-0420cb750b31'

# 1. 모든 reviewSubmissions (app filter)
c, b = api(:get, "/v1/reviewSubmissions?filter%5Bapp%5D=#{APP_ID}&limit=20")
puts "HTTP #{c}"
JSON.parse(b)['data'].each do |s|
  a = s['attributes']
  puts "  id=#{s['id']}  state=#{a['state']}  platform=#{a['platform']}  submittedDate=#{a['submittedDate']}"
end

# 2. 최신 (방금 만든) submission 의 items 확인
LATEST = '1a25ba1c-163c-40f0-a2fb-063b64d99bf1'
puts "\n=== Latest submission items ==="
c, b = api(:get, "/v1/reviewSubmissions/#{LATEST}/items")
puts "HTTP #{c}"
puts b[0..1500]

# 3. Version 의 state
puts "\n=== Version state ==="
c, b = api(:get, "/v1/appStoreVersions/#{VERSION_ID}")
attrs = JSON.parse(b)['data']['attributes']
puts "  appStoreState=#{attrs['appStoreState']}  appVersionState=#{attrs['appVersionState']}"
