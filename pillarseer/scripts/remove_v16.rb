require_relative '_helpers'
require 'net/http'
require 'json'
b16 = '3b51b143-3c41-47b8-8228-15fb717c8b1b'
b17 = '6df80630-26e5-48c4-833e-8fcf55f6124e'

# add v17 to group
code, body = api(:post, "/v1/builds/#{b17}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "add v17: HTTP #{code}"

# remove v16
u = URI("https://api.appstoreconnect.apple.com/v1/builds/#{b16}/relationships/betaGroups")
req = Net::HTTP::Delete.new(u)
req['Authorization'] = "Bearer #{jwt_token}"
req['Content-Type'] = 'application/json'
req.body = {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]}.to_json
h = Net::HTTP.new(u.host, u.port); h.use_ssl = true
res = h.request(req)
puts "remove v16: HTTP #{res.code}"
