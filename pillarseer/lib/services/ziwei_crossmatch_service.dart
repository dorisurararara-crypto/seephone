// Pillar Seer — 사주 ↔ 자미두수 교차 일치 (Crossmatch) 서비스.
//
// 두 운명학(자평명리 + 자미두수)에서 **같은 결론** 이 나온 부분만 추려
// "신뢰도 가장 높은 핵심" 으로 보여준다. 이 앱의 차별점.
//
// 매칭 규칙 — 사주 일간(천간 5행 + 음양) + dominant 5행 + 일주 지지 ↔
// 자미두수 명궁/관록궁/부처궁/재백궁 의 주성·길성 key.

import '../models/saju_result.dart';
import 'ziwei_service.dart';

class CrossMatch {
  /// 주제 라벨 한글 (예: '본성', '진로', '연애', '돈', '공부').
  final String topic;

  /// 주제 라벨 영문 (UPPERCASE 노출).
  final String topicEn;

  /// 사주 근거 한 줄 한글.
  final String sajuSide;

  /// 사주 근거 한 줄 영문.
  final String sajuSideEn;

  /// 자미두수 근거 한 줄 한글 (Round 70 — 자미두수 별 이름 노출 X, 우회 표현).
  final String ziweiSide;

  /// 자미두수 근거 한 줄 영문.
  final String ziweiSideEn;

  /// 두 시스템 공통 풀이 한 문장 한글 (직설 친근 톤).
  final String combinedKo;

  /// 두 시스템 공통 풀이 한 문장 영문.
  final String combinedEn;

  const CrossMatch({
    required this.topic,
    required this.topicEn,
    required this.sajuSide,
    required this.sajuSideEn,
    required this.ziweiSide,
    required this.ziweiSideEn,
    required this.combinedKo,
    required this.combinedEn,
  });

  /// useKo flag → topic 라벨.
  String topicFor({required bool useKo}) => useKo ? topic : topicEn;

  /// useKo flag → 기본 흐름 (사주 측) 본문.
  String sajuSideFor({required bool useKo}) => useKo ? sajuSide : sajuSideEn;

  /// useKo flag → 깊은 흐름 (자미두수 측) 본문.
  String ziweiSideFor({required bool useKo}) => useKo ? ziweiSide : ziweiSideEn;

  /// useKo flag → 메인 결론.
  String combinedFor({required bool useKo}) => useKo ? combinedKo : combinedEn;
}

