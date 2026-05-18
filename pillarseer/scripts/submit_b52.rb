#!/usr/bin/env ruby
# Build #52 — R92: entry 단위 codex 9.9+ 목표 quality 정제 4 round
require_relative '_helpers'

BUILD_NO = 52

# 1. Build id
code, body = api(:get, "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=#{BUILD_NO}&limit=1")
b = JSON.parse(body)['data'].first
unless b
  puts "❌ Build ##{BUILD_NO} not found yet. (Apple processing 5~15분 대기 후 재시도)"
  exit 1
end
b_id = b['id']
state = b['attributes']['processingState']
puts "[Build ##{BUILD_NO} id=#{b_id} state=#{state}]"
if state != 'VALID'
  puts "⚠️  Not VALID yet (state=#{state}). Wait ASC processing."
  exit 0
end

# 2. localizations
code, body = api(:get, "/v1/builds/#{b_id}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
by_locale = {}
locs.each { |l| by_locale[l['attributes']['locale']] = l['id'] }
puts "  locales: #{by_locale.keys}"

# 3. whatsNew — R93 사용자 4 mandate 반영
ko_text = <<~KO.strip
  v1.0.0 Build ##{BUILD_NO} — R93 사용자 4 mandate

  스크린샷 보고 직접 받은 사용자 verbatim 4 mandate 반영:

  1. 더보기 탭 K-POP 케미 답변 = 진짜 연인 사주 톤으로 전환
     • "무대/팬싸/굿즈/직캠/컴백/플레이리스트/응원봉" K-POP 어휘 12종 0회
     • 사주 9 anchor (오행 + 일주/일지 동일 + 천간합 + 지지육합/삼합/충/형 + 점수) 기반 동적 합성
     • 88~143자 → 300~600자 확장, 셀럽 이름 직접 inject

  2. 궁합보기 화면 UI 키보드 직접 입력 전환
     • DatePicker / TimePicker 모달 제거
     • 본인 사주 입력처럼 4 TextField (YYYY · MM · DD + HHMM) + 자동 focus 이동

  3. 궁합 답변 길게 + 사주 anchor 깊은 분석 (오늘 사주 톤)
     • 1 anchor → 9 anchor 확장 + 각 섹션 ×2~3 길이
     • summary/attract/friction/actions 모두 동적 분기 (천간합 / 지지충 / 보완 구조 등)
     • 본문 400~600자 → 1000~2000자

  4. 신년운세 매우 긴 사주 anchor 기반 총평 추가
     • _AnnualSummary 새 섹션 (1500~2000자, 7 문단)
     • 일간 5행 vs 2026 火 관계 + 격국 + 용신/희신/기신 + 십신 강세 + 길흉 시기
     • unsin/점신/한경운세 벤치마크 후 long-form 800~1500자 권고 충족

  품질: flutter analyze 0 / flutter test 854/854 PASS / R71 가드 사용자
  mandate 역방향 → R93 가드 교체.

  Issues: dorisurararara@gmail.com
KO

en_text = <<~EN.strip
  v1.0.0 Build ##{BUILD_NO} — R93 four user-mandate updates

  1. More tab — K-POP chemistry verdict in real-partner saju tone
     • K-POP vocab (stage/fansign/photocard/fancam/comeback/playlist) all removed
     • 9 saju anchors (element / same-pillar / stem union / branch hap/triad/clash/punishment + score)
     • 88~143 char → 300~600 char with celeb name dynamic inject

  2. Compatibility input UI keyboard-direct
     • DatePicker / TimePicker removed
     • 4 TextField (YYYY · MM · DD + HHMM) like personal input, auto-focus jump

  3. Compatibility body expanded with saju anchor depth (today-saju tone)
     • 1 → 9 anchor, all sections ×2~3 length
     • summary/attract/friction/actions all dynamic-branch
     • Body 400~600 char → 1000~2000 char

  4. New Year fortune long-form annual summary
     • _AnnualSummary new section (1500~2000 char, 7 paragraphs)
     • Day-master element vs 2026 fire + gyeokguk + yongsin/huisin/gisin + top tenGod
     • unsin/jeomsin/hankyung benchmark — long-form 800~1500 char target met

  Quality: flutter analyze 0 / test 854/854 PASS.

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
                             relationships: {build: {data: {type: 'builds', id: b_id}}}}})
    puts "  POST #{locale}: HTTP #{code} (#{text.length} chars)"
  end
end

# 4. External group
puts "\n외부 그룹 할당..."
code, body = api(:post, "/v1/builds/#{b_id}/relationships/betaGroups",
                 {data: [{type: 'betaGroups', id: EXTERNAL_GROUP_ID}]})
puts "  HTTP #{code}"

# 5. Beta Review submit
sleep 3
puts "\nBeta Review 제출..."
code, body = api(:post, '/v1/betaAppReviewSubmissions',
                 {data: {type: 'betaAppReviewSubmissions',
                         relationships: {build: {data: {type: 'builds', id: b_id}}}}})
case code.to_i
when 201
  puts "  ✅ 제출 완료."
when 409
  puts "  ℹ️  이미 제출됨 (멱등)."
else
  puts "  FAIL HTTP #{code}: #{body[0..400]}"
end

puts "\n📱 Public link: #{PUBLIC_LINK}"
