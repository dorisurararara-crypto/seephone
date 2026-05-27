#!/usr/bin/env ruby
# R111 — Apple 4.3(a) appeal: ASC 메타데이터 K-pop 셀럽 lead 로 재포지셔닝
require_relative '_helpers'

LOC_EN = 'c5d2f6cc-7c45-4e9b-bb94-e4a96f086b80'
LOC_KO = '7b4bd70c-1ee7-4773-bdb5-eaa36f9705c1'

# ─── English (en-US) ─────────────────────────────────────────────
en_subtitle = "K-pop Idol Charts & Stories"  # 27 chars (<=30)
en_keywords = "kpop,idol,bts,blackpink,aespa,celebrity,compatibility,fandom,saju,korean,culture,story,fiction"  # 99 chars
en_promo = "203 K-pop idol charts (wiki-verified) + 66 original past-life web-novel episodes. Chemistry with your bias, music prescriptions, more."  # 132 chars (<=170)
en_desc = <<~EN.strip
  Pillarseer is a K-pop fandom app — original celebrity charts, hand-written fiction, and curated music — built around a Korean cultural framework.

  ▶ My Favorite's Chart · 203 K-pop Idols
  IU, V (BTS), Jennie (BLACKPINK), Karina (aespa), and 199 more. Each idol's publicly known birth date is sourced from Korean Wikipedia and mapped to a traditional Korean day-pillar chart. Read your favorite's personality, compare chemistry with yours, and discover idols who share your pillar.

  ▶ Past-Life Series · 66 Original Web-Novel Episodes
  66 hand-written longform episodes in the format of Korean web fiction (인터넷소설). Tied to your day pillar, each episode tells you who you might have been in a past life — like reading a novel, one chapter at a time. 66 Korean episodes + 66 English episodes — 132 original fiction stories.

  ▶ Music Pharmacy — Personalized Song Prescriptions
  Curated K-pop and OST songs matched to your personality profile.

  ▶ K-pop Compatibility — You vs Your Bias
  Compare day pillars with K-pop idols. Where you align, where you differ, chemistry score.

  ▶ Korean Cultural Framework
  A 1,000-year-old Korean personality system (Saju / Four Pillars) explained in plain language — Ten Gods, Five Elements, structure charts — without the kanji wall.

  This is not a daily horoscope app. The main surfaces are K-pop celebrity content, original web-novel fiction, music curation, and a Korean cultural framework explainer.

  Monetization: one-time premium pack (no subscription). Free tier includes 5 categories + 1 past-life episode; premium unlocks 12 categories + all 66 episodes.
EN
en_whatsnew = <<~EN.strip
  This release repositions the app around its K-pop fandom and original fiction features:

  • New navigation: after birth date entry, the app now opens onto the "More" tab — your gateway to the K-pop celebrity charts, past-life episodes, music pharmacy, and K-pop compatibility tools.
  • 203 K-pop idol charts (wiki-verified), 31 in-depth idol readings.
  • 66 + 66 hand-written past-life episodes (Korean + English).
  • Premium pack: one-time $4.99, no subscription.
EN

# ─── Korean (ko) ─────────────────────────────────────────────────
ko_subtitle = "최애의 사주 · 셀럽 203명"  # 16 chars
ko_keywords = "케이팝,아이돌,셀럽,최애,궁합,방탄,블랙핑크,에스파,팬,웹소설,전생,사주,한국문화,음악추천"
ko_promo = "K-pop 아이돌 203명의 실제 사주 차트 + 인터넷소설 전생 66편. 최애와의 케미부터 음악 처방까지."
ko_desc = <<~KO.strip
  필러시어는 K-pop 팬을 위한 셀럽 사주 + 인터넷소설 앱입니다.

  ▶ 최애의 사주 · 셀럽 203명
  아이유, 뷔(BTS), 제니(BLACKPINK), 카리나(aespa) 등 K-pop 아이돌 203명의 실제 생년월일(위키 검증)을 기반으로 일주(日柱) 차트와 분석을 보여드려요. 최애의 성향, 너와의 케미, 같은 일주 셀럽 끼리 묶어보는 재미까지.

  ▶ 인터넷소설 전생 66편
  한국 웹소설 스타일로 직접 집필한 66편 장편 서사. 너의 사주 일주에 맞춰 "전생에 너는 누구였을까" 를 한 편 한 편 읽는 소설처럼 풀어드려요. 한국어 66편 + 영문 66편 — 총 132편의 오리지널 픽션 컨텐츠.

  ▶ 음악 처방 (Music Pharmacy)
  K-pop·OST 큐레이션. 너의 성향에 맞는 곡을 처방전처럼 알려드려요.

  ▶ 최애와의 케미 (K-pop Compatibility)
  너 vs 아이돌 일주 비교. 같은 점, 다른 점, 케미 점수.

  ▶ 한국 전통 문화 · 사주 입문
  부가 기능으로, 1000년 한국 전통의 사주(四柱) 개념을 십신·오행·격국·용신 등 한국 문화 키워드로 친절히 안내해요. 어려운 한자는 줄이고 일상 언어로.

  본 앱은 일반적인 일일 운세 앱이 아닙니다. K-pop 팬덤을 위한 셀럽 데이터 + 오리지널 서사 + 큐레이션 음악 + 한국 문화 입문이 메인 surface 입니다.

  수익 모델: 1회 결제 프리미엄 팩 (구독 X). 무료 5 카테고리 + 전생 1편, 프리미엄 12 카테고리 + 전생 66편.
