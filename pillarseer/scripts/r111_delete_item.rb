#!/usr/bin/env ruby
require_relative '_helpers'

# 1. 34f8f7fe submission 의 모든 items 조회
SUB = '34f8f7fe-98a4-4126-abab-198267a880e3'
c, b = api(:get, "/v1/reviewSubmissions/#{SUB}/items")
puts "HTTP #{c}"
items = JSON.parse(b)['data']
items.each do |it|
  puts "  item id=#{it['id']}  type=#{it['type']}  attrs=#{it['attributes'].inspect[0..200]}"
end

# 2. 각 item 삭제 시도
items.each do |it|
  c2, b2 = api(:delete, "/v1/reviewSubmissionItems/#{it['id']}")
  puts "  DELETE #{it['id']} → HTTP #{c2}  #{c2.to_i == 204 ? '✅' : '❌'}"
  puts "    #{b2[0..300]}" if c2.to_i >= 400
end
