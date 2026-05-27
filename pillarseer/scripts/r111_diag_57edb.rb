#!/usr/bin/env ruby
require_relative '_helpers'

OLD = '57edb925-4d4d-4688-a34b-ad2964edddde'
EMPTY = '1a25ba1c-163c-40f0-a2fb-063b64d99bf1'

[OLD, EMPTY].each do |sid|
  puts "=== submission #{sid} ==="
  c, b = api(:get, "/v1/reviewSubmissions/#{sid}/items")
  puts "HTTP #{c}"
  puts "  raw: #{b[0..600]}"
end
