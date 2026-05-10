#!/usr/bin/env ruby
# 외부 베타 그룹 'ganzitester' 자동 생성
require_relative '_helpers'

# 이미 있는지 체크
code, body = api(:get, "/v1/apps/#{APP_ID}/betaGroups?limit=50")
existing = JSON.parse(body)['data']
match = existing.find { |g| g['attributes']['name'] == 'ganzitester' }
if match
  puts "[skip] ganzitester 이미 존재 → id=#{match['id']}"
  puts "       publicLink=#{match['attributes']['publicLink'] || '(disabled)'}"
  exit 0
end

payload = {
  data: {
    type: 'betaGroups',
    attributes: {
      name: 'ganzitester',
      publicLinkEnabled: true,
      publicLinkLimitEnabled: false
    },
    relationships: { app: { data: { type: 'apps', id: APP_ID } } }
  }
}

code, body = api(:post, '/v1/betaGroups', payload)
if code.to_i == 201
  parsed = JSON.parse(body)['data']
  puts "[OK] ganzitester 생성됨"
  puts "     group_id=#{parsed['id']}"
  puts "     publicLink=#{parsed['attributes']['publicLink']}"
else
  puts "[FAIL] HTTP #{code}"
  puts body[0..600]
  exit 1
end
