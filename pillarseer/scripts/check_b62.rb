#!/usr/bin/env ruby
require_relative '_helpers'

code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=62&limit=1&include=preReleaseVersion")
data = JSON.parse(body)
b = data['data'].first
if b
  puts "build 62 id=#{b['id']} state=#{b['attributes']['processingState']} expired=#{b['attributes']['expired']}"
  puts "  preReleaseVersion: #{b['relationships']['preReleaseVersion']['data'].inspect}"
end
(data['included'] || []).each do |i|
  puts "  included[#{i['type']}] id=#{i['id']} attrs=#{i['attributes'].inspect}"
end
