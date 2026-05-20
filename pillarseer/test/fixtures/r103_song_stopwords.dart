// R103 Sprint 4 — celeb_songs.json 검증 fixtures.
//
// 사용자 mandate verbatim (1.0.0+63 실기기):
//   "사진 1,2 처럼 디지털 처방전 메뉴에는 없는 곡들이 너무 많아
//    이거 제대로 검증해서 올려야지"
//
// 본 fixture 는 R103 sprint 4 audit 후 confirmed fake / drama-title-leak /
// transliteration-nonsense 패턴을 lock. 회귀 가드 + 신규 entry 검증 용도.
//
// 정책:
//   - confirmedFakeTitles : 직접 검증된 fake (P0 OCR 2 + R103 P1 25)
//   - dramaStopwordsExtra : R102 stopword pool 외 추가 발견된 drama/영화 title
//   - placeholderArtistsExtra : R102 forbidden artist 외 추가 발견된 placeholder
//   - suspectTransliterationFragments : 본문에 자주 나타나는 의심 transliteration
//     단편 (R104 +α audit 시 sentinel)

/// 사용자 OCR 직발 + R103 sprint 4 audit 결과 확정된 fake titleKo 27개.
///
/// 본 set 의 title 이 celeb_songs.json 에 다시 등장하면 → 회귀 발생.
const Set<String> r103ConfirmedFakeTitles = <String>{
  // P0 OCR 직발 2
  '두 라이크 댓', // pharita_bm — BABYMONSTER catalog miss
  '샵 아저씨', // j_stayc — STAYC catalog miss
  // P1 transliteration fake — SEVENTEEN
  '러브 콜', // SVT / GIDLE 양쪽 fake
  '러브 스리 러브', // SVT
  // P1 — TXT
  // (taehyun_txt '러브 송' OK 곡명일 수 있어 본 set 제외)
  // P1 — NMIXX / GIDLE
  '씨 댓', // NMIXX
  '디지 댐 디지', // NMIXX → DICE 오기
  // P1 — ZB1
  '러브, 러브, 러브',
  '러브 인 더 무드',
  '필름 아웃', // ZB1 X (BTS 일본 곡)
  // P1 — BND
  '어스 위 워크', // → Earth, Wind & Fire mis-translit
  // P1 — TWS
  '오 마이 갓', // TWS 0 → Oh Mymy: 7s
  '플롯 인 러브', // TWS 0 → Plot Twist
  '이프 아이 머스트', // TWS 0
  // P1 — NCT DREAM
  '러브 잼', // NCT DREAM 0
  // P1 — KATSEYE
  '부 아이 러브 유',
  '디바', // KATSEYE 0
  // P1 — RV
  '러브 미 두',
  // P1 — solo
  '러브세이프티',
  // P1 — TREASURE
  // (asahi_trsr 러브 송은 다른 그룹곡으로 replace)
  // P2 — ILLIT
  '점핑 잭',
  '미드나잇 파이트',
  // P2 — XG
  '우드랜드',
  '샬라라',
  '프야 잇',
  '우 아',
  '그래 그래',
  '좀비',
  // P2 — KIOF
  '불러바드',
  '이그조틱',
  // P2 — P1Harmony
  '키리 키리',
  // P2 — TREASURE
  '호버링',
};

/// R102 drama stopword pool 외 추가 발견된 drama/영화/게임 title.
///
/// 본 audit 에서는 R102 set 만으로 leak 0건 — 신규 항목 0.
/// 향후 추가 발견 시 본 set 으로 확장.
const Set<String> r103DramaStopwordsExtra = <String>{
  // 신규 발견 시 추가
};

/// placeholder artist 라벨 R102 set 외 추가.
const Set<String> r103PlaceholderArtistsExtra = <String>{
  // 본 audit 에서는 R102 set 만으로 0건 — 신규 0
};

/// 의심 transliteration 단편 — sentinel 용 (R104+ 진단용, 본 sprint 회귀
/// 가드에는 직접 사용 X).
const Set<String> r103SuspectFragments = <String>{
  '러브 콜',
  '러브 송',
  '러브 잼',
  '러브 미',
  '디바',
  '씨 댓',
  '키리 키리',
  '아이 노',
  '러키 ',
  '오 마이 갓',
};
