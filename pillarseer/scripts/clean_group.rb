require_relative '_helpers'
require 'net/http'
require 'json'

def del_build(b_id)
  u = URI("https://api.appstoreconnect.apple.com/v1/builds/#{b_id}/relationships/betaGroups")
  req = Net::HTTP::Delete.new(u)
  req['Authorization'] = "Bearer #{jwt_token}"
  req['Content-Type'] = 'application/json'
  req.body = {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]}.to_json
  h = Net::HTTP.new(u.host, u.port); h.use_ssl = true
  res = h.request(req)
  [res.code, res.body]
end

# Remove v4 (not submitted) + v3 + v6 — keep only v16 (latest BETA_APPROVED)
to_remove = {
  'v3'  => '438bbff5-8ded-4f1d-bad3-9ebd879ad3b3',
  'v4'  => '6e1a52d3-7292-432c-9679-4b87b5679e4d',
  'v6'  => 'da6e83a8-4611-483b-812c-fef376e86b5e',
}
to_remove.each do |label, bid|
  code, body = del_build(bid)
  puts "remove #{label}: HTTP #{code}"
end

# 잔존 확인
puts "\n─── remaining ───"
code, body = api(:get, "/v1/betaGroups/#{EXTERNAL_GROUP_ID}/builds")
JSON.parse(body)['data'].each do |b|
  code2, body2 = api(:get, "/v1/builds/#{b['id']}")
  attrs = JSON.parse(body2)['data']['attributes']
  puts "  v#{attrs['version']} state=#{attrs['processingState']} expired=#{attrs['expired']}"
end

# betaRecruitmentCriteria 확인
puts "\n─── betaRecruitmentCriteria ───"
code, body = api(:get, "/v1/betaGroups/#{EXTERNAL_GROUP_ID}?include=betaRecruitmentCriteria&fields[betaGroups]=name,publicLinkEnabled,publicLink,betaRecruitmentCriteria")
data = JSON.parse(body)
puts data['data']['relationships']['betaRecruitmentCriteria'].inspect rescue puts 'no recruitmentCriteria rel'
inc = data['included'] || []
inc.each do |i|
  puts "  type=#{i['type']} attr=#{i['attributes'].inspect}"
end
