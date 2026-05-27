#!/usr/bin/env ruby
require_relative '_helpers'

SUB = '1a25ba1c-163c-40f0-a2fb-063b64d99bf1'
VERSION_ID = '2084f5bc-9577-427d-b6d7-0420cb750b31'
IAP_ID = '6772283210'

puts "▶︎ POST appStoreVersion item to #{SUB}"
c, b = api(:post, '/v1/reviewSubmissionItems', {
  data: {
    type: 'reviewSubmissionItems',
    relationships: {
      reviewSubmission: { data: { type: 'reviewSubmissions', id: SUB } },
      appStoreVersion: { data: { type: 'appStoreVersions', id: VERSION_ID } }
    }
  }
})
puts "  HTTP #{c}"
puts "  body=#{b[0..1000]}"

puts "\n▶︎ POST IAP item"
c, b = api(:post, '/v1/reviewSubmissionItems', {
  data: {
    type: 'reviewSubmissionItems',
    relationships: {
      reviewSubmission: { data: { type: 'reviewSubmissions', id: SUB } },
      inAppPurchaseV2: { data: { type: 'inAppPurchases', id: IAP_ID } }
    }
  }
})
puts "  HTTP #{c}"
puts "  body=#{b[0..1000]}"
