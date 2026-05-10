#!/usr/bin/env ruby
# protagonist ASC 빌드 상태 조회
require_relative '_helpers'

limit = ARGV[0] || 10
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&sort=-version&limit=#{limit}")
data = JSON.parse(body)
if data['data'].nil? || data['data'].empty?
  puts "빌드 없음 (HTTP #{code}) — 업로드 직후엔 1~5분 더 기다려야 ASC 가 record 만듦"
  exit 0
end
printf "%-6s %-18s %-18s %s\n", 'build', 'state', 'expiration', 'uploaded'
data['data'].each do |b|
  a = b['attributes']
  printf "%-6s %-18s %-18s %s\n",
    a['version'], a['processingState'], a['expirationDate'] || 'valid', a['uploadedDate']
end
