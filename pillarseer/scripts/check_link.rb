require_relative '_helpers'
code, body = api(:get, '/v1/betaGroups/' + EXTERNAL_GROUP_ID)
data = JSON.parse(body)
a = data['data']['attributes']
puts 'name: ' + a['name'].to_s
puts 'publicLinkEnabled: ' + a['publicLinkEnabled'].to_s
puts 'publicLink: ' + a['publicLink'].to_s
puts 'publicLinkId: ' + a['publicLinkId'].to_s
puts 'createdDate: ' + a['createdDate'].to_s
