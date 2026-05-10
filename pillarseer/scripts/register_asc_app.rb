#!/usr/bin/env ruby
# pillarseer 신규 ASC 앱 등록 (Bundle ID + App)
require_relative '_helpers'

# 1. Bundle ID 조회/생성
puts "▶︎ Bundle ID 확인: #{BUNDLE_ID}"
code, body = api(:get, "/v1/bundleIds?filter[identifier]=#{BUNDLE_ID}&limit=1")
data = JSON.parse(body)['data']
bundle_internal_id = nil

if data && data.any?
  bundle_internal_id = data[0]['id']
  puts "✅ Bundle ID 이미 등록됨: id=#{bundle_internal_id}"
else
  puts "▶︎ Bundle ID 신규 등록"
  code, body = api(:post, "/v1/bundleIds", {
    data: {
      type: 'bundleIds',
      attributes: {
        identifier: BUNDLE_ID,
        name: 'Pillar Seer',
        platform: 'IOS'
      }
    }
  })
  if code == '201'
    bundle_internal_id = JSON.parse(body)['data']['id']
    puts "✅ Bundle ID 생성됨: id=#{bundle_internal_id}"
  else
    puts "❌ Bundle ID 등록 실패: #{code} #{body}"
    exit 1
  end
end

# 2. App 조회/생성
puts "▶︎ App 확인: bundleId=#{BUNDLE_ID}"
code, body = api(:get, "/v1/apps?filter[bundleId]=#{BUNDLE_ID}&limit=1")
apps = JSON.parse(body)['data']

if apps && apps.any?
  app_id = apps[0]['id']
  puts "✅ App 이미 등록됨: APP_ID=#{app_id}"
  puts "   name=#{apps[0]['attributes']['name']}"
  puts ""
  puts "다음 단계: PILLARSEER_APP_ID=#{app_id} 환경변수 설정 또는 _helpers.rb 의 APP_ID 상수 갱신"
else
  puts "▶︎ App 신규 등록"
  code, body = api(:post, "/v1/apps", {
    data: {
      type: 'apps',
      attributes: {
        bundleId: BUNDLE_ID,
        name: 'Pillar Seer',
        primaryLocale: 'en-US',
        sku: 'PILLARSEER001'
      },
      relationships: {
        bundleId: {
          data: { type: 'bundleIds', id: bundle_internal_id }
        }
      }
    }
  })
  if code == '201'
    app_id = JSON.parse(body)['data']['id']
    puts "✅ App 생성됨: APP_ID=#{app_id}"
    puts ""
    puts "다음 단계: PILLARSEER_APP_ID=#{app_id} 환경변수 설정 또는 _helpers.rb 의 APP_ID 상수 갱신"
  else
    puts "❌ App 등록 실패: #{code}"
    puts body
    exit 1
  end
end
