#!/usr/bin/env ruby
# R111 — appInfoLocalizations 의 name + subtitle K-pop lead 로 변경
require_relative '_helpers'

INFO_LOC_KO = '9a0ac138-1676-4a56-ada7-1536fba6f347'
INFO_LOC_EN = '65122676-8c69-495c-888e-dcf7e9e0537c'

# ko: 30 chars 이내
ko_name = "필러시어 - 최애의 사주"           # 16 chars
ko_subtitle = "K-pop 아이돌 차트 · 셀럽 203명"  # 27 chars

# en-US: 30 chars 이내
en_name = "Pillarseer - K-pop Charts"        # 25 chars
en_subtitle = "K-pop Idol Charts & Stories"  # 27 chars

def patch_appinfo(id, attrs, label)
  c, b = api(:patch, "/v1/appInfoLocalizations/#{id}", {
    data: { type: 'appInfoLocalizations', id: id, attributes: attrs }
  })
  ok = c.to_i == 200
  puts "  [#{label}] HTTP #{c}  #{ok ? '✅' : '❌'}"
  puts "    body=#{b[0..400]}" unless ok
  ok
end

puts "▶︎ PATCH ko appInfoLocalization ..."
puts "  name='#{ko_name}' (#{ko_name.length})  subtitle='#{ko_subtitle}' (#{ko_subtitle.length})"
patch_appinfo(INFO_LOC_KO, { name: ko_name, subtitle: ko_subtitle }, 'ko')

puts "▶︎ PATCH en-US appInfoLocalization ..."
puts "  name='#{en_name}' (#{en_name.length})  subtitle='#{en_subtitle}' (#{en_subtitle.length})"
patch_appinfo(INFO_LOC_EN, { name: en_name, subtitle: en_subtitle }, 'en-US')
