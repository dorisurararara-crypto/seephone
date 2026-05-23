#!/usr/bin/env ruby
# R110 — Final Submit for Review (app version 1.0.0 + IAP premium pack bundle)
require_relative '_helpers'

VERSION_ID = '2084f5bc-9577-427d-b6d7-0420cb750b31'
IAP_ID = '6772283210'

# 0. Sanity checks
c, b = api(:get, "/v1/appStoreVersions/#{VERSION_ID}")
vstate = JSON.parse(b)['data']['attributes']['appStoreState']
puts "App Store version state: #{vstate}"
unless ['PREPARE_FOR_SUBMISSION', 'READY_FOR_REVIEW'].include?(vstate)
  raise "Version not ready: #{vstate}"
end

c, b = api(:get, "/v2/inAppPurchases/#{IAP_ID}")
istate = JSON.parse(b)['data']['attributes']['state']
puts "IAP state: #{istate}"
unless ['READY_TO_SUBMIT'].include?(istate)
  raise "IAP not ready: #{istate}"
end

# 1. Create review submission
c, b = api(:post, '/v1/reviewSubmissions', {
  data: {
    type: 'reviewSubmissions',
    attributes: { platform: 'IOS' },
    relationships: { app: { data: { type: 'apps', id: APP_ID } } }
  }
})
raise "submission create FAIL #{c}: #{b[0..400]}" unless c.to_i == 201
sub_id = JSON.parse(b)['data']['id']
puts "Created reviewSubmission id=#{sub_id}"

# 2. Add appStoreVersion as item
c, b = api(:post, '/v1/reviewSubmissionItems', {
  data: {
    type: 'reviewSubmissionItems',
    relationships: {
      reviewSubmission: { data: { type: 'reviewSubmissions', id: sub_id } },
      appStoreVersion: { data: { type: 'appStoreVersions', id: VERSION_ID } }
    }
  }
})
raise "appVersion item FAIL #{c}: #{b[0..400]}" unless c.to_i == 201
puts "  added appStoreVersion item"

# 3. Add IAP as item
c, b = api(:post, '/v1/reviewSubmissionItems', {
  data: {
    type: 'reviewSubmissionItems',
    relationships: {
      reviewSubmission: { data: { type: 'reviewSubmissions', id: sub_id } },
      inAppPurchaseV2: { data: { type: 'inAppPurchases', id: IAP_ID } }
    }
  }
})
if c.to_i == 201
  puts "  added inAppPurchaseV2 item"
elsif c.to_i == 409
  puts "  IAP already bundled with version (409 — proceeding)"
else
  raise "IAP item FAIL #{c}: #{b[0..400]}"
end

# 4. Submit
c, b = api(:patch, "/v1/reviewSubmissions/#{sub_id}", {
  data: {
    type: 'reviewSubmissions',
    id: sub_id,
    attributes: { submitted: true }
  }
})
raise "submit FAIL #{c}: #{b[0..400]}" unless c.to_i == 200

state = JSON.parse(b)['data']['attributes']['state']
puts "\n🎉 Submitted. reviewSubmission state: #{state}"
puts "Apple typically responds in 24-48 hours."
