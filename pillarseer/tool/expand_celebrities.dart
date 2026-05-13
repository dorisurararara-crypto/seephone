// Tool — Add 30+ K-POP idol celebrities with auto-computed day pillars.
// Run: dart run tool/expand_celebrities.dart
// Output: prints JSON array merged with existing celebrities.json.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:klc/klc.dart';

const Map<String, String> _elemKo = {
  '甲': '큰 나무', '乙': '풀 나무', '丙': '태양 불', '丁': '촛불 불',
  '戊': '큰 흙', '己': '논흙', '庚': '강한 쇠', '辛': '작은 쇠',
  '壬': '큰 물', '癸': '비/이슬 물',
};
const Map<String, String> _animalKo = {
  '子': '쥐', '丑': '소', '寅': '호랑이', '卯': '토끼',
  '辰': '용', '巳': '뱀', '午': '말', '未': '양',
  '申': '원숭이', '酉': '닭', '戌': '개', '亥': '돼지',
};
const Map<String, String> _elemEn = {
  '甲': 'Wood', '乙': 'Wood', '丙': 'Fire', '丁': 'Fire',
  '戊': 'Earth', '己': 'Earth', '庚': 'Metal', '辛': 'Metal',
  '壬': 'Water', '癸': 'Water',
};
const Map<String, String> _animalEn = {
  '子': 'Rat', '丑': 'Ox', '寅': 'Tiger', '卯': 'Rabbit',
  '辰': 'Dragon', '巳': 'Snake', '午': 'Horse', '未': 'Goat',
  '申': 'Monkey', '酉': 'Rooster', '戌': 'Dog', '亥': 'Pig',
};

class NewCeleb {
  final String id;
  final String nameEn;
  final String nameKo;
  final String birth; // YYYY-MM-DD
  final String group; // e.g. "NewJeans" — used in blurb
  final String hintEn; // 1 hook line for English
  final String hintKo;
  NewCeleb(this.id, this.nameEn, this.nameKo, this.birth, this.group,
      this.hintEn, this.hintKo);
}

