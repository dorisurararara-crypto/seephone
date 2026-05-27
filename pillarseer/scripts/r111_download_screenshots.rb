#!/usr/bin/env ruby
require_relative '_helpers'
require 'open-uri'

LOC_EN = 'c5d2f6cc-7c45-4e9b-bb94-e4a96f086b80'
DEST_DIR = '/Users/seunghyeon/seephone/pillarseer/.playwright-mcp/asc_screenshots'

Dir.mkdir(DEST_DIR) unless Dir.exist?(DEST_DIR)

c, b = api(:get, "/v1/appStoreVersionLocalizations/#{LOC_EN}/appScreenshotSets?include=appScreenshots")
parsed = JSON.parse(b)
shots = (parsed['included'] || []).select { |x| x['type'] == 'appScreenshots' }
puts "screenshots: #{shots.size}"

shots.each_with_index do |s, i|
  attrs = s['attributes']
  fn = attrs['fileName']
  asset = attrs['assetDeliveryState']
  url_tpl = attrs.dig('imageAsset', 'templateUrl')
  w = attrs.dig('imageAsset', 'width')
  h = attrs.dig('imageAsset', 'height')
  puts "  #{i+1}. #{fn} #{w}x#{h} state=#{asset&.dig('state')}"
  next unless url_tpl
  # 원본 사이즈 다운로드 — w x h 그대로
  url = url_tpl.gsub('{w}', w.to_s).gsub('{h}', h.to_s).gsub('{f}', 'png')
  dest = "#{DEST_DIR}/#{fn}"
  next if File.exist?(dest)
  URI.open(url) { |io| File.write(dest, io.read, mode: 'wb') }
  puts "    → #{dest}"
end
