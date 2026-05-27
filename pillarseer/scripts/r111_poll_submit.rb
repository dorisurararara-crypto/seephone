#!/usr/bin/env ruby
# 34f8f7fe submission 의 PATCH submitted=true 가 "Version not ready" 가 아닌 다른 응답 나올 때까지 60s polling
require_relative '_helpers'

OLD_SUB = '34f8f7fe-98a4-4126-abab-198267a880e3'
MAX = 20  # 20분

MAX.times do |i|
  c, b = api(:patch, "/v1/reviewSubmissions/#{OLD_SUB}", {
    data: { type: 'reviewSubmissions', id: OLD_SUB, attributes: { submitted: true } }
  })
  if c.to_i == 200
    puts "[#{Time.now.strftime('%H:%M:%S')}] SUCCESS HTTP 200"
    s = JSON.parse(b)['data']['attributes']['state']
    puts "state=#{s}"
    exit 0
  end
  begin
    err = JSON.parse(b)['errors']&.first
    detail = err&.dig('meta', 'associatedErrors')&.values&.flatten&.first&.dig('detail') || err['detail']
    puts "[#{Time.now.strftime('%H:%M:%S')}] retry #{i+1}/#{MAX} HTTP #{c} — #{detail}"
  rescue => e
    puts "[#{Time.now.strftime('%H:%M:%S')}] retry #{i+1}/#{MAX} HTTP #{c} parse=#{e.message}"
  end
  STDOUT.flush
  sleep 60
end
puts "TIMEOUT after #{MAX} min — manual intervention needed"
exit 1