// Birthdays from public Wikipedia / official agency profiles.
final newCelebs = <NewCeleb>[
  // NewJeans
  NewCeleb('minji_njs', 'Minji (NewJeans)', '민지 (뉴진스)', '2004-05-07', 'NewJeans',
      "leader with a quiet confidence and elegant presence",
      "리더로서 조용한 자신감과 우아한 존재감"),
  NewCeleb('hanni_njs', 'Hanni (NewJeans)', '하니 (뉴진스)', '2004-10-06', 'NewJeans',
      "warm cosmopolitan smile that lifts every track",
      "따뜻한 코스모폴리탄 미소가 모든 곡을 띄우는"),
  NewCeleb('danielle_njs', 'Danielle (NewJeans)', '다니엘 (뉴진스)', '2005-04-11', 'NewJeans',
      "bilingual brightness with a soft-rebel edge",
      "이중언어의 밝음과 부드러운 반항의 결"),
  NewCeleb('haerin_njs', 'Haerin (NewJeans)', '해린 (뉴진스)', '2006-05-15', 'NewJeans',
      "feline mystery, the camera reads more than the line",
      "고양이 같은 신비, 카메라가 대사보다 더 많이 읽는"),
  NewCeleb('hyein_njs', 'Hyein (NewJeans)', '혜인 (뉴진스)', '2008-04-21', 'NewJeans',
      "the youngest with grown-up stage instincts",
      "최연소이지만 무대 위에서는 가장 어른의 본능"),
  // IVE
  NewCeleb('yujin_ive', 'Yujin (IVE)', '안유진 (아이브)', '2003-09-01', 'IVE',
      "leader who carries the room with a single beat",
      "한 박자만으로 무대를 휘어잡는 리더"),
  NewCeleb('gaeul_ive', 'Gaeul (IVE)', '가을 (아이브)', '2002-09-24', 'IVE',
      "sharp dancer whose stage edge cuts cleanly",
      "무대의 결이 깔끔하게 끊어지는 칼군무 댄서"),
  NewCeleb('rei_ive', 'Rei (IVE)', '레이 (아이브)', '2004-02-03', 'IVE',
      "Tokyo-born flow with a quiet rapper backbone",
      "도쿄 출신의 흐름, 조용한 래퍼의 뼈대"),
  NewCeleb('wonyoung_ive', 'Wonyoung (IVE)', '장원영 (아이브)', '2004-08-31', 'IVE',
      "luminous it-girl whose presence resets every photo line",
      "포토라인을 매번 리셋시키는 빛나는 잇걸"),
  NewCeleb('liz_ive', 'Liz (IVE)', '리즈 (아이브)', '2004-11-21', 'IVE',
      "main vocal whose tone floats above the mix",
      "믹스 위에 떠 있는 듯한 메인보컬의 톤"),
  NewCeleb('leeseo_ive', 'Leeseo (IVE)', '이서 (아이브)', '2007-02-21', 'IVE',
      "maknae with a polished doll-like aura",
      "잘 다듬어진 인형 같은 아우라의 막내"),
  // LE SSERAFIM
  NewCeleb('sakura_les', 'Sakura (LE SSERAFIM)', '사쿠라 (르세라핌)', '1998-03-19', 'LE SSERAFIM',
      "seasoned center whose two-nation career deepens every cut",
      "두 나라 활동으로 단단해진 베테랑 센터"),
  NewCeleb('chaewon_les', 'Chaewon (LE SSERAFIM)', '김채원 (르세라핌)', '2000-08-01', 'LE SSERAFIM',
      "leader voice with razor poise on stage",
      "면도날 같은 균형의 리더 보컬"),
  NewCeleb('kazuha_les', 'Kazuha (LE SSERAFIM)', '카즈하 (르세라핌)', '2003-08-09', 'LE SSERAFIM',
      "trained dancer turned idol — every line lands clean",
      "전공 댄서의 정확함이 한 마디마다 살아 있는"),
  NewCeleb('eunchae_les', 'Eunchae (LE SSERAFIM)', '홍은채 (르세라핌)', '2006-11-10', 'LE SSERAFIM',
      "the smile-energy maknae who turns chaos into camera magic",
      "혼란을 카메라 매직으로 바꾸는 미소 에너지 막내"),
  // ITZY
  NewCeleb('yeji_itzy', 'Yeji (ITZY)', '예지 (있지)', '2000-05-26', 'ITZY',
      "leader fox-eye intensity, dance line lead",
      "리더의 여우상 강렬함, 댄스 라인의 중심"),
  NewCeleb('lia_itzy', 'Lia (ITZY)', '리아 (있지)', '2000-07-21', 'ITZY',
      "honey-colored main vocal with a warm core",
      "꿀빛 메인보컬의 따뜻한 중심"),
  NewCeleb('ryujin_itzy', 'Ryujin (ITZY)', '류진 (있지)', '2001-04-17', 'ITZY',
      "fearless dance line presence",
      "두려움 없는 댄스 라인의 존재감"),
  NewCeleb('chaeryeong_itzy', 'Chaeryeong (ITZY)', '채령 (있지)', '2001-06-05', 'ITZY',
      "main dancer whose lines flow like ink",
      "잉크가 흐르듯 이어지는 메인댄서의 선"),
  NewCeleb('yuna_itzy', 'Yuna (ITZY)', '유나 (있지)', '2003-12-09', 'ITZY',
      "visual maknae with surprising vocal range",
      "예상 밖의 음역대를 가진 비주얼 막내"),
  // aespa
  NewCeleb('winter_aespa', 'Winter (aespa)', '윈터 (에스파)', '2001-01-01', 'aespa',
      "icy clean lead vocal with sharp expressions",
      "차가운 듯 깔끔한 리드 보컬과 또렷한 표정"),
  NewCeleb('giselle_aespa', 'Giselle (aespa)', '지젤 (에스파)', '2000-10-30', 'aespa',
      "tri-lingual rap line — Japanese-Korean-English",
      "일본어·한국어·영어 3개 국어 랩 라인"),
  NewCeleb('ningning_aespa', 'Ningning (aespa)', '닝닝 (에스파)', '2002-10-23', 'aespa',
      "main vocal powerhouse from China",
      "중국 출신 메인보컬 파워하우스"),
  // ENHYPEN
  NewCeleb('heeseung_eh', 'Heeseung (ENHYPEN)', '희승 (엔하이픈)', '2001-10-15', 'ENHYPEN',
      "main vocal trained for years before debut",
      "데뷔 전 오랜 훈련의 메인보컬"),
  NewCeleb('jay_eh', 'Jay (ENHYPEN)', '제이 (엔하이픈)', '2002-04-20', 'ENHYPEN',
      "bilingual main rapper with stage edge",
      "이중언어 메인 래퍼의 무대 엣지"),
  NewCeleb('jake_eh', 'Jake (ENHYPEN)', '제이크 (엔하이픈)', '2002-11-15', 'ENHYPEN',
      "Aussie-Korean charm with bright stage timing",
      "호주-한국 매력과 밝은 무대 타이밍"),
  NewCeleb('sunghoon_eh', 'Sunghoon (ENHYPEN)', '성훈 (엔하이픈)', '2002-12-08', 'ENHYPEN',
      "former figure skater with poised camera face",
      "전 피겨 선수 출신의 안정된 카메라 얼굴"),
  NewCeleb('sunoo_eh', 'Sunoo (ENHYPEN)', '선우 (엔하이픈)', '2003-06-24', 'ENHYPEN',
      "bright eye-smile melts the camera",
      "카메라를 녹이는 밝은 눈웃음"),
  NewCeleb('jungwon_eh', 'Jungwon (ENHYPEN)', '정원 (엔하이픈)', '2004-02-09', 'ENHYPEN',
      "youngest-leader paradox — quiet authority",
      "최연소 리더의 역설 — 조용한 권위"),
  NewCeleb('niki_eh', 'Niki (ENHYPEN)', '니키 (엔하이픈)', '2005-12-09', 'ENHYPEN',
      "youngest powerhouse dancer from Japan",
      "일본 출신 최연소 파워하우스 댄서"),
  // SEVENTEEN — popular picks
  NewCeleb('joshua_svt', 'Joshua (SEVENTEEN)', '조슈아 (세븐틴)', '1995-12-30', 'SEVENTEEN',
      "LA-born vocal — soft surface, deep musicality",
      "LA 출신 보컬 — 부드러운 표면 아래 깊은 음악성"),
  NewCeleb('mingyu_svt', 'Mingyu (SEVENTEEN)', '민규 (세븐틴)', '1997-04-06', 'SEVENTEEN',
      "tall visual rapper with kitchen-warmth aura",
      "주방 같은 따뜻함의 큰 키 비주얼 래퍼"),
  NewCeleb('vernon_svt', 'Vernon (SEVENTEEN)', '버논 (세븐틴)', '1998-02-18', 'SEVENTEEN',
      "Korean-American hip-hop pivot of the group",
      "그룹의 한국계 미국인 힙합 축"),
  NewCeleb('dk_svt', 'DK (SEVENTEEN)', '도겸 (세븐틴)', '1997-02-18', 'SEVENTEEN',
      "main vocal whose musical-theater belt soars",
      "뮤지컬 출신의 시원한 메인보컬 음역"),
  NewCeleb('woozi_svt', 'Woozi (SEVENTEEN)', '우지 (세븐틴)', '1996-11-22', 'SEVENTEEN',
      "producer-leader behind most of the discography",
      "디스코그래피의 대부분을 만드는 프로듀서-리더"),
  // TXT
  NewCeleb('yeonjun_txt', 'Yeonjun (TXT)', '연준 (투바투)', '1999-09-13', 'TXT',
      "main dancer with tigerish stage presence",
      "호랑이 같은 무대 존재감의 메인댄서"),
  NewCeleb('soobin_txt', 'Soobin (TXT)', '수빈 (투바투)', '2000-12-05', 'TXT',
      "bunny-leader with quiet vocal warmth",
      "토끼상 리더의 조용한 보컬 따뜻함"),
  NewCeleb('beomgyu_txt', 'Beomgyu (TXT)', '범규 (투바투)', '2001-03-13', 'TXT',
      "mood-maker guitar fan and clean vocal",
      "기타 팬이자 깔끔한 보컬의 분위기메이커"),
  NewCeleb('taehyun_txt', 'Taehyun (TXT)', '태현 (투바투)', '2002-02-05', 'TXT',
      "lead vocal with sharp ML-debate logic in interviews",
      "인터뷰에서 날카로운 논리를 보이는 리드보컬"),
  NewCeleb('huening_txt', 'Hueningkai (TXT)', '휴닝카이 (투바투)', '2002-08-14', 'TXT',
      "tri-cultural maknae main vocal — Hawaii-Korea-China",
      "하와이-한국-중국 3문화의 막내 메인보컬"),
  // RIIZE
  NewCeleb('wonbin_riize', 'Wonbin (RIIZE)', '원빈 (라이즈)', '2004-12-12', 'RIIZE',
      "visual all-rounder with k-drama-lead face",
      "K-드라마 주연감 얼굴의 비주얼 올라운더"),
  NewCeleb('anton_riize', 'Anton (RIIZE)', '안톤 (라이즈)', '2004-03-04', 'RIIZE',
      "Korean-American multi-instrumentalist maknae line",
      "한국계 미국인 멀티 악기 연주자 막내 라인"),
];

