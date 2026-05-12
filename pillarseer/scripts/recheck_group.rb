require_relative '_helpers'
code, body = api(:get, "/v1/betaGroups/#{EXTERNAL_GROUP_ID}/builds")
data = JSON.parse(body)
puts "Builds linked to ganzitester (#{data['data'].length}):"
data['data'].each do |b|
  code2, body2 = api(:get, "/v1/builds/#{b['id']}")
  attrs = JSON.parse(body2)['data']['attributes']
  puts "  v#{attrs['version']} expired:#{attrs['expired']} state:#{attrs['processingState']}"
end
