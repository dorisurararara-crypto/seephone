#!/usr/bin/env ruby
require_relative '_helpers'

[
  '57edb925-4d4d-4688-a34b-ad2964edddde',  # R110 잔존
  '1a25ba1c-163c-40f0-a2fb-063b64d99bf1',  # 방금 만들었던 빈 것
].each do |sid|
  c, b = api(:patch, "/v1/reviewSubmissions/#{sid}", {
    data: { type: 'reviewSubmissions', id: sid, attributes: { canceled: true } }
  })
  puts "CANCEL #{sid} → HTTP #{c}"
  puts "  body=#{b[0..400]}" unless c.to_i == 200
end
