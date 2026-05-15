#!/usr/bin/env ruby
# Build #40 — R82 + R83 통합 (사용자 9문제 + 외부 reviewer P0/P1 4 fix + P1 5 fix)
# R82 sprint 2~13 + R83 sprint 2~6 + 9 통합 / 698 test / 5행 골든 보존
require_relative '_helpers'

# 1. Build #40 id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=40&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts '❌ Build #40 not found yet. (Apple processing 5~15분 대기 후 재시도)'
  exit 1
end
b40_id = b['id']
state = b['attributes']['processingState']
puts "[Build #40 id=#{b40_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b40_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R82 + R83 통합 (≤500자 mandate)
ko_text = <<~KO.strip
  v1.0.0 Build #40 — R82+R83 통합. 사용자 9문제 + 외부 audit 9 fix.

  R82 fix (사용자 verbatim 9문제):
  • 내 사주 / 오늘 탭 완전 분리 (오늘 사건 카드 이동)
  • 60일주 한 줄 풀이 한자 어휘 일소 (벼린 칼 → 단단한데 말투는 부드러운)
  • 6각 라벨 친근 어휘 ("두 번 봐도 같이 잡힌 강점")
  • 12 결 풀이 라벨 옆 십신/용신 근거 1줄 설명
  • 한글 동물·일진·알림 호명 옆 사주 관계 1줄 wire
  • 결과 화면 접기 강화 (핵심 4 펼침 + 나머지 14 접힘)
  • 사주 본문 30 sample 어색 어휘 재작성

  R82 외부 audit fix:
  • 성별 "기타" silent 처리 → 보조 모달
  • 5행 라벨 "세력 분포 점수 (앱 기준)" + 평이 helper
  • Profile reset 확인 모달
  • 버전 표시 실제 빌드 번호 wire

  R83 P1 신뢰도 fix:
  • Settings → 사주 계산 기준 안내 페이지 신규
  • 셀럽 출생 시간 미상 라벨
  • 23시 자시 학파 입력 안내
  • 시간 모름 시 시주 흐림 + 안내
  • 용신 억부/조후/격국 3 분리 + 신뢰도 chip

  698 test PASS / 5행 골든 1995-10-27 男 17시 보존.
  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build #40 — R82+R83 unified (user 9 issues + external audit 9 fix).

  Screen / tabs:
  • My-chart / Today tabs fully separated
  • Result screen stronger collapse (4 expanded + rest collapsed)

  Body / labels:
  • Day-pillar one-liner hanja wiped
  • Life-12 cards show ten-gods/yongsin basis
  • Six-axis badge friendly label
  • Korean animal / day-pillar / notification context line
  • Five-element label → "Strength distribution score (app)"

  Trust:
  • New "How saju is calculated" info page
  • 23h jasi school input helper
  • Unknown-time hour-pillar dim + notice
  • Celebrity birth-time disclosure label
  • Yongsin split 3 ways + confidence chip
  • Gender "Other" modal / Profile reset confirm / dynamic version

  698 tests PASS / 1995-10-27 male 17h golden preserved.
  Issues: dorisurararara@gmail.com
EN

[['ko', ko_text], ['en-US', en_text]].each do |locale, text|
  loc_id = by_locale[locale]
  if loc_id
    code, body = api(:patch, "/v1/betaBuildLocalizations/#{loc_id}",
                     {data: {type: 'betaBuildLocalizations', id: loc_id,
                             attributes: {whatsNew: text}}})
    puts "  PATCH #{locale}: HTTP #{code} (#{text.length} chars)"
  else
    code, body = api(:post, '/v1/betaBuildLocalizations',
                     {data: {type: 'betaBuildLocalizations',
                             attributes: {locale: locale, whatsNew: text},
                             relationships: {build: {data: {type: 'builds', id: b40_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b40_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b40_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
