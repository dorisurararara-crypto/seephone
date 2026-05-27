#!/usr/bin/env ruby
require_relative '_helpers'

LOC_EN = 'c5d2f6cc-7c45-4e9b-bb94-e4a96f086b80'
LOC_KO = '7b4bd70c-1ee7-4773-bdb5-eaa36f9705c1'

en = File.read('/tmp/r111_whatsnew_en.txt')
ko = File.read('/tmp/r111_whatsnew_ko.txt')

[[LOC_EN, 'en-US', en], [LOC_KO, 'ko', ko]].each do |id, lab, text|
  c, b = api(:patch, "/v1/appStoreVersionLocalizations/#{id}", {
    data: { type: 'appStoreVersionLocalizations', id: id, attributes: { whatsNew: text } }
  })
  ok = c.to_i == 200
  puts "[#{lab}] HTTP #{c}  #{ok ? '✅' : '❌'}"
  puts "  #{b[0..300]}" unless ok
end
