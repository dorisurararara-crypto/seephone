#!/usr/bin/env ruby
# Apple Developer App ID 에 HealthKit capability 추가.
# 한 번만 돌리면 됨 — 이후 빌드는 자동 sync.
#
# 사용: ./scripts/enable_healthkit.rb
require_relative '_helpers'

BUNDLE_IDENTIFIER = 'com.ganziman.pupil'

# 1) bundleId resource ID 찾기
code, body = api(:get, "/v1/bundleIds?filter[identifier]=#{BUNDLE_IDENTIFIER}&limit=1")
data = JSON.parse(body)
bundle = data.dig('data', 0)
abort "bundleId not found: #{body}" unless bundle
bundle_resource_id = bundle['id']
puts "✓ bundleId resource: #{bundle_resource_id}"

# 2) 기존 capabilities 조회 — 이미 활성화돼 있으면 skip
code, body = api(:get, "/v1/bundleIds/#{bundle_resource_id}/bundleIdCapabilities")
caps = JSON.parse(body)['data'] || []
existing = caps.map { |c| c.dig('attributes', 'capabilityType') }
puts "현재 capabilities: #{existing.join(', ')}"

if existing.include?('HEALTHKIT')
  puts "✓ HEALTHKIT 이미 활성화됨 — skip"
  exit 0
end

# 3) HEALTHKIT capability 추가
payload = {
  data: {
    type: 'bundleIdCapabilities',
    attributes: { capabilityType: 'HEALTHKIT' },
    relationships: {
      bundleId: { data: { type: 'bundleIds', id: bundle_resource_id } }
    }
  }
}
code, body = api(:post, '/v1/bundleIdCapabilities', payload)

if code.to_i.between?(200, 299)
  puts "✓ HEALTHKIT capability 추가 성공"
else
  abort "❌ 추가 실패 (#{code}): #{body}"
end
