#!/usr/bin/env ruby
require_relative '_helpers'
c, b = api(:get, "/v1/apps/#{APP_ID}/appStoreVersions?limit=10")
puts "HTTP #{c}"
puts b
