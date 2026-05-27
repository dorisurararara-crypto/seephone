#!/usr/bin/env ruby
require_relative '_helpers'
VERSION_ID = '2084f5bc-9577-427d-b6d7-0420cb750b31'

# 1. Localizations
c, b = api(:get, "/v1/appStoreVersions/#{VERSION_ID}/appStoreVersionLocalizations")
puts "HTTP #{c}"
data = JSON.parse(b)['data']
data.each do |loc|
  a = loc['attributes']
  puts ""
  puts "id=#{loc['id']}  locale=#{a['locale']}"
  puts "  name=#{a['name']}"
  puts "  subtitle=#{a['subtitle']}"
  puts "  description=#{(a['description']||'')[0..150]}"
  puts "  keywords=#{a['keywords']}"
  puts "  promotionalText=#{a['promotionalText']}"
  puts "  marketingUrl=#{a['marketingUrl']}"
  puts "  supportUrl=#{a['supportUrl']}"
  puts "  whatsNew=#{(a['whatsNew']||'')[0..120]}"
end
