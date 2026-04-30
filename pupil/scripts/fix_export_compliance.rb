#!/usr/bin/env ruby
# ASC 의 모든 활성 빌드에 대해 usesNonExemptEncryption=false 설정.
# Info.plist 에 ITSAppUsesNonExemptEncryption=false 추가하면 미래 빌드는 자동 통과지만,
# 이미 올라간 빌드는 한 번 PATCH 해줘야 외부 그룹 제출 가능.
require_relative '_helpers'

code, body = api(:get, "/v1/builds?filter[app]=#{APP_ID}&filter[expired]=false&fields[builds]=version,uploadedDate,usesNonExemptEncryption&limit=20")
builds = JSON.parse(body)['data'] || []
abort "❌ no builds found: #{body}" if builds.empty?

builds.each do |b|
  v = b['attributes']['version']
  enc = b['attributes']['usesNonExemptEncryption']
  bid = b['id']
  if enc.nil?
    payload = {
      data: {
        type: 'builds',
        id: bid,
        attributes: { usesNonExemptEncryption: false },
      }
    }
    c, r = api(:patch, "/v1/builds/#{bid}", payload)
    if c.to_i.between?(200, 299)
      puts "✓ build #{v} (id=#{bid}) usesNonExemptEncryption=false 설정"
    else
      puts "❌ build #{v} 실패: #{c} #{r}"
    end
  else
    puts "  build #{v} 이미 #{enc} — skip"
  end
end
