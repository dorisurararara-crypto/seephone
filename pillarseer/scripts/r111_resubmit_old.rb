#!/usr/bin/env ruby
# 거절된 34f8f7fe 를 다시 submit 시도 (state 가 UNRESOLVED_ISSUES → 가능한가?)
require_relative '_helpers'

OLD_SUB = '34f8f7fe-98a4-4126-abab-198267a880e3'

# 1. 현재 state 확인
c, b = api(:get, "/v1/reviewSubmissions/#{OLD_SUB}")
puts "GET HTTP #{c}"
puts b[0..600]

# 2. PATCH submitted=true 시도
puts "\n▶︎ PATCH submitted=true on REJECTED submission"
c, b = api(:patch, "/v1/reviewSubmissions/#{OLD_SUB}", {
  data: { type: 'reviewSubmissions', id: OLD_SUB, attributes: { submitted: true } }
})
puts "  HTTP #{c}"
puts "  body=#{b[0..800]}"
