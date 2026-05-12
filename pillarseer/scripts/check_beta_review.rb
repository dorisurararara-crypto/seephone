require_relative '_helpers'

# 모든 build 의 beta review status 확인
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&sort=-version&limit=15&include=betaAppReviewSubmission")
data = JSON.parse(body)
included = data['included'] || []
submissions = {}
included.each do |inc|
  if inc['type'] == 'betaAppReviewSubmissions'
    submissions[inc['id']] = inc['attributes']
  end
end

printf "%-6s %-12s %-30s\n", 'build', 'state', 'beta-review-state'
data['data'].each do |b|
  v = b['attributes']['version']
  st = b['attributes']['processingState']
  rel = b['relationships']['betaAppReviewSubmission']
  sub_id = rel && rel['data'] && rel['data']['id']
  rev_state = sub_id ? (submissions[sub_id]&.dig('betaReviewState') || '?') : '(not submitted)'
  printf "%-6s %-12s %-30s\n", v, st, rev_state
end
