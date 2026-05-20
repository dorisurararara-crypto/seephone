#!/usr/bin/env ruby
# Try to: 1) withdraw build 61 Beta Review, 2) expire build 61, 3) delete 1.1.0 preReleaseVersion
# Goal: free ASC to accept 1.0.0+62 upload (marketing downgrade)

require_relative '_helpers'

BUILD_ID_61 = '1c573f45-649b-4920-a902-ab426e4511b6'
BETA_SUBMISSION_61 = '1c573f45-649b-4920-a902-ab426e4511b6'  # same id from API
PRV_110 = '9cb56428-81fe-442d-bd1e-d26b29401d68'

puts "=== Step 1: DELETE betaAppReviewSubmission for build 61 ==="
code, body = api(:delete, "/v1/betaAppReviewSubmissions/#{BETA_SUBMISSION_61}")
puts "  HTTP #{code}"
puts "  body: #{body[0..400]}" if code.to_i >= 400

puts "\n=== Step 2: PATCH build 61 expired=true ==="
code, body = api(:patch, "/v1/builds/#{BUILD_ID_61}",
                 {data: {type: 'builds', id: BUILD_ID_61,
                         attributes: {expired: true}}})
puts "  HTTP #{code}"
puts "  body: #{body[0..400]}" if code.to_i >= 400

puts "\n=== Step 3: DELETE preReleaseVersion 1.1.0 ==="
code, body = api(:delete, "/v1/preReleaseVersions/#{PRV_110}")
puts "  HTTP #{code}"
puts "  body: #{body[0..400]}" if code.to_i >= 400

puts "\n=== Verify: preReleaseVersions ==="
code, body = api(:get, "/v1/preReleaseVersions?filter%5Bapp%5D=#{APP_ID}&limit=50&sort=-version")
data = JSON.parse(body)
(data['data'] || []).each do |v|
  a = v['attributes']
  puts "  id=#{v['id']} version=#{a['version']} platform=#{a['platform']}"
end

puts "\n=== Verify: build 61 ==="
code, body = api(:get, "/v1/builds/#{BUILD_ID_61}")
data = JSON.parse(body)
b = data['data']
if b
  puts "  state=#{b['attributes']['processingState']} expired=#{b['attributes']['expired']} valid=#{b['attributes']['valid']}"
end
