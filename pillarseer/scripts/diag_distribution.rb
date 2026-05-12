require_relative '_helpers'

# 1. 외부 그룹 상세
code, body = api(:get, "/v1/betaGroups/#{EXTERNAL_GROUP_ID}?include=builds,betaTesters")
data = JSON.parse(body)
a = data['data']['attributes']
puts '─── ganzitester group ───'
puts "publicLinkEnabled: #{a['publicLinkEnabled']}"
puts "publicLinkLimit: #{a['publicLinkLimit']}"
puts "publicLinkLimitEnabled: #{a['publicLinkLimitEnabled']}"
puts "iosBuildsAvailableForAppleSiliconMac: #{a['iosBuildsAvailableForAppleSiliconMac']}"
puts "publicLink: #{a['publicLink']}"

# 2. 각 build 의 review state 상세
puts "\n─── build review states ───"
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&sort=-version&limit=20&include=betaAppReviewSubmission,buildBetaDetail")
data = JSON.parse(body)
included = data['included'] || []
review_map = {}
detail_map = {}
included.each do |i|
  if i['type'] == 'betaAppReviewSubmissions'
    review_map[i['id']] = i['attributes']['betaReviewState']
  elsif i['type'] == 'buildBetaDetails'
    detail_map[i['id']] = i['attributes']
  end
end

printf "%-6s %-9s %-18s %-18s %-18s\n", 'build', 'state', 'review', 'externalState', 'autoNotify'
data['data'].each do |b|
  v = b['attributes']['version']
  st = b['attributes']['processingState']
  exp = b['attributes']['expired']
  rev_rel = b['relationships']['betaAppReviewSubmission']
  rev_id = rev_rel && rev_rel['data'] && rev_rel['data']['id']
  rev = rev_id ? review_map[rev_id] : 'NONE'
  bd_rel = b['relationships']['buildBetaDetail']
  bd_id = bd_rel && bd_rel['data'] && bd_rel['data']['id']
  bd = bd_id && detail_map[bd_id]
  ext_state = bd ? bd['externalBuildState'] : '?'
  auto_notify = bd ? bd['autoNotifyEnabled'] : '?'
  printf "%-6s %-9s %-18s %-18s %-18s exp:%s\n", v, st, rev || 'NONE', ext_state, auto_notify, exp
end

# 3. betaBuildLocalizations (이게 누락이면 review 통과해도 distribution 안 됨)
puts "\n─── betaBuildLocalizations (Build #15) ───"
b15_id = '0b24806b-15ce-4236-a398-85caec9ffdd4'
code, body = api(:get, "/v1/builds/#{b15_id}/betaBuildLocalizations")
data = JSON.parse(body)
data['data'].each do |loc|
  a = loc['attributes']
  puts "  locale=#{a['locale']} whatsNew=#{(a['whatsNew'] || '').length} chars"
end