void main() async {
  final root = Directory.current;
  final celebPath = '${root.path}/assets/data/celebrities.json';
  final existing = jsonDecode(await File(celebPath).readAsString()) as List;
  final existingIds = existing.map((e) => (e as Map)['id']).toSet();

  final newEntries = <Map<String, dynamic>>[];
  for (final c in newCelebs) {
    if (existingIds.contains(c.id)) {
      print('skip dup: ${c.id}');
      continue;
    }
    final parts = c.birth.split('-').map(int.parse).toList();
    setSolarDate(parts[0], parts[1], parts[2]);
    final gapja = getChineseGapJaString();
    // "甲子年 乙丑月 丙寅日"
    final p = gapja.split(' ');
    final day = p[2];
    final chun = day[0];
    final ji = day[1];
    final dayPillar = '$chun$ji';
    final elemKo = _elemKo[chun] ?? '?';
    final animalKo = _animalKo[ji] ?? '?';
    final elemEn = _elemEn[chun] ?? '?';
    final animalEn = _animalEn[ji] ?? '?';
    final dayPillarName = '$elemEn $animalEn';
    final blurbEn =
        '${c.group} member ${c.nameEn.split(' (').first} — ${c.hintEn}. '
        'Day master $dayPillar ($dayPillarName) — $elemEn × $animalEn.';
    final blurbKo =
        '${c.group} ${c.nameKo.split(' (').first}. 일주 $dayPillar — '
        '$elemKo와 $animalKo띠 결합. ${c.hintKo} 결.';
    newEntries.add({
      'id': c.id,
      'nameEn': c.nameEn,
      'nameKo': c.nameKo,
      'kind': 'idol',
      'birth': c.birth,
      'dayPillar': dayPillar,
      'dayPillarName': dayPillarName,
      'blurbEn': blurbEn,
      'blurbKo': blurbKo,
    });
  }

  final merged = [...existing, ...newEntries];
  await File(celebPath).writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(merged)}\n');
  print('새 셀럽 추가: ${newEntries.length}');
  print('총 셀럽 수: ${merged.length}');
}
