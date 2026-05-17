// Pillar Seer — World Cities DB.
// R87 sprint 3 — 해외 출생지 지원 mandate. 한국 도시는 manseryeok_service.dart 의
// _cityLongitudes 유지 (fallback), 해외 ~150 주요 도시 DB 는 여기로 분리.
//
// 각 entry 의 fields:
//  - id: lowercase ascii unique key (검색용 substring 매칭 동시 사용)
//  - ko: 한글 도시명 (사용자 입력 매칭)
//  - en: 영문 도시명
//  - country: ISO 국가명 (한글 1줄 helper 용)
//  - lat: 위도 (degrees north)
//  - lon: 경도 (degrees east, west 는 음수)
//  - standardMeridian: 그 나라/지역 표준시 자오선 (degrees east)
//    예: 한국 KST UTC+9 → 135°. 미국 EST UTC-5 → -75°. 중국 CST UTC+8 → 120°.
//    진태양시 보정 = (lon - standardMeridian) × 4분/도.
//  - iana: IANA timezone (예: 'Asia/Tokyo', 'America/New_York').
//    DST 자동 처리 위해 timezone 패키지 lookup 에 사용.

class WorldCity {
  final String id;
  final String ko;
  final String en;
  final String country;
  final double lat;
  final double lon;
  final double standardMeridian;
  final String iana;
  const WorldCity({
    required this.id,
    required this.ko,
    required this.en,
    required this.country,
    required this.lat,
    required this.lon,
    required this.standardMeridian,
    required this.iana,
  });

  /// 사용자 입력과 매칭 가능한 모든 토큰 (lowercase).
  List<String> get matchTokens => [
        id,
        ko,
        en.toLowerCase(),
      ];

  /// "도쿄 · 일본" / "Tokyo · Japan" 형태 helper 라벨.
  String labeled(bool useKo) =>
      useKo ? '$ko · $country' : '$en · ${_enCountry()}';

  String _enCountry() {
    // 간단 매핑. 자주 쓰이는 것만. fallback = country 원문.
    const m = {
      '일본': 'Japan',
      '중국': 'China',
      '대만': 'Taiwan',
      '홍콩': 'Hong Kong',
      '베트남': 'Vietnam',
      '태국': 'Thailand',
      '필리핀': 'Philippines',
      '인도네시아': 'Indonesia',
      '말레이시아': 'Malaysia',
      '싱가포르': 'Singapore',
      '인도': 'India',
      '아랍에미리트': 'UAE',
      '터키': 'Türkiye',
      '이스라엘': 'Israel',
      '영국': 'United Kingdom',
      '프랑스': 'France',
      '독일': 'Germany',
      '스페인': 'Spain',
      '이탈리아': 'Italy',
      '네덜란드': 'Netherlands',
      '벨기에': 'Belgium',
      '스위스': 'Switzerland',
      '오스트리아': 'Austria',
      '체코': 'Czechia',
      '폴란드': 'Poland',
      '러시아': 'Russia',
      '아일랜드': 'Ireland',
      '스웨덴': 'Sweden',
      '덴마크': 'Denmark',
      '노르웨이': 'Norway',
      '핀란드': 'Finland',
      '포르투갈': 'Portugal',
      '그리스': 'Greece',
      '헝가리': 'Hungary',
      '미국': 'United States',
      '캐나다': 'Canada',
      '멕시코': 'Mexico',
      '브라질': 'Brazil',
      '아르헨티나': 'Argentina',
      '칠레': 'Chile',
      '페루': 'Peru',
      '콜롬비아': 'Colombia',
      '호주': 'Australia',
      '뉴질랜드': 'New Zealand',
      '남아프리카': 'South Africa',
      '이집트': 'Egypt',
      '나이지리아': 'Nigeria',
      '케냐': 'Kenya',
      '에티오피아': 'Ethiopia',
      '모로코': 'Morocco',
    };
    return m[country] ?? country;
  }
}

