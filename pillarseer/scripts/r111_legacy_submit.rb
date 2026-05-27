#!/usr/bin/env ruby
# 레거시 appStoreVersionSubmissions API 시도 — 단일 version 제출
require_relative '_helpers'

VERSION_ID = '2084f5bc-9577-427d-b6d7-0420cb750b31'

# 1. 현재 version 의 submission 확인
c, b = api(:get, "/v1/appStoreVersions/#{VERSION_ID}/appStoreVersionSubmission")
puts "GET appStoreVersionSubmission HTTP #{c}"
puts b[0..600]

# 2. 없으면 POST 로 생성
puts "\n▶︎ POST 로 새 submission 시도"
c, b = api(:post, '/v1/appStoreVersionSubmissions', {
  data: {
    type: 'appStoreVersionSubmissions',
    relationships: {
      appStoreVersion: { data: { type: 'appStoreVersions', id: VERSION_ID } }
    }
  }
})
puts "  HTTP #{c}"
puts "  body=#{b[0..1000]}"
