#!/usr/bin/env ruby
# R111 — 거절 후 현재 ASC version 상태 확인 + 다음 path 진단
require_relative '_helpers'

# 1. App store versions (전체)
c, b = api(:get, "/v1/apps/#{APP_ID}/appStoreVersions?limit=10&sort=-createdDate")
versions = JSON.parse(b)['data']
puts "=== App Store Versions ==="
versions.each do |v|
  a = v['attributes']
  puts "  id=#{v['id']}"
  puts "    versionString=#{a['versionString']}  state=#{a['appStoreState']}  platform=#{a['platform']}"
  puts "    createdDate=#{a['createdDate']}"
end

# 2. 최신 build 처리 상태
c, b = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&limit=5&sort=-uploadedDate")
builds = JSON.parse(b)['data']
puts "\n=== Recent Builds ==="
builds.each do |bld|
  a = bld['attributes']
  puts "  id=#{bld['id']}  ver=#{a['version']}  state=#{a['processingState']}  uploaded=#{a['uploadedDate']}"
end

# 3. Resolution Center (rejection feedback)
c, b = api(:get, "/v1/apps/#{APP_ID}/appStoreVersions?limit=1&sort=-createdDate")
ver = JSON.parse(b)['data'].first
ver_id = ver['id']
puts "\n=== Latest Version Details: #{ver_id} ==="
c, b = api(:get, "/v1/appStoreVersions/#{ver_id}?include=appStoreVersionLocalizations,appStoreVersionSubmission,appStoreReviewDetail")
included = JSON.parse(b)['included'] || []
included.each do |inc|
  puts "  type=#{inc['type']}  id=#{inc['id']}"
  a = inc['attributes'] || {}
  case inc['type']
  when 'appStoreVersionLocalizations'
    puts "    locale=#{a['locale']}  description.len=#{(a['description']||'').length}  keywords=#{a['keywords']&.slice(0,80)}"
  when 'appStoreVersionSubmissions'
    puts "    attrs=#{a.inspect[0..200]}"
  end
end
