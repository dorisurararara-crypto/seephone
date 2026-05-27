#!/usr/bin/env ruby
require_relative '_helpers'

OLD = '57edb925-4d4d-4688-a34b-ad2964edddde'
NEW = '1a25ba1c-163c-40f0-a2fb-063b64d99bf1'

[OLD, NEW].each do |sid|
  puts "\n=== submission #{sid} full ==="
  c, b = api(:get, "/v1/reviewSubmissions/#{sid}?include=items")
  puts "HTTP #{c}"
  puts b[0..2500]
end
