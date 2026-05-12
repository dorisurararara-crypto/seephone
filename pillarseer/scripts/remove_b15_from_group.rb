require_relative '_helpers'
b15 = '0b24806b-15ce-4236-a398-85caec9ffdd4'

# Build → BetaGroup relationship 삭제 시도
code, body = api(:delete, "/v1/builds/#{b15}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "DELETE relationship: HTTP #{code}"
puts body unless code.to_i == 204