KO
ko_whatsnew = <<~KO.strip
  이번 릴리스는 K-pop 팬덤·오리지널 서사 기능 중심으로 앱을 재포지셔닝했습니다:

  • 새 내비게이션: 생년월일 입력 직후 "더 보기" 탭이 첫 화면 — K-pop 셀럽 차트, 전생 에피소드, 음악 처방, K-pop 케미 도구가 한자리에.
  • K-pop 아이돌 203명 차트(위키 검증), 31편 심층 셀럽 분석.
  • 손으로 쓴 전생 66편 + 영문 66편.
  • 프리미엄팩: 1회 $4.99 / ₩5,900, 구독 X.
KO

def patch_loc(id, attrs, label)
  c, b = api(:patch, "/v1/appStoreVersionLocalizations/#{id}", {
    data: { type: 'appStoreVersionLocalizations', id: id, attributes: attrs }
  })
  ok = c.to_i == 200
  puts "  [#{label}] HTTP #{c}  #{ok ? '✅' : '❌'}"
  puts "    body=#{b[0..400]}" unless ok
  ok
end

puts "▶︎ PATCH en-US (appStoreVersionLocalization, whatsNew 제외) ..."
patch_loc(LOC_EN, {
  keywords: en_keywords,
  promotionalText: en_promo,
  description: en_desc,
}, 'en-US')

puts "▶︎ PATCH ko (appStoreVersionLocalization, whatsNew 제외) ..."
patch_loc(LOC_KO, {
  keywords: ko_keywords,
  promotionalText: ko_promo,
  description: ko_desc,
}, 'ko')

# whatsNew 은 새 build attach 직후 별도 patch (post-attach 단계에서)
File.write('/tmp/r111_whatsnew_en.txt', en_whatsnew)
File.write('/tmp/r111_whatsnew_ko.txt', ko_whatsnew)
puts "→ whatsNew 본문은 /tmp/r111_whatsnew_*.txt 에 저장. 새 build attach 후 patch."

# ─── App-level: primary category ─────────────────────────────────
# 현재 LIFESTYLE → ENTERTAINMENT 로 변경 시도
puts "\n▶︎ Category: LIFESTYLE → ENTERTAINMENT (primary)"
puts "(주의: 카테고리 변경은 별도 API. 실패 시 ASC 웹에서 수동 변경 필요.)"

c, b = api(:get, "/v1/apps/#{APP_ID}/appInfos")
infos = JSON.parse(b)['data']
if infos.empty?
  puts "  ❌ appInfos empty"
else
  info_id = infos.first['id']
  state = infos.first['attributes']['appStoreState']
  puts "  appInfo id=#{info_id} state=#{state}"

  # appInfos 의 카테고리 PATCH (READY_FOR_DISTRIBUTION/PREPARE 상태에서만)
  c2, b2 = api(:patch, "/v1/appInfos/#{info_id}", {
    data: {
      type: 'appInfos',
      id: info_id,
      relationships: {
        primaryCategory: { data: { type: 'appCategories', id: 'ENTERTAINMENT' } },
        secondaryCategory: { data: { type: 'appCategories', id: 'LIFESTYLE' } },
      }
    }
  })
  ok2 = c2.to_i == 200
  puts "  PATCH category HTTP #{c2}  #{ok2 ? '✅' : '❌'}"
  puts "    body=#{b2[0..400]}" unless ok2
end
