require_relative '_helpers'
# disable
code, body = api(:patch, "/v1/betaGroups/#{EXTERNAL_GROUP_ID}",
                 {data: {type: 'betaGroups', id: EXTERNAL_GROUP_ID,
                         attributes: {publicLinkEnabled: false}}})
puts "disable: HTTP #{code}"
sleep 3
# enable
code, body = api(:patch, "/v1/betaGroups/#{EXTERNAL_GROUP_ID}",
                 {data: {type: 'betaGroups', id: EXTERNAL_GROUP_ID,
                         attributes: {publicLinkEnabled: true}}})
puts "enable: HTTP #{code}"
sleep 2
# 재조회
code, body = api(:get, "/v1/betaGroups/#{EXTERNAL_GROUP_ID}")
a = JSON.parse(body)['data']['attributes']
puts "publicLinkEnabled: #{a['publicLinkEnabled']}"
puts "publicLink: #{a['publicLink']}"
puts "publicLinkId: #{a['publicLinkId']}"