class ZiweiCrossmatchService {
  /// 사주 결과 + 자미두수 결과 → 공통 결론 3-5 개.
  static List<CrossMatch> find(SajuResult saju, ZiweiResult ziwei) {
    final out = <CrossMatch>[];

    final dayStem = saju.dayPillar.chunGan; // 甲乙丙丁戊己庚辛壬癸
    final dayJi = saju.dayPillar.jiJi;
    final dayStemEl = saju.dayPillar.chunGanElement; // 木火土金水
    final dominant = saju.elements.dominant;

    final mingStars = ziwei.mingPalace.allStarNamesKo;
    final ming = ziwei.mingPalace;
    final shen = ziwei.shenPalace;
    final guanrok = ziwei.gungByName('관록궁');
    final buchu = ziwei.gungByName('부처궁');
    final jaebaek = ziwei.gungByName('재백궁');
    final bokdok = ziwei.gungByName('복덕궁');

    // ─────────────────────────────────────────────
    // 1) 본성 — 일간 + 명궁 주성
    // ─────────────────────────────────────────────
    // 辛(신금: 정밀·세련·날카로움) + 문창 → 꼼꼼·정확
    if (dayStem == '辛' &&
        (mingStars.contains('문창') || mingStars.contains('문곡'))) {
      out.add(const CrossMatch(
        topic: '본성',
        topicEn: 'NATURE',
        sajuSide: '신(辛) 일간 — 정밀하고 깔끔한 감각',
        sajuSideEn: 'Xin (辛) day master — precise and clean instincts.',
        ziweiSide: '명궁에 문창·문곡 — 디테일을 잘 잡아내는 별',
        ziweiSideEn: 'The deep layer underlines fine-detail intelligence.',
        combinedKo: '꼼꼼하게 보는 눈이 강점이에요. 작은 차이도 잘 잡아내요.',
        combinedEn:
            'Your strength is a sharp eye. You catch the small differences others miss.',
      ));
    }
    // 甲/丙 + 자미·태양·칠살 → 리더십
    if ((dayStem == '甲' || dayStem == '丙') &&
        ming.majorStars.any((s) =>
            s.keyEn == 'ziwei' || s.keyEn == 'taiyang' || s.keyEn == 'qisha')) {
      final dayStemEn = dayStem == '甲' ? 'Jia (甲) wood' : 'Bing (丙) fire';
      out.add(CrossMatch(
        topic: '본성',
        topicEn: 'NATURE',
        sajuSide:
            '${dayStem == '甲' ? '갑목(甲)' : '병화(丙)'} 일간 — 앞에 서는 리더 기질',
        sajuSideEn: '$dayStemEn day master — a leader who steps forward.',
        ziweiSide: '명궁에 ${ming.majorStars.first.nameKo} — 타고난 카리스마',
        ziweiSideEn: 'The deep layer confirms inborn charisma.',
        combinedKo: '사람을 모으고 끌어가는 힘이 있어요. 리더 자리가 자연스러운 타입.',
        combinedEn:
            'You gather people and pull them forward. A leadership seat suits you naturally.',
      ));
    }
    // 乙/卯/未 + 우필·좌보 → 보좌·조율
    final softSaju = dayStem == '乙' || dayJi == '卯' || dayJi == '未';
    if (softSaju && mingStars.any((n) => n == '우필' || n == '좌보')) {
      final softEn = dayJi == '卯'
          ? 'Mao (卯) rabbit branch'
          : dayStem == '乙'
              ? 'Yi (乙) wood day master'
              : 'Wei (未) sheep branch';
      out.add(CrossMatch(
        topic: '본성',
        topicEn: 'NATURE',
        sajuSide:
            '${dayJi == '卯' ? '묘(卯) 토끼' : dayStem == '乙' ? '을목(乙)' : '미(未) 양'} — 부드럽고 조율 잘하는 성향',
        sajuSideEn: '$softEn — soft and good at finding balance.',
        ziweiSide:
            '명궁에 ${mingStars.contains('우필') ? '우필' : '좌보'} — 보좌·조율 능력 강함',
        ziweiSideEn: 'The deep layer shows strong supporter and mediator notes.',
        combinedKo: '안은 의외로 부드러운 타입이에요. 사람 사이 균형을 자연스럽게 잡아요.',
        combinedEn:
            'Inside, you are softer than people expect. You balance people around you with ease.',
      ));
    }

    // ─────────────────────────────────────────────
    // 2) 직업·진로 — 관록궁 주성 + 사주 dayStem 표현 능력
    // ─────────────────────────────────────────────
    if (guanrok != null) {
      bool has(String key) => guanrok.majorStars.any((s) => s.keyEn == key);
      // 거문 → 말·상담·강의
      if (has('jumen') && (dayStem == '辛' || dayStem == '癸' || dayStem == '己')) {
        out.add(const CrossMatch(
          topic: '진로',
          topicEn: 'PATH',
          sajuSide: '섬세하게 캐치하는 사주 타입',
          sajuSideEn: 'A chart that picks up subtle signals.',
          ziweiSide: '관록궁에 거문성 — 말로 분위기 잡는 힘',
          ziweiSideEn: 'The deep career layer carries strong speaking energy.',
          combinedKo: '말과 표현으로 사람을 끌어가는 쪽이 잘 맞아요. 발표, 영상, 덕질 콘텐츠, 팬계정 운영처럼 보여지는 활동에서 빛나요.',
          combinedEn:
              'Words and expression are your strength. You shine when you speak, present, or build visible content — videos, fan accounts, anything where your voice is heard.',
        ));
      }
      // 자미·태양·칠살 → 조직 리더
      if (has('ziwei') || has('taiyang') || has('qisha')) {
        final elKo = const {
          '木': '나무', '火': '불', '土': '흙', '金': '금', '水': '물'
        }[dayStemEl] ?? dayStemEl;
        final elEn = const {
          '木': 'wood', '火': 'fire', '土': 'earth', '金': 'metal', '水': 'water'
        }[dayStemEl] ?? dayStemEl;
        out.add(CrossMatch(
          topic: '진로',
          topicEn: 'PATH',
          sajuSide: '$elKo 기운이 강해서 앞에 서는 자리가 잘 어울려요',
          sajuSideEn:
              'Strong $elEn energy — front-stage roles suit you well.',
          ziweiSide: '관록궁에 ${guanrok.majorStars.first.nameKo} — 사람 모으는 기질',
          ziweiSideEn:
              'The deep career layer shows people-gathering charisma.',
          combinedKo: '큰 자리를 맡을수록 빛나는 타입이에요. 무대 작은 데보단 큰 데서 살아나요.',
          combinedEn:
              'You shine more on a bigger stage. Small rooms dull you; big rooms light you up.',
        ));
      }
      // 천기·천량 → 기획·분석
      if (has('tianji') || has('tianliang')) {
        final elKo = const {
          '木': '나무', '火': '불', '土': '흙', '金': '금', '水': '물'
        }[dayStemEl] ?? dayStemEl;
        final elEn = const {
          '木': 'wood', '火': 'fire', '土': 'earth', '金': 'metal', '水': 'water'
        }[dayStemEl] ?? dayStemEl;
        out.add(CrossMatch(
          topic: '진로',
          topicEn: 'PATH',
          sajuSide: dayStemEl == '木' || dayStemEl == '水'
              ? '$elKo 기운 — 머리 빠르고 분위기 잘 읽어요'
              : '판단이 차분하고 정확한 사주 타입',
          sajuSideEn: dayStemEl == '木' || dayStemEl == '水'
              ? '$elEn energy — fast mind, reads the room well.'
              : 'A chart that judges calmly and precisely.',
          ziweiSide: '관록궁에 ${guanrok.majorStars.first.nameKo} — 기획·분석에 잘 맞음',
          ziweiSideEn:
              'The deep career layer favors planning and analysis.',
          combinedKo: '기획하고 정리하는 쪽이 잘 맞아요. 큰 그림 그리는 일에서 살아나요.',
          combinedEn:
              'Planning and organizing suit you. You come alive on big-picture work.',
        ));
      }
    }

    // ─────────────────────────────────────────────
    // 3) 돈·재물 — 재백궁 + 사주 dominant 5행
    // ─────────────────────────────────────────────
    if (jaebaek != null) {
      bool has(String key) => jaebaek.majorStars.any((s) => s.keyEn == key);
      if (has('taiyang')) {
        out.add(const CrossMatch(
          topic: '돈',
          topicEn: 'MONEY',
          sajuSide: '돈 버는 방식이 눈에 잘 보이는 타입',
          sajuSideEn: 'A chart where the money path is visible to others.',
          ziweiSide: '재백궁에 태양성 — 드러날수록 잘 풀려요',
          ziweiSideEn:
              'The deep money layer says the more visible you are, the better it flows.',
          combinedKo: '보여지는 활동을 할수록 기회가 더 잘 붙어요. 사람들 앞에 설수록 살아나는 타입이에요.',
          combinedEn:
              'Visible work brings more opportunity. The more people see you, the more you earn.',
        ));
      }
      if (has('wuqu') || has('tianfu')) {
        final domEn = const {
          '木': 'wood', '火': 'fire', '土': 'earth', '金': 'metal', '水': 'water'
        }[dominant] ?? dominant;
        out.add(CrossMatch(
          topic: '돈',
          topicEn: 'MONEY',
          sajuSide: dominant == '土' || dominant == '金'
              ? '$dominant 의 기운 — 차곡차곡 모으는 타입'
              : '꾸준히 쌓는 자산형',
          sajuSideEn: dominant == '土' || dominant == '金'
              ? '$domEn dominant — a steady accumulator.'
              : 'A chart that builds assets slowly.',
          ziweiSide:
              '재백궁에 ${jaebaek.majorStars.first.nameKo} — 안정적인 재물',
          ziweiSideEn:
              'The deep money layer points to stable, steady wealth.',
          combinedKo: '한 번에 크게보다 꾸준히 모이는 형태예요. 자산형으로 가는 게 자연스러워요.',
          combinedEn:
              'Wealth comes step by step, not in one big hit. Building assets is your natural lane.',
        ));
      }
    }

    // ─────────────────────────────────────────────
    // 4) 연애·인연 — 부처궁 + 사주 일주 (timidity)
    // ─────────────────────────────────────────────
    if (buchu != null) {
      bool has(String key) => buchu.majorStars.any((s) => s.keyEn == key);
      if (has('tianji')) {
        out.add(const CrossMatch(
          topic: '연애',
          topicEn: 'LOVE',
          sajuSide: '머리 잘 돌아가는 사람이랑 인연이 잘 닿아요',
          sajuSideEn: 'Your chart attracts quick, witty partners.',
          ziweiSide: '부처궁에 천기성 — 영리하고 재치 있는 인연',
          ziweiSideEn:
              'The deep partner layer brings clever, sharp companions.',
          combinedKo: '대화가 잘 통하는, 빠릿한 사람이 잘 맞아요. 너무 무뚝뚝한 타입은 금방 답답해져요.',
          combinedEn:
              'You match best with people you can really talk to. A blunt or quiet partner gets tiring fast.',
        ));
      }
      if (has('taiyin')) {
        out.add(const CrossMatch(
          topic: '연애',
          topicEn: 'LOVE',
          sajuSide: '인연에서 부드럽고 섬세한 사람을 끌어당겨요',
          sajuSideEn: 'You draw in soft, sensitive partners.',
          ziweiSide: '부처궁에 태음성 — 감수성이 풍부한 파트너',
          ziweiSideEn:
              'The deep partner layer points to an emotionally rich match.',
          combinedKo: '예민하고 다정한 사람과 합이 좋아요. 무뚝뚝한 타입은 오래 못 갑니다.',
          combinedEn:
              'Sensitive, warm partners fit you. A cold or blunt type will not last.',
        ));
      }
      if (has('tianfu') || has('tiantong')) {
        out.add(CrossMatch(
          topic: '연애',
          topicEn: 'LOVE',
          sajuSide: '안정적인 관계를 원하는 타입',
          sajuSideEn: 'A chart that wants steady, secure relationships.',
          ziweiSide:
              '부처궁에 ${buchu.majorStars.first.nameKo} — 든든한 파트너 인연',
          ziweiSideEn:
              'The deep partner layer brings dependable, anchored love.',
          combinedKo: '뜨거운 사랑보다 오래 가는 사랑이 잘 맞아요. 안정형 파트너.',
          combinedEn:
              'You suit lasting love over fiery love. Look for the steady kind of partner.',
        ));
      }
    }

    // ─────────────────────────────────────────────
    // 5) 학문·디테일 — 명궁 문창/문곡 + 사주 정인·식신 톤
    // ─────────────────────────────────────────────
    if ((mingStars.contains('문창') || mingStars.contains('문곡')) &&
        (dayStem == '辛' || dayStem == '癸' || dayStemEl == '木')) {
      final elKo = const {
        '木': '나무', '火': '불', '土': '흙', '金': '금', '水': '물'
      }[dayStemEl] ?? dayStemEl;
      final elEn = const {
        '木': 'wood', '火': 'fire', '土': 'earth', '金': 'metal', '水': 'water'
      }[dayStemEl] ?? dayStemEl;
      out.add(CrossMatch(
        topic: '공부',
        topicEn: 'STUDY',
        sajuSide: '$elKo 기운이 강해서 정리하고 외우는 힘이 좋아요',
        sajuSideEn:
            'Strong $elEn energy — you organize and memorize well.',
        ziweiSide:
            '명궁에 ${mingStars.contains('문창') ? '문창' : '문곡'} — 공부·글쓰기에 잘 맞아요',
        ziweiSideEn:
            'The deep layer favors study and writing as a strength.',
        combinedKo: '시험, 수행평가, 글쓰기 쪽이 잘 풀려요. 노트 정리도 자연스럽게 잘하는 타입.',
        combinedEn:
            'Exams, papers, and writing all go well for you. Keeping clean notes comes naturally.',
      ));
    }

    // ─────────────────────────────────────────────
    // 6) 마음·감수성 — 복덕궁 + 사주 음간 부드러움
    // ─────────────────────────────────────────────
    if (bokdok != null) {
      bool has(String key) => bokdok.majorStars.any((s) => s.keyEn == key);
      if ((has('taiyin') || has('tiantong')) && softSaju) {
        out.add(CrossMatch(
          topic: '마음',
          topicEn: 'HEART',
          sajuSide: '겉은 단단해도 안은 섬세한 타입',
          sajuSideEn: 'A chart that looks tough outside but is delicate inside.',
          ziweiSide: '복덕궁에 ${bokdok.majorStars.first.nameKo} — 감수성이 풍부함',
          ziweiSideEn: 'The deep inner layer is emotionally rich.',
          combinedKo: '겉으로 잘 표현 안 해도 마음은 섬세해요. 혼자 회복하는 시간이 꼭 필요해요.',
          combinedEn:
              'You hide it well, but your inside is sensitive. Solo recovery time is a must, not a luxury.',
        ));
      }
    }

    // ─────────────────────────────────────────────
    // 7) 변화·개척 — 명궁/신궁 파군 + 사주 dominant 木/火
    // ─────────────────────────────────────────────
    final hasPojun = ming.majorStars.any((s) => s.keyEn == 'pojun') ||
        shen.majorStars.any((s) => s.keyEn == 'pojun');
    if (hasPojun && (dominant == '木' || dominant == '火')) {
      final domEn = const {
        '木': 'wood', '火': 'fire', '土': 'earth', '金': 'metal', '水': 'water'
      }[dominant] ?? dominant;
      out.add(CrossMatch(
        topic: '변화',
        topicEn: 'CHANGE',
        sajuSide: '$dominant 의 기운 — 새로운 시작에 강해요',
        sajuSideEn: '$domEn dominant — you are strong at new starts.',
        ziweiSide: '${ming.majorStars.any((s) => s.keyEn == 'pojun') ? '명궁' : '신궁'}에 파군성 — 개척자 타입',
        ziweiSideEn:
            'The deep layer carries a pioneer note in your core or outer self.',
        combinedKo: '한 곳에 고이지 않는 타입이에요. 변화가 오히려 기회로 작동합니다.',
        combinedEn:
            'You do not settle in one place. Change actually works as opportunity for you.',
      ));
    }

    // 결과 정제: 같은 주제 중복은 제거, 최대 5 개.
    final seen = <String>{};
    final filtered = <CrossMatch>[];
    for (final cm in out) {
      if (seen.add(cm.topic)) {
        filtered.add(cm);
      }
      if (filtered.length >= 5) break;
    }
    return filtered;
  }
}
