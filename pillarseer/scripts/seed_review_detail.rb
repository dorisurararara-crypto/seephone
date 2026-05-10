#!/usr/bin/env ruby
# betaAppReviewDetails (contact info) + betaBuildLocalizations (whatsNew) + usesNonExemptEncryption
require_relative '_helpers'

# 1. betaAppReviewDetails
code, body = api(:patch, "/v1/betaAppReviewDetails/#{APP_ID}", {
  data: {
    type: 'betaAppReviewDetails',
    id: APP_ID,
    attributes: {
      contactFirstName: 'Seunghyeon',
      contactLastName: 'Lee',
      contactPhone: '+821000000000',
      contactEmail: 'dorisurararara@gmail.com'
    }
  }
})
puts "betaAppReviewDetails: HTTP #{code}"
puts body[0..200] unless code.to_i == 200

# 2. 최근 빌드 ID
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&sort=-version&limit=1")
build = JSON.parse(body)['data'].first
build_id = build['id']
puts "Build ID: #{build_id} (v#{build['attributes']['version']})"

# 3. betaBuildLocalizations (ko + en-US)
WHATS_NEW = {
  'ko' => "v1.0.0 첫 베타. 7화면 (Splash/Input/Result/Home/Reports/Discover/Profile) + Julian Day Number 만세력 + 5행 분포 + 60일주 콘텐츠 300 entries.",
  'en-US' => "v1.0.0 first beta. 7 screens + Julian Day Number based pillar calculation + Five Element distribution + 60 day-pillar content (300 entries)."
}
WHATS_NEW.each do |loc, txt|
  code, body = api(:post, '/v1/betaBuildLocalizations', {
    data: {
      type: 'betaBuildLocalizations',
      attributes: { locale: loc, whatsNew: txt },
      relationships: { build: { data: { type: 'builds', id: build_id } } }
    }
  })
  puts "  betaBuildLoc[#{loc}]: HTTP #{code}"
  puts "    #{body[0..200]}" unless [201, 409].include?(code.to_i)
end

# 4. usesNonExemptEncryption = false (수출 규제 면제)
code, body = api(:patch, "/v1/builds/#{build_id}", {
  data: {
    type: 'builds',
    id: build_id,
    attributes: { usesNonExemptEncryption: false }
  }
})
puts "usesNonExemptEncryption=false: HTTP #{code}"
puts body[0..200] unless code.to_i == 200
