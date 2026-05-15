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
  /// 5행 한자 → 한국어 자연어 (나무/불/흙/금/물). user-facing 본문에서
  /// `$dominant` (raw hanja) interpolation 대신 항상 본 매핑을 거쳐 노출.
  static const Map<String, String> _elKo = {
    '木': '나무',
    '火': '불',
    '土': '흙',
    '金': '금',
    '水': '물',
  };

  /// 사주 결과 + 자미두수 결과 → 공통 결론 3-5 개.
  static List<CrossMatch> find(SajuResult saju, ZiweiResult ziwei) {
    final out = <CrossMatch>[];

    final dayStem = saju.dayPillar.chunGan; // 甲乙丙丁戊己庚辛壬癸
    final dayJi = saju.dayPillar.jiJi;
    final dayStemEl = saju.dayPillar.chunGanElement; // 木火土金水
    final dominant = saju.elements.dominant;
    final domKo = _elKo[dominant] ?? '';

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
        topic: '중심 성향',
        topicEn: 'NATURE',
        sajuSide: '디테일에 예민하고 결이 깔끔한 타입',
        sajuSideEn: 'A precise, polished read with a sharp eye for fine detail.',
        ziweiSide: '깊게 봐도 같은 결 — 작은 차이를 잘 잡아내는 감각',
        ziweiSideEn: 'The deeper read underlines the same fine-detail instinct.',
        combinedKo: '꼼꼼하게 보는 눈이 강점이에요. 작은 차이도 잘 잡아내요.',
        combinedEn:
            'Your strength is a sharp eye. You catch the small differences others miss.',
      ));
    }
    // 甲/丙 + 자미·태양·칠살 → 리더십
    if ((dayStem == '甲' || dayStem == '丙') &&
        ming.majorStars.any((s) =>
            s.keyEn == 'ziwei' || s.keyEn == 'taiyang' || s.keyEn == 'qisha')) {
      out.add(const CrossMatch(
        topic: '중심 성향',
        topicEn: 'NATURE',
        sajuSide: '앞에 나서서 끌고 가는 결이 강한 타입',
        sajuSideEn:
            'A natural front-stepper who pulls others forward.',
        ziweiSide: '깊게 봐도 같은 결 — 타고난 카리스마',
        ziweiSideEn: 'The deeper read confirms an inborn charisma.',
        combinedKo: '사람을 모으고 끌어가는 힘이 있어요. 리더 자리가 자연스러운 타입.',
        combinedEn:
            'You gather people and pull them forward. A leadership seat suits you naturally.',
      ));
    }
    // 乙/卯/未 + 우필·좌보 → 보좌·조율
    final softSaju = dayStem == '乙' || dayJi == '卯' || dayJi == '未';
    if (softSaju && mingStars.any((n) => n == '우필' || n == '좌보')) {
      out.add(const CrossMatch(
        topic: '중심 성향',
        topicEn: 'NATURE',
        sajuSide: '겉은 무던해도 안은 부드럽고 사람 사이 조율을 잘하는 타입',
        sajuSideEn:
            'Soft on the inside and good at finding balance between people.',
        ziweiSide: '깊게 봐도 같은 결 — 사람 사이 균형을 자연스럽게 잡는 힘',
        ziweiSideEn:
            'The deeper read shows a strong supporting, mediating note.',
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
          sajuSide: '섬세하게 캐치하는 결이 강한 타입',
          sajuSideEn: 'A nature that picks up subtle signals before others do.',
          ziweiSide: '깊게 봐도 같은 결 — 말과 표현으로 분위기 잡는 힘',
          ziweiSideEn:
              'The deeper read carries the same strong speaking energy.',
          combinedKo: '말과 표현으로 사람을 끌어가는 쪽이 잘 맞아요. 발표, 영상, 덕질 콘텐츠, 팬계정 운영처럼 보여지는 활동에서 빛나요.',
          combinedEn:
              'Words and expression are your strength. You shine when you speak, present, or build visible content — videos, fan accounts, anything where your voice is heard.',
        ));
      }
      // 자미·태양·칠살 → 조직 리더
      if (has('ziwei') || has('taiyang') || has('qisha')) {
        final elKo = _elKo[dayStemEl] ?? '';
        out.add(CrossMatch(
          topic: '진로',
          topicEn: 'PATH',
          sajuSide: elKo.isNotEmpty
              ? '$elKo 기운이 강해서 앞에 서는 자리가 잘 어울려요'
              : '앞에 서는 자리가 자연스럽게 어울리는 타입',
          sajuSideEn:
              'Front-stage roles suit you well — the bigger the room, the better.',
          ziweiSide: '깊게 봐도 같은 결 — 사람 모으는 기질',
          ziweiSideEn:
              'The deeper read shows the same people-gathering pull.',
          combinedKo: '큰 자리를 맡을수록 빛나는 타입이에요. 무대 작은 데보단 큰 데서 살아나요.',
          combinedEn:
              'You shine more on a bigger stage. Small rooms dull you; big rooms light you up.',
        ));
      }
      // 천기·천량 → 기획·분석
      if (has('tianji') || has('tianliang')) {
        final elKo = _elKo[dayStemEl] ?? '';
        final isLight = dayStemEl == '木' || dayStemEl == '水';
        out.add(CrossMatch(
          topic: '진로',
          topicEn: 'PATH',
          sajuSide: isLight && elKo.isNotEmpty
              ? '$elKo 기운 — 머리 빠르고 분위기 잘 읽어요'
              : '판단이 차분하고 정확한 타입',
          sajuSideEn: isLight
              ? 'A fast mind that reads the room well.'
              : 'A nature that judges calmly and precisely.',
          ziweiSide: '깊게 봐도 같은 결 — 기획·분석에 잘 맞는 결',
          ziweiSideEn:
              'The deeper read favors planning and analysis.',
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
          sajuSideEn: 'A nature where the money path is visible to others.',
          ziweiSide: '깊게 봐도 같은 결 — 드러날수록 잘 풀리는 흐름',
          ziweiSideEn:
              'The deeper money read says the more visible you are, the better it flows.',
          combinedKo: '보여지는 활동을 할수록 기회가 더 잘 붙어요. 사람들 앞에 설수록 살아나는 타입이에요.',
          combinedEn:
              'Visible work brings more opportunity. The more people see you, the more you earn.',
        ));
      }
      if (has('wuqu') || has('tianfu')) {
        final isSteady = dominant == '土' || dominant == '金';
        out.add(CrossMatch(
          topic: '돈',
          topicEn: 'MONEY',
          sajuSide: isSteady && domKo.isNotEmpty
              ? '$domKo 기운이 안정적이라 차곡차곡 모으는 타입'
              : '꾸준히 쌓는 자산형',
          sajuSideEn: isSteady
              ? 'A steady accumulator who builds wealth in layers.'
              : 'A nature that builds assets slowly.',
          ziweiSide: '깊게 봐도 같은 결 — 안정적으로 쌓이는 돈 흐름',
          ziweiSideEn:
              'The deeper money read points to stable, steady wealth.',
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
          sajuSideEn: 'Quick, witty partners are the ones who find you.',
          ziweiSide: '깊게 봐도 같은 결 — 영리하고 재치 있는 인연',
          ziweiSideEn:
              'The deeper partner read brings clever, sharp companions.',
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
          ziweiSide: '깊게 봐도 같은 결 — 감수성이 풍부한 파트너',
          ziweiSideEn:
              'The deeper partner read points to an emotionally rich match.',
          combinedKo: '예민하고 다정한 사람과 합이 좋아요. 무뚝뚝한 타입은 오래 못 갑니다.',
          combinedEn:
              'Sensitive, warm partners fit you. A cold or blunt type will not last.',
        ));
      }
      if (has('tianfu') || has('tiantong')) {
        out.add(const CrossMatch(
          topic: '연애',
          topicEn: 'LOVE',
          sajuSide: '안정적인 관계를 원하는 타입',
          sajuSideEn: 'A nature that wants steady, secure relationships.',
          ziweiSide: '깊게 봐도 같은 결 — 든든하고 안정적인 파트너 인연',
          ziweiSideEn:
              'The deeper partner read brings dependable, anchored love.',
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
      final elKo = _elKo[dayStemEl] ?? '';
      out.add(CrossMatch(
        topic: '공부',
        topicEn: 'STUDY',
        sajuSide: elKo.isNotEmpty
            ? '$elKo 기운이 강해서 정리하고 외우는 힘이 좋아요'
            : '정리하고 외우는 힘이 좋은 타입',
        sajuSideEn:
            'A natural at organizing and memorizing what you learn.',
        ziweiSide: '깊게 봐도 같은 결 — 공부·글쓰기에 잘 맞는 결',
        ziweiSideEn:
            'The deeper read favors study and writing as a strength.',
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
        out.add(const CrossMatch(
          topic: '마음',
          topicEn: 'HEART',
          sajuSide: '겉은 단단해도 안은 섬세한 타입',
          sajuSideEn: 'A nature that looks tough outside but is delicate inside.',
          ziweiSide: '깊게 봐도 같은 결 — 안쪽 감수성이 풍부한 사람',
          ziweiSideEn: 'The deeper inner read is emotionally rich.',
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
      out.add(CrossMatch(
        topic: '변화',
        topicEn: 'CHANGE',
        sajuSide: domKo.isNotEmpty
            ? '$domKo 기운이 강해서 새로운 시작에 강해요'
            : '새로운 시작에 강한 타입',
        sajuSideEn:
            'A starter — you are strong at new beginnings.',
        ziweiSide: '깊게 봐도 같은 결 — 한 곳에 머물지 않는 개척자 결',
        ziweiSideEn:
            'The deeper read carries the same pioneer note.',
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
