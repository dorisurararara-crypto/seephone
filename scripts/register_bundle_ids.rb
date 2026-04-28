#!/usr/bin/env ruby
# 빡신/pupil/anger Bundle ID 자동 등록 (Apple Developer Portal via ASC API)
#
# 주의: ASC App 등록 (Apple Connect 의 앱 메타데이터) 은 API 미지원 → 웹 UI 필요.
# Bundle ID 만 미리 만들어둠.

require_relative '/Users/seunghyeon/shadow/shadowrun/scripts/asc/_helpers'

APPS = [
  { id: 'com.ganziman.bbaksin', name: 'Bbaksin' },
  { id: 'com.ganziman.pupil',   name: 'Pupil Detector' },
  { id: 'com.ganziman.anger',   name: 'Anger Power' },
]

# 1. 기존 bundle ID 조회
code, body = api(:get, '/v1/bundleIds?limit=200')
existing = JSON.parse(body)['data'].map { |b| b['attributes']['identifier'] }

APPS.each do |app|
  if existing.include?(app[:id])
    puts "[skip] #{app[:id]} 이미 등록됨"
    next
  end

  payload = {
    data: {
      type: 'bundleIds',
      attributes: {
        identifier: app[:id],
        name: app[:name],
        platform: 'IOS'
      }
    }
  }

  code, body = api(:post, '/v1/bundleIds', payload)
  if code.to_i == 201
    parsed = JSON.parse(body)
    puts "[OK]   #{app[:id]} → #{parsed['data']['id']}"
  else
    puts "[FAIL] #{app[:id]} (HTTP #{code})"
    puts body[0..500]
  end
end
