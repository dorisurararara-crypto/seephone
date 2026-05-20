#!/usr/bin/env ruby
require_relative '_helpers'

puts "=== preReleaseVersions for app ==="
code, body = api(:get, "/v1/preReleaseVersions?filter%5Bapp%5D=#{APP_ID}&limit=50&sort=-version")
puts "HTTP #{code}"
data = JSON.parse(body)
puts "raw: #{data.inspect[0..500]}" if data['data'].nil?
(data['data'] || []).each do |v|
  a = v['attributes']
  puts "  id=#{v['id']} version=#{a['version']} platform=#{a['platform']}"
end

puts "\n=== build 61 detail ==="
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=61&limit=1&include=preReleaseVersion,betaGroups,betaAppReviewSubmission")
data = JSON.parse(body)
b = data['data'].first
if b
  puts "  id=#{b['id']} version=#{b['attributes']['version']} state=#{b['attributes']['processingState']} expired=#{b['attributes']['expired']}"
  rel = b['relationships']
  puts "  preReleaseVersion: #{rel['preReleaseVersion']['data'].inspect}"
  puts "  betaGroups: #{rel['betaGroups']['data'].inspect}"
  puts "  betaAppReviewSubmission: #{rel['betaAppReviewSubmission']['data'].inspect}"
end
data['included']&.each do |i|
  puts "  included[#{i['type']}] id=#{i['id']} attrs=#{i['attributes'].inspect[0..200]}"
end

puts "\n=== build 60 detail ==="
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=60&limit=1&include=preReleaseVersion,betaGroups,betaAppReviewSubmission")
data = JSON.parse(body)
b = data['data'].first
if b
  puts "  id=#{b['id']} version=#{b['attributes']['version']} state=#{b['attributes']['processingState']} expired=#{b['attributes']['expired']}"
  rel = b['relationships']
  puts "  preReleaseVersion: #{rel['preReleaseVersion']['data'].inspect}"
end
data['included']&.each do |i|
  puts "  included[#{i['type']}] id=#{i['id']} attrs=#{i['attributes'].inspect[0..200]}"
end
