#!/usr/bin/env ruby
# R111 — appStoreReviewDetail.notes 에 resubmit 메모 paste
require_relative '_helpers'

VERSION_ID = '2084f5bc-9577-427d-b6d7-0420cb750b31'

# 1. appStoreReviewDetail id 조회
c, b = api(:get, "/v1/appStoreVersions/#{VERSION_ID}/appStoreReviewDetail")
puts "GET HTTP #{c}"
data = JSON.parse(b)['data']
if data.nil?
  puts "  detail 없음 — POST 로 생성 필요"
  c2, b2 = api(:post, "/v1/appStoreReviewDetails", {
    data: {
      type: 'appStoreReviewDetails',
      relationships: { appStoreVersion: { data: { type: 'appStoreVersions', id: VERSION_ID } } }
    }
  })
  puts "  POST HTTP #{c2}: #{b2[0..300]}"
  data = JSON.parse(b2)['data']
end
detail_id = data['id']
puts "  detail id=#{detail_id}"

# 2. resubmit notes 본문
notes_en = <<~NOTES.strip
  Thank you for the previous Guideline 4.3(a) feedback on build 76. We have substantially updated this submission (build 77):

  1) ROUTING CHANGE — After a user enters their birth date, the app now opens onto the "More" tab. This tab surfaces our K-pop celebrity charts, original past-life web-novel series, music pharmacy, and K-pop compatibility tools. This is now the first surface a reviewer sees after onboarding.

  2) APP NAME / SUBTITLE — Updated to reflect the actual primary content:
     - en-US: "Pillarseer - K-pop Charts" / "K-pop Idol Charts & Stories"
     - ko: "필러시어 - 최애의 사주" / "K-pop 아이돌 차트 · 셀럽 203명"
     (was: "Pillar Seer - Saju Fortune" / "Daily fortune & Four Pillars")

  3) CATEGORY — changed from Lifestyle to Entertainment (primary) / Lifestyle (secondary).

  4) DESCRIPTION & KEYWORDS — rewritten to lead with K-pop celebrity content, 66-episode past-life fiction series, music pharmacy, and K-pop compatibility. Korean cultural framework (Saju) is now supporting context only.

  WHAT THE APP CONTAINS (original, not duplicating saturated category):
  - 203 K-pop idols with publicly known birth dates from Korean Wikipedia, each mapped to a traditional Korean day-pillar chart.
  - 31 in-depth long-form celebrity readings (written and curated).
  - 66 hand-written past-life episodes in Korean web-novel format + 66 English equivalents (132 original fiction stories).
  - Music Pharmacy: curated K-pop and OST song prescriptions matched to user personality.
  - K-pop Compatibility tool (user vs. idol day-pillar comparison).
  - One-time premium pack ($4.99 / KRW 5,900), no subscription.

  We respectfully ask the review team to evaluate the "More" tab (the first surface after onboarding) and verify the content is distinct from the saturated horoscope/astrology/fortune-telling category targeted by Guideline 4.3(a).

  TEST CREDENTIALS: not required — no sign-up or login. After enter birth date, the app opens the "More" tab. Tap "최애의 사주 (My Favorite's Chart)" to see the K-pop celebrity feature. Tap "전생 (Past Life)" to see the 66-episode original fiction.

  Thank you for your time.
NOTES

# 3. PATCH notes
c, b = api(:patch, "/v1/appStoreReviewDetails/#{detail_id}", {
  data: {
    type: 'appStoreReviewDetails',
    id: detail_id,
    attributes: {
      notes: notes_en,
      contactFirstName: 'Seunghyeon',
      contactLastName: 'Lee',
      contactPhone: '+821000000000',
      contactEmail: 'dorisurararara@gmail.com',
    }
  }
})
ok = c.to_i == 200
puts "\nPATCH notes HTTP #{c}  #{ok ? '✅' : '❌'}"
puts "  body=#{b[0..400]}" unless ok
