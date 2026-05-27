#!/usr/bin/env ruby
# R111 — build 77 VALID 까지 60s 주기 polling (stdout = 변화 시 한 줄)
require_relative '_helpers'

BUILD_NO = 77
last = nil
max_iters = 60  # 1h 안전장치
iters = 0

loop do
  c, b = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=#{BUILD_NO}&limit=1")
  data = JSON.parse(b)['data']
  state = data.empty? ? 'MISSING' : data.first['attributes']['processingState']
  if state != last
    puts "[#{Time.now.strftime('%H:%M:%S')}] build #{BUILD_NO} state: #{state}"
    STDOUT.flush
    last = state
  end
  break if state == 'VALID' || state == 'INVALID' || state == 'FAILED'
  iters += 1
  break if iters >= max_iters
  sleep 60
end

puts "BUILD_#{last}"
