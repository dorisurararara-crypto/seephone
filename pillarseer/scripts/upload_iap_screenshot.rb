#!/usr/bin/env ruby
# R110 — Upload IAP review screenshot (paywall) so IAP state → READY_TO_SUBMIT
require_relative '_helpers'
require 'digest'
require 'net/http'

IAP_ID = '6772283210'
SHOT = '/tmp/pillar_shots/appstore/IAP_REVIEW_SCREENSHOT.png'

# Check if IAP already has a review screenshot, delete if so
c, b = api(:get, "/v2/inAppPurchases/#{IAP_ID}/appStoreReviewScreenshot")
existing = JSON.parse(b)['data']
if existing
  puts "Existing review screenshot id=#{existing['id']} — deleting"
  api(:delete, "/v1/inAppPurchaseAppStoreReviewScreenshots/#{existing['id']}")
end

bytes = File.binread(SHOT)
size = bytes.bytesize
fname = File.basename(SHOT)

c, b = api(:post, '/v1/inAppPurchaseAppStoreReviewScreenshots', {
  data: {
    type: 'inAppPurchaseAppStoreReviewScreenshots',
    attributes: { fileSize: size, fileName: fname },
    relationships: { inAppPurchaseV2: { data: { type: 'inAppPurchases', id: IAP_ID } } }
  }
})
raise "create FAIL #{c}: #{b[0..400]}" unless c.to_i == 201

data = JSON.parse(b)['data']
sid = data['id']
ops = data['attributes']['uploadOperations']
puts "Created review screenshot id=#{sid}, #{ops.size} upload operations"

ops.each do |op|
  uri = URI(op['url'])
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 120
  req = Net::HTTP::Put.new(uri.request_uri)
  op['requestHeaders'].each { |h| req[h['name']] = h['value'] }
  req.body = bytes.byteslice(op['offset'], op['length'])
  resp = http.request(req)
  unless (200..299).include?(resp.code.to_i)
    raise "PUT failed #{resp.code}: #{resp.body[0..200]}"
  end
end

checksum = Digest::MD5.hexdigest(bytes)
c, b = api(:patch, "/v1/inAppPurchaseAppStoreReviewScreenshots/#{sid}", {
  data: {
    type: 'inAppPurchaseAppStoreReviewScreenshots',
    id: sid,
    attributes: { uploaded: true, sourceFileChecksum: checksum }
  }
})
raise "PATCH FAIL #{c}: #{b[0..300]}" unless c.to_i == 200

puts "✅ IAP review screenshot uploaded."

# Verify IAP state
sleep 2
c, b = api(:get, "/v2/inAppPurchases/#{IAP_ID}")
state = JSON.parse(b)['data']['attributes']['state']
puts "IAP state now: #{state}"