class WorldCities {
  /// 핵심 글로벌 도시 ~150개. 한국 외 K-POP 팬덤·이민·유학 빈도 우선.
  /// 한국 도시는 [manseryeok_service._cityLongitudes] 에 별도 유지 (fallback).
  static const List<WorldCity> all = [
    // ── 일본 (UTC+9, JST, no DST since 1951) ──
    WorldCity(id: 'tokyo', ko: '도쿄', en: 'Tokyo', country: '일본', lat: 35.6762, lon: 139.6503, standardMeridian: 135.0, iana: 'Asia/Tokyo'),
    WorldCity(id: 'osaka', ko: '오사카', en: 'Osaka', country: '일본', lat: 34.6937, lon: 135.5023, standardMeridian: 135.0, iana: 'Asia/Tokyo'),
    WorldCity(id: 'kyoto', ko: '교토', en: 'Kyoto', country: '일본', lat: 35.0116, lon: 135.7681, standardMeridian: 135.0, iana: 'Asia/Tokyo'),
    WorldCity(id: 'yokohama', ko: '요코하마', en: 'Yokohama', country: '일본', lat: 35.4437, lon: 139.6380, standardMeridian: 135.0, iana: 'Asia/Tokyo'),
    WorldCity(id: 'nagoya', ko: '나고야', en: 'Nagoya', country: '일본', lat: 35.1815, lon: 136.9066, standardMeridian: 135.0, iana: 'Asia/Tokyo'),
    WorldCity(id: 'fukuoka', ko: '후쿠오카', en: 'Fukuoka', country: '일본', lat: 33.5904, lon: 130.4017, standardMeridian: 135.0, iana: 'Asia/Tokyo'),
    WorldCity(id: 'sapporo', ko: '삿포로', en: 'Sapporo', country: '일본', lat: 43.0618, lon: 141.3545, standardMeridian: 135.0, iana: 'Asia/Tokyo'),
    WorldCity(id: 'kobe', ko: '고베', en: 'Kobe', country: '일본', lat: 34.6901, lon: 135.1955, standardMeridian: 135.0, iana: 'Asia/Tokyo'),
    WorldCity(id: 'okinawa', ko: '오키나와', en: 'Okinawa', country: '일본', lat: 26.2125, lon: 127.6809, standardMeridian: 135.0, iana: 'Asia/Tokyo'),
    WorldCity(id: 'hiroshima', ko: '히로시마', en: 'Hiroshima', country: '일본', lat: 34.3853, lon: 132.4553, standardMeridian: 135.0, iana: 'Asia/Tokyo'),
    WorldCity(id: 'sendai', ko: '센다이', en: 'Sendai', country: '일본', lat: 38.2682, lon: 140.8694, standardMeridian: 135.0, iana: 'Asia/Tokyo'),

    // ── 중국 (UTC+8, CST, no DST. 표준시 자오선 120°E) ──
    WorldCity(id: 'beijing', ko: '베이징', en: 'Beijing', country: '중국', lat: 39.9042, lon: 116.4074, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'shanghai', ko: '상하이', en: 'Shanghai', country: '중국', lat: 31.2304, lon: 121.4737, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'guangzhou', ko: '광저우', en: 'Guangzhou', country: '중국', lat: 23.1291, lon: 113.2644, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'shenzhen', ko: '선전', en: 'Shenzhen', country: '중국', lat: 22.5431, lon: 114.0579, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'chengdu', ko: '청두', en: 'Chengdu', country: '중국', lat: 30.5728, lon: 104.0668, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'xian', ko: '시안', en: "Xi'an", country: '중국', lat: 34.3416, lon: 108.9398, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'hangzhou', ko: '항저우', en: 'Hangzhou', country: '중국', lat: 30.2741, lon: 120.1551, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'tianjin', ko: '톈진', en: 'Tianjin', country: '중국', lat: 39.3434, lon: 117.3616, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'qingdao', ko: '칭다오', en: 'Qingdao', country: '중국', lat: 36.0671, lon: 120.3826, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'dalian', ko: '다롄', en: 'Dalian', country: '중국', lat: 38.9140, lon: 121.6147, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'shenyang', ko: '선양', en: 'Shenyang', country: '중국', lat: 41.8057, lon: 123.4315, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'harbin', ko: '하얼빈', en: 'Harbin', country: '중국', lat: 45.8038, lon: 126.5350, standardMeridian: 120.0, iana: 'Asia/Shanghai'),
    WorldCity(id: 'hongkong', ko: '홍콩', en: 'Hong Kong', country: '홍콩', lat: 22.3193, lon: 114.1694, standardMeridian: 120.0, iana: 'Asia/Hong_Kong'),
    WorldCity(id: 'macau', ko: '마카오', en: 'Macau', country: '중국', lat: 22.1987, lon: 113.5439, standardMeridian: 120.0, iana: 'Asia/Macau'),
    WorldCity(id: 'taipei', ko: '타이베이', en: 'Taipei', country: '대만', lat: 25.0330, lon: 121.5654, standardMeridian: 120.0, iana: 'Asia/Taipei'),
    WorldCity(id: 'kaohsiung', ko: '가오슝', en: 'Kaohsiung', country: '대만', lat: 22.6273, lon: 120.3014, standardMeridian: 120.0, iana: 'Asia/Taipei'),

    // ── 동남아 (각국 UTC+7~+8) ──
    WorldCity(id: 'bangkok', ko: '방콕', en: 'Bangkok', country: '태국', lat: 13.7563, lon: 100.5018, standardMeridian: 105.0, iana: 'Asia/Bangkok'),
    WorldCity(id: 'chiangmai', ko: '치앙마이', en: 'Chiang Mai', country: '태국', lat: 18.7883, lon: 98.9853, standardMeridian: 105.0, iana: 'Asia/Bangkok'),
    WorldCity(id: 'hochiminh', ko: '호치민', en: 'Ho Chi Minh City', country: '베트남', lat: 10.8231, lon: 106.6297, standardMeridian: 105.0, iana: 'Asia/Ho_Chi_Minh'),
    WorldCity(id: 'hanoi', ko: '하노이', en: 'Hanoi', country: '베트남', lat: 21.0285, lon: 105.8542, standardMeridian: 105.0, iana: 'Asia/Ho_Chi_Minh'),
    WorldCity(id: 'jakarta', ko: '자카르타', en: 'Jakarta', country: '인도네시아', lat: -6.2088, lon: 106.8456, standardMeridian: 105.0, iana: 'Asia/Jakarta'),
    WorldCity(id: 'bali', ko: '발리', en: 'Bali', country: '인도네시아', lat: -8.4095, lon: 115.1889, standardMeridian: 120.0, iana: 'Asia/Makassar'),
    WorldCity(id: 'manila', ko: '마닐라', en: 'Manila', country: '필리핀', lat: 14.5995, lon: 120.9842, standardMeridian: 120.0, iana: 'Asia/Manila'),
    WorldCity(id: 'cebu', ko: '세부', en: 'Cebu', country: '필리핀', lat: 10.3157, lon: 123.8854, standardMeridian: 120.0, iana: 'Asia/Manila'),
    WorldCity(id: 'kualalumpur', ko: '쿠알라룸푸르', en: 'Kuala Lumpur', country: '말레이시아', lat: 3.1390, lon: 101.6869, standardMeridian: 120.0, iana: 'Asia/Kuala_Lumpur'),
    WorldCity(id: 'singapore', ko: '싱가포르', en: 'Singapore', country: '싱가포르', lat: 1.3521, lon: 103.8198, standardMeridian: 120.0, iana: 'Asia/Singapore'),
    WorldCity(id: 'phnompenh', ko: '프놈펜', en: 'Phnom Penh', country: '캄보디아', lat: 11.5564, lon: 104.9282, standardMeridian: 105.0, iana: 'Asia/Phnom_Penh'),
    WorldCity(id: 'yangon', ko: '양곤', en: 'Yangon', country: '미얀마', lat: 16.8409, lon: 96.1735, standardMeridian: 97.5, iana: 'Asia/Yangon'),
    WorldCity(id: 'vientiane', ko: '비엔티안', en: 'Vientiane', country: '라오스', lat: 17.9757, lon: 102.6331, standardMeridian: 105.0, iana: 'Asia/Vientiane'),

    // ── 인도 (UTC+5:30 → meridian 82.5°) ──
    WorldCity(id: 'newdelhi', ko: '뉴델리', en: 'New Delhi', country: '인도', lat: 28.6139, lon: 77.2090, standardMeridian: 82.5, iana: 'Asia/Kolkata'),
    WorldCity(id: 'mumbai', ko: '뭄바이', en: 'Mumbai', country: '인도', lat: 19.0760, lon: 72.8777, standardMeridian: 82.5, iana: 'Asia/Kolkata'),
    WorldCity(id: 'bangalore', ko: '벵갈루루', en: 'Bangalore', country: '인도', lat: 12.9716, lon: 77.5946, standardMeridian: 82.5, iana: 'Asia/Kolkata'),
    WorldCity(id: 'chennai', ko: '첸나이', en: 'Chennai', country: '인도', lat: 13.0827, lon: 80.2707, standardMeridian: 82.5, iana: 'Asia/Kolkata'),
    WorldCity(id: 'kolkata', ko: '콜카타', en: 'Kolkata', country: '인도', lat: 22.5726, lon: 88.3639, standardMeridian: 82.5, iana: 'Asia/Kolkata'),

    // ── 중동 (각국 UTC+2~+4) ──
    WorldCity(id: 'dubai', ko: '두바이', en: 'Dubai', country: '아랍에미리트', lat: 25.2048, lon: 55.2708, standardMeridian: 60.0, iana: 'Asia/Dubai'),
    WorldCity(id: 'abudhabi', ko: '아부다비', en: 'Abu Dhabi', country: '아랍에미리트', lat: 24.4539, lon: 54.3773, standardMeridian: 60.0, iana: 'Asia/Dubai'),
    WorldCity(id: 'istanbul', ko: '이스탄불', en: 'Istanbul', country: '터키', lat: 41.0082, lon: 28.9784, standardMeridian: 45.0, iana: 'Europe/Istanbul'),
    WorldCity(id: 'telaviv', ko: '텔아비브', en: 'Tel Aviv', country: '이스라엘', lat: 32.0853, lon: 34.7818, standardMeridian: 30.0, iana: 'Asia/Jerusalem'),
    WorldCity(id: 'jerusalem', ko: '예루살렘', en: 'Jerusalem', country: '이스라엘', lat: 31.7683, lon: 35.2137, standardMeridian: 30.0, iana: 'Asia/Jerusalem'),
    WorldCity(id: 'doha', ko: '도하', en: 'Doha', country: '카타르', lat: 25.2854, lon: 51.5310, standardMeridian: 45.0, iana: 'Asia/Qatar'),
    WorldCity(id: 'riyadh', ko: '리야드', en: 'Riyadh', country: '사우디아라비아', lat: 24.7136, lon: 46.6753, standardMeridian: 45.0, iana: 'Asia/Riyadh'),

    // ── 유럽 (대부분 DST 사용) ──
    WorldCity(id: 'london', ko: '런던', en: 'London', country: '영국', lat: 51.5074, lon: -0.1278, standardMeridian: 0.0, iana: 'Europe/London'),
    WorldCity(id: 'manchester', ko: '맨체스터', en: 'Manchester', country: '영국', lat: 53.4808, lon: -2.2426, standardMeridian: 0.0, iana: 'Europe/London'),
    WorldCity(id: 'edinburgh', ko: '에든버러', en: 'Edinburgh', country: '영국', lat: 55.9533, lon: -3.1883, standardMeridian: 0.0, iana: 'Europe/London'),
    WorldCity(id: 'dublin', ko: '더블린', en: 'Dublin', country: '아일랜드', lat: 53.3498, lon: -6.2603, standardMeridian: 0.0, iana: 'Europe/Dublin'),
    WorldCity(id: 'paris', ko: '파리', en: 'Paris', country: '프랑스', lat: 48.8566, lon: 2.3522, standardMeridian: 15.0, iana: 'Europe/Paris'),
    WorldCity(id: 'nice', ko: '니스', en: 'Nice', country: '프랑스', lat: 43.7102, lon: 7.2620, standardMeridian: 15.0, iana: 'Europe/Paris'),
    WorldCity(id: 'lyon', ko: '리옹', en: 'Lyon', country: '프랑스', lat: 45.7640, lon: 4.8357, standardMeridian: 15.0, iana: 'Europe/Paris'),
    WorldCity(id: 'berlin', ko: '베를린', en: 'Berlin', country: '독일', lat: 52.5200, lon: 13.4050, standardMeridian: 15.0, iana: 'Europe/Berlin'),
    WorldCity(id: 'munich', ko: '뮌헨', en: 'Munich', country: '독일', lat: 48.1351, lon: 11.5820, standardMeridian: 15.0, iana: 'Europe/Berlin'),
    WorldCity(id: 'frankfurt', ko: '프랑크푸르트', en: 'Frankfurt', country: '독일', lat: 50.1109, lon: 8.6821, standardMeridian: 15.0, iana: 'Europe/Berlin'),
    WorldCity(id: 'hamburg', ko: '함부르크', en: 'Hamburg', country: '독일', lat: 53.5511, lon: 9.9937, standardMeridian: 15.0, iana: 'Europe/Berlin'),
    WorldCity(id: 'madrid', ko: '마드리드', en: 'Madrid', country: '스페인', lat: 40.4168, lon: -3.7038, standardMeridian: 15.0, iana: 'Europe/Madrid'),
    WorldCity(id: 'barcelona', ko: '바르셀로나', en: 'Barcelona', country: '스페인', lat: 41.3851, lon: 2.1734, standardMeridian: 15.0, iana: 'Europe/Madrid'),
    WorldCity(id: 'rome', ko: '로마', en: 'Rome', country: '이탈리아', lat: 41.9028, lon: 12.4964, standardMeridian: 15.0, iana: 'Europe/Rome'),
    WorldCity(id: 'milan', ko: '밀라노', en: 'Milan', country: '이탈리아', lat: 45.4642, lon: 9.1900, standardMeridian: 15.0, iana: 'Europe/Rome'),
    WorldCity(id: 'florence', ko: '피렌체', en: 'Florence', country: '이탈리아', lat: 43.7696, lon: 11.2558, standardMeridian: 15.0, iana: 'Europe/Rome'),
    WorldCity(id: 'venice', ko: '베네치아', en: 'Venice', country: '이탈리아', lat: 45.4408, lon: 12.3155, standardMeridian: 15.0, iana: 'Europe/Rome'),
    WorldCity(id: 'amsterdam', ko: '암스테르담', en: 'Amsterdam', country: '네덜란드', lat: 52.3676, lon: 4.9041, standardMeridian: 15.0, iana: 'Europe/Amsterdam'),
    WorldCity(id: 'brussels', ko: '브뤼셀', en: 'Brussels', country: '벨기에', lat: 50.8503, lon: 4.3517, standardMeridian: 15.0, iana: 'Europe/Brussels'),
    WorldCity(id: 'zurich', ko: '취리히', en: 'Zurich', country: '스위스', lat: 47.3769, lon: 8.5417, standardMeridian: 15.0, iana: 'Europe/Zurich'),
    WorldCity(id: 'geneva', ko: '제네바', en: 'Geneva', country: '스위스', lat: 46.2044, lon: 6.1432, standardMeridian: 15.0, iana: 'Europe/Zurich'),
    WorldCity(id: 'vienna', ko: '비엔나', en: 'Vienna', country: '오스트리아', lat: 48.2082, lon: 16.3738, standardMeridian: 15.0, iana: 'Europe/Vienna'),
    WorldCity(id: 'prague', ko: '프라하', en: 'Prague', country: '체코', lat: 50.0755, lon: 14.4378, standardMeridian: 15.0, iana: 'Europe/Prague'),
    WorldCity(id: 'budapest', ko: '부다페스트', en: 'Budapest', country: '헝가리', lat: 47.4979, lon: 19.0402, standardMeridian: 15.0, iana: 'Europe/Budapest'),
    WorldCity(id: 'warsaw', ko: '바르샤바', en: 'Warsaw', country: '폴란드', lat: 52.2297, lon: 21.0122, standardMeridian: 15.0, iana: 'Europe/Warsaw'),
    WorldCity(id: 'stockholm', ko: '스톡홀름', en: 'Stockholm', country: '스웨덴', lat: 59.3293, lon: 18.0686, standardMeridian: 15.0, iana: 'Europe/Stockholm'),
    WorldCity(id: 'copenhagen', ko: '코펜하겐', en: 'Copenhagen', country: '덴마크', lat: 55.6761, lon: 12.5683, standardMeridian: 15.0, iana: 'Europe/Copenhagen'),
    WorldCity(id: 'oslo', ko: '오슬로', en: 'Oslo', country: '노르웨이', lat: 59.9139, lon: 10.7522, standardMeridian: 15.0, iana: 'Europe/Oslo'),
    WorldCity(id: 'helsinki', ko: '헬싱키', en: 'Helsinki', country: '핀란드', lat: 60.1699, lon: 24.9384, standardMeridian: 30.0, iana: 'Europe/Helsinki'),
    WorldCity(id: 'lisbon', ko: '리스본', en: 'Lisbon', country: '포르투갈', lat: 38.7223, lon: -9.1393, standardMeridian: 0.0, iana: 'Europe/Lisbon'),
    WorldCity(id: 'athens', ko: '아테네', en: 'Athens', country: '그리스', lat: 37.9838, lon: 23.7275, standardMeridian: 30.0, iana: 'Europe/Athens'),
    WorldCity(id: 'moscow', ko: '모스크바', en: 'Moscow', country: '러시아', lat: 55.7558, lon: 37.6173, standardMeridian: 45.0, iana: 'Europe/Moscow'),
    WorldCity(id: 'stpetersburg', ko: '상트페테르부르크', en: 'Saint Petersburg', country: '러시아', lat: 59.9311, lon: 30.3609, standardMeridian: 45.0, iana: 'Europe/Moscow'),

    // ── 북미 (미국·캐나다·멕시코, DST 사용) ──
    // 미국 동부 EST UTC-5 → meridian -75°
    WorldCity(id: 'newyork', ko: '뉴욕', en: 'New York', country: '미국', lat: 40.7128, lon: -74.0060, standardMeridian: -75.0, iana: 'America/New_York'),
    WorldCity(id: 'boston', ko: '보스턴', en: 'Boston', country: '미국', lat: 42.3601, lon: -71.0589, standardMeridian: -75.0, iana: 'America/New_York'),
    WorldCity(id: 'philadelphia', ko: '필라델피아', en: 'Philadelphia', country: '미국', lat: 39.9526, lon: -75.1652, standardMeridian: -75.0, iana: 'America/New_York'),
    WorldCity(id: 'washington', ko: '워싱턴', en: 'Washington', country: '미국', lat: 38.9072, lon: -77.0369, standardMeridian: -75.0, iana: 'America/New_York'),
    WorldCity(id: 'atlanta', ko: '애틀랜타', en: 'Atlanta', country: '미국', lat: 33.7490, lon: -84.3880, standardMeridian: -75.0, iana: 'America/New_York'),
    WorldCity(id: 'miami', ko: '마이애미', en: 'Miami', country: '미국', lat: 25.7617, lon: -80.1918, standardMeridian: -75.0, iana: 'America/New_York'),
    WorldCity(id: 'orlando', ko: '올랜도', en: 'Orlando', country: '미국', lat: 28.5383, lon: -81.3792, standardMeridian: -75.0, iana: 'America/New_York'),
    // CST UTC-6 → meridian -90°
    WorldCity(id: 'chicago', ko: '시카고', en: 'Chicago', country: '미국', lat: 41.8781, lon: -87.6298, standardMeridian: -90.0, iana: 'America/Chicago'),
    WorldCity(id: 'dallas', ko: '댈러스', en: 'Dallas', country: '미국', lat: 32.7767, lon: -96.7970, standardMeridian: -90.0, iana: 'America/Chicago'),
    WorldCity(id: 'houston', ko: '휴스턴', en: 'Houston', country: '미국', lat: 29.7604, lon: -95.3698, standardMeridian: -90.0, iana: 'America/Chicago'),
    WorldCity(id: 'austin', ko: '오스틴', en: 'Austin', country: '미국', lat: 30.2672, lon: -97.7431, standardMeridian: -90.0, iana: 'America/Chicago'),
    WorldCity(id: 'minneapolis', ko: '미니애폴리스', en: 'Minneapolis', country: '미국', lat: 44.9778, lon: -93.2650, standardMeridian: -90.0, iana: 'America/Chicago'),
    // MST UTC-7 → meridian -105°
    WorldCity(id: 'denver', ko: '덴버', en: 'Denver', country: '미국', lat: 39.7392, lon: -104.9903, standardMeridian: -105.0, iana: 'America/Denver'),
    WorldCity(id: 'phoenix', ko: '피닉스', en: 'Phoenix', country: '미국', lat: 33.4484, lon: -112.0740, standardMeridian: -105.0, iana: 'America/Phoenix'),
    WorldCity(id: 'saltlakecity', ko: '솔트레이크시티', en: 'Salt Lake City', country: '미국', lat: 40.7608, lon: -111.8910, standardMeridian: -105.0, iana: 'America/Denver'),
    // PST UTC-8 → meridian -120°
    WorldCity(id: 'losangeles', ko: '로스앤젤레스', en: 'Los Angeles', country: '미국', lat: 34.0522, lon: -118.2437, standardMeridian: -120.0, iana: 'America/Los_Angeles'),
    WorldCity(id: 'sanfrancisco', ko: '샌프란시스코', en: 'San Francisco', country: '미국', lat: 37.7749, lon: -122.4194, standardMeridian: -120.0, iana: 'America/Los_Angeles'),
    WorldCity(id: 'sandiego', ko: '샌디에이고', en: 'San Diego', country: '미국', lat: 32.7157, lon: -117.1611, standardMeridian: -120.0, iana: 'America/Los_Angeles'),
    WorldCity(id: 'seattle', ko: '시애틀', en: 'Seattle', country: '미국', lat: 47.6062, lon: -122.3321, standardMeridian: -120.0, iana: 'America/Los_Angeles'),
    WorldCity(id: 'portland', ko: '포틀랜드', en: 'Portland', country: '미국', lat: 45.5152, lon: -122.6784, standardMeridian: -120.0, iana: 'America/Los_Angeles'),
    WorldCity(id: 'lasvegas', ko: '라스베이거스', en: 'Las Vegas', country: '미국', lat: 36.1699, lon: -115.1398, standardMeridian: -120.0, iana: 'America/Los_Angeles'),
    // 하와이 UTC-10 (no DST)
    WorldCity(id: 'honolulu', ko: '호놀룰루', en: 'Honolulu', country: '미국', lat: 21.3099, lon: -157.8581, standardMeridian: -150.0, iana: 'Pacific/Honolulu'),
    // 알래스카 UTC-9
    WorldCity(id: 'anchorage', ko: '앵커리지', en: 'Anchorage', country: '미국', lat: 61.2181, lon: -149.9003, standardMeridian: -135.0, iana: 'America/Anchorage'),
    // 캐나다
    WorldCity(id: 'toronto', ko: '토론토', en: 'Toronto', country: '캐나다', lat: 43.6532, lon: -79.3832, standardMeridian: -75.0, iana: 'America/Toronto'),
    WorldCity(id: 'montreal', ko: '몬트리올', en: 'Montreal', country: '캐나다', lat: 45.5017, lon: -73.5673, standardMeridian: -75.0, iana: 'America/Montreal'),
    WorldCity(id: 'vancouver', ko: '밴쿠버', en: 'Vancouver', country: '캐나다', lat: 49.2827, lon: -123.1207, standardMeridian: -120.0, iana: 'America/Vancouver'),
    WorldCity(id: 'calgary', ko: '캘거리', en: 'Calgary', country: '캐나다', lat: 51.0447, lon: -114.0719, standardMeridian: -105.0, iana: 'America/Edmonton'),
    WorldCity(id: 'edmonton', ko: '에드먼턴', en: 'Edmonton', country: '캐나다', lat: 53.5461, lon: -113.4938, standardMeridian: -105.0, iana: 'America/Edmonton'),
    WorldCity(id: 'ottawa', ko: '오타와', en: 'Ottawa', country: '캐나다', lat: 45.4215, lon: -75.6972, standardMeridian: -75.0, iana: 'America/Toronto'),
    // 멕시코
    WorldCity(id: 'mexicocity', ko: '멕시코시티', en: 'Mexico City', country: '멕시코', lat: 19.4326, lon: -99.1332, standardMeridian: -90.0, iana: 'America/Mexico_City'),
    WorldCity(id: 'cancun', ko: '칸쿤', en: 'Cancun', country: '멕시코', lat: 21.1619, lon: -86.8515, standardMeridian: -75.0, iana: 'America/Cancun'),

    // ── 중남미 ──
    WorldCity(id: 'saopaulo', ko: '상파울로', en: 'São Paulo', country: '브라질', lat: -23.5505, lon: -46.6333, standardMeridian: -45.0, iana: 'America/Sao_Paulo'),
    WorldCity(id: 'riodejaneiro', ko: '리우데자네이루', en: 'Rio de Janeiro', country: '브라질', lat: -22.9068, lon: -43.1729, standardMeridian: -45.0, iana: 'America/Sao_Paulo'),
    WorldCity(id: 'buenosaires', ko: '부에노스아이레스', en: 'Buenos Aires', country: '아르헨티나', lat: -34.6037, lon: -58.3816, standardMeridian: -45.0, iana: 'America/Argentina/Buenos_Aires'),
    WorldCity(id: 'santiago', ko: '산티아고', en: 'Santiago', country: '칠레', lat: -33.4489, lon: -70.6693, standardMeridian: -60.0, iana: 'America/Santiago'),
    WorldCity(id: 'lima', ko: '리마', en: 'Lima', country: '페루', lat: -12.0464, lon: -77.0428, standardMeridian: -75.0, iana: 'America/Lima'),
    WorldCity(id: 'bogota', ko: '보고타', en: 'Bogota', country: '콜롬비아', lat: 4.7110, lon: -74.0721, standardMeridian: -75.0, iana: 'America/Bogota'),

    // ── 오세아니아 ──
    WorldCity(id: 'sydney', ko: '시드니', en: 'Sydney', country: '호주', lat: -33.8688, lon: 151.2093, standardMeridian: 150.0, iana: 'Australia/Sydney'),
    WorldCity(id: 'melbourne', ko: '멜버른', en: 'Melbourne', country: '호주', lat: -37.8136, lon: 144.9631, standardMeridian: 150.0, iana: 'Australia/Melbourne'),
    WorldCity(id: 'brisbane', ko: '브리즈번', en: 'Brisbane', country: '호주', lat: -27.4698, lon: 153.0251, standardMeridian: 150.0, iana: 'Australia/Brisbane'),
    WorldCity(id: 'perth', ko: '퍼스', en: 'Perth', country: '호주', lat: -31.9505, lon: 115.8605, standardMeridian: 120.0, iana: 'Australia/Perth'),
    WorldCity(id: 'adelaide', ko: '애들레이드', en: 'Adelaide', country: '호주', lat: -34.9285, lon: 138.6007, standardMeridian: 142.5, iana: 'Australia/Adelaide'),
    WorldCity(id: 'auckland', ko: '오클랜드', en: 'Auckland', country: '뉴질랜드', lat: -36.8485, lon: 174.7633, standardMeridian: 180.0, iana: 'Pacific/Auckland'),
    WorldCity(id: 'wellington', ko: '웰링턴', en: 'Wellington', country: '뉴질랜드', lat: -41.2865, lon: 174.7762, standardMeridian: 180.0, iana: 'Pacific/Auckland'),

    // ── 아프리카 ──
    WorldCity(id: 'cairo', ko: '카이로', en: 'Cairo', country: '이집트', lat: 30.0444, lon: 31.2357, standardMeridian: 30.0, iana: 'Africa/Cairo'),
    WorldCity(id: 'lagos', ko: '라고스', en: 'Lagos', country: '나이지리아', lat: 6.5244, lon: 3.3792, standardMeridian: 15.0, iana: 'Africa/Lagos'),
    WorldCity(id: 'nairobi', ko: '나이로비', en: 'Nairobi', country: '케냐', lat: -1.2921, lon: 36.8219, standardMeridian: 45.0, iana: 'Africa/Nairobi'),
    WorldCity(id: 'johannesburg', ko: '요하네스버그', en: 'Johannesburg', country: '남아프리카', lat: -26.2041, lon: 28.0473, standardMeridian: 30.0, iana: 'Africa/Johannesburg'),
    WorldCity(id: 'capetown', ko: '케이프타운', en: 'Cape Town', country: '남아프리카', lat: -33.9249, lon: 18.4241, standardMeridian: 30.0, iana: 'Africa/Johannesburg'),
    WorldCity(id: 'addis', ko: '아디스아바바', en: 'Addis Ababa', country: '에티오피아', lat: 9.0192, lon: 38.7525, standardMeridian: 45.0, iana: 'Africa/Addis_Ababa'),
    WorldCity(id: 'casablanca', ko: '카사블랑카', en: 'Casablanca', country: '모로코', lat: 33.5731, lon: -7.5898, standardMeridian: 0.0, iana: 'Africa/Casablanca'),
  ];

