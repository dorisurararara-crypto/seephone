require_relative '_helpers'
require 'net/http'
require 'uri'
require 'json'

b15 = '0b24806b-15ce-4236-a398-85caec9ffdd4'
u = URI("https://api.appstoreconnect.apple.com/v1/builds/#{b15}/relationships/betaGroups")
req = Net::HTTP::Delete.new(u)
req['Authorization'] = "Bearer #{jwt_token}"
req['Content-Type'] = 'application/json'
req.body = {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]}.to_json
h = Net::HTTP.new(u.host, u.port); h.use_ssl = true
res = h.request(req)
puts "HTTP #{res.code}: #{res.body}"
