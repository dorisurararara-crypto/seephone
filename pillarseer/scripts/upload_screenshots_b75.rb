#!/usr/bin/env ruby
# R110 — Upload App Store screenshots (1320x2868, 6.9") to ko + en-US locales
require_relative '_helpers'
require 'digest'
require 'net/http'

VERSION_ID = '2084f5bc-9577-427d-b6d7-0420cb750b31'
DEVICE_TYPE = 'APP_IPHONE_67'  # ASC enum covers both 6.7" and 6.9" Pro Max

# Ordered for App Store impact (slot 1-3 = search result preview)
SHOTS = [
  '/tmp/pillar_shots/appstore/01_home_mysaju.png',
  '/tmp/pillar_shots/appstore/06_today.png',
  '/tmp/pillar_shots/appstore/02_personality_deep.png',
  '/tmp/pillar_shots/appstore/04_premium_gates.png',
  '/tmp/pillar_shots/appstore/05_paywall_IAP.png',
  '/tmp/pillar_shots/appstore/07_more_menu.png',
  '/tmp/pillar_shots/appstore/09_compatibility.png',
]

LOC_BY_LOCALE = {
  'ko' => '7b4bd70c-1ee7-4773-bdb5-eaa36f9705c1',
  'en-US' => 'c5d2f6cc-7c45-4e9b-bb94-e4a96f086b80',
}

def put_upload(op, bytes)
  uri = URI(op['url'])
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 120
  req = Net::HTTP::Put.new(uri.request_uri)
  op['requestHeaders'].each { |h| req[h['name']] = h['value'] }
  offset = op['offset']
  length = op['length']
  req.body = bytes.byteslice(offset, length)
  resp = http.request(req)
  unless (200..299).include?(resp.code.to_i)
    raise "PUT failed #{resp.code}: #{resp.body[0..200]}"
  end
end

LOC_BY_LOCALE.each do |locale, loc_id|
  puts "\n=== #{locale} loc=#{loc_id} ==="

  # Find or create set
  c, b = api(:get, "/v1/appStoreVersionLocalizations/#{loc_id}/appScreenshotSets")
  sets = JSON.parse(b)['data']
  set = sets.find { |s| s['attributes']['screenshotDisplayType'] == DEVICE_TYPE }
  if set
    puts "  found existing set: #{set['id']} — deleting #{sets.size} screenshots first"
    c2, b2 = api(:get, "/v1/appScreenshotSets/#{set['id']}/appScreenshots")
    JSON.parse(b2)['data'].each do |sh|
      api(:delete, "/v1/appScreenshots/#{sh['id']}")
    end
    set_id = set['id']
  else
    c, b = api(:post, '/v1/appScreenshotSets', {
      data: {
        type: 'appScreenshotSets',
        attributes: { screenshotDisplayType: DEVICE_TYPE },
        relationships: { appStoreVersionLocalization: { data: { type: 'appStoreVersionLocalizations', id: loc_id } } }
      }
    })
    raise "set create FAIL #{c}: #{b[0..300]}" unless c.to_i == 201
    set_id = JSON.parse(b)['data']['id']
    puts "  created set: #{set_id}"
  end

  SHOTS.each_with_index do |path, idx|
    fname = File.basename(path)
    bytes = File.binread(path)
    size = bytes.bytesize

    c, b = api(:post, '/v1/appScreenshots', {
      data: {
        type: 'appScreenshots',
        attributes: { fileSize: size, fileName: fname },
        relationships: { appScreenshotSet: { data: { type: 'appScreenshotSets', id: set_id } } }
      }
    })
    raise "create FAIL #{c}: #{b[0..300]}" unless c.to_i == 201

    data = JSON.parse(b)['data']
    sid = data['id']
    ops = data['attributes']['uploadOperations']

    ops.each { |op| put_upload(op, bytes) }

    checksum = Digest::MD5.hexdigest(bytes)
    c, b = api(:patch, "/v1/appScreenshots/#{sid}", {
      data: {
        type: 'appScreenshots',
        id: sid,
        attributes: { uploaded: true, sourceFileChecksum: checksum }
      }
    })
    raise "PATCH FAIL #{c}: #{b[0..300]}" unless c.to_i == 200

    puts "  ✅ #{idx+1}/#{SHOTS.size}: #{fname}"
  end
end

puts "\n🎉 All screenshots uploaded for ko + en-US."