  /// 입력 query 와 매칭되는 도시 검색 (한글 / 영문 / id 모두).
  /// limit 결과 수 제한.
  static List<WorldCity> search(String query, {int limit = 12}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final hits = <WorldCity>[];
    for (final c in all) {
      bool match = false;
      for (final tok in c.matchTokens) {
        if (tok.toLowerCase().contains(q)) {
          match = true;
          break;
        }
      }
      // 국가 이름 substring 도 hit (예: '일본' → 도쿄/오사카 등)
      if (!match && c.country.toLowerCase().contains(q)) {
        match = true;
      }
      if (match) {
        hits.add(c);
        if (hits.length >= limit) break;
      }
    }
    return hits;
  }

  /// 도시 이름 / id 로 정확 매칭 (substring fallback 미포함).
  /// manseryeok_service 가 진태양시 계산할 때 사용.
  static WorldCity? findByName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final lower = name.trim().toLowerCase();
    for (final c in all) {
      for (final tok in c.matchTokens) {
        if (tok.toLowerCase() == lower) return c;
      }
    }
    // substring fallback (사용자가 "서울특별시" 같은 표현 입력 가능).
    for (final c in all) {
      for (final tok in c.matchTokens) {
        if (lower.contains(tok.toLowerCase()) ||
            tok.toLowerCase().contains(lower)) {
          return c;
        }
      }
    }
    return null;
  }
}
