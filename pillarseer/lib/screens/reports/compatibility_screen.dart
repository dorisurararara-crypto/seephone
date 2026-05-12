// Pillar Seer — Compatibility (궁합) Report.
// 두 사주의 오행 공명 + 일주 케미 → 점수 + verdict.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/saju_result.dart';
import '../../providers/saju_provider.dart';
import '../../services/saju_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';

class CompatibilityScreen extends ConsumerStatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  ConsumerState<CompatibilityScreen> createState() =>
      _CompatibilityScreenState();
}

class _CompatibilityScreenState extends ConsumerState<CompatibilityScreen> {
  final _partnerNameCtrl = TextEditingController();
  DateTime? _partnerDate;
  TimeOfDay? _partnerTime;
  bool _unknownTime = false;
  SajuResult? _partner;
  int? _score;
  String? _verdict;
  bool _loading = false;

  Future<void> _calculate() async {
    if (_partnerDate == null) return;
    setState(() {
      _loading = true;
    });
    final svc = SajuService();
    final time = _unknownTime
        ? const TimeOfDay(hour: 12, minute: 0)
        : (_partnerTime ?? const TimeOfDay(hour: 12, minute: 0));
    final partner = await svc.calculateSaju(
      year: _partnerDate!.year,
      month: _partnerDate!.month,
      day: _partnerDate!.day,
      hour: time.hour,
      minute: time.minute,
      isLunar: false,
      isMale: true, // 단순 매칭 점수에는 영향 X
      unknownTime: _unknownTime,
    );
    if (!mounted) return;
    final me = ref.read(sajuResultProvider);
    if (me == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final score = _scoreFor(me, partner);
    final l = AppL10n.of(context);
    final verdict = score >= 75
        ? l.compatVerdictHigh
        : score >= 50
            ? l.compatVerdictMid
            : l.compatVerdictLow;
    setState(() {
      _partner = partner;
      _score = score;
      _verdict = verdict;
      _loading = false;
    });
  }

  /// 오행 공명 + 일주 케미 단순 점수 (0-100).
  int _scoreFor(SajuResult me, SajuResult partner) {
    final myEl = me.dayPillar.chunGanElement;
    final ptEl = partner.dayPillar.chunGanElement;
    int base;
    const generates = {
      '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
    };
    const overcomes = {
      '木': '土', '土': '水', '水': '火', '火': '金', '金': '木',
    };
    if (myEl == ptEl) {
      base = 78; // 비화
    } else if (generates[myEl] == ptEl || generates[ptEl] == myEl) {
      base = 88; // 상생
    } else if (overcomes[myEl] == ptEl || overcomes[ptEl] == myEl) {
      base = 52; // 상극
    } else {
      base = 65;
    }
    // 오행 분포 보정 — 결핍을 채워주는 파트너면 가산
    if (me.elements.deficit == partner.elements.dominant) base += 8;
    if (partner.elements.deficit == me.elements.dominant) base += 4;
    // 동물 충 (충형파해) — 일지 12지 충
    const ji12clash = {
      '子': '午', '丑': '未', '寅': '申', '卯': '酉', '辰': '戌', '巳': '亥',
      '午': '子', '未': '丑', '申': '寅', '酉': '卯', '戌': '辰', '亥': '巳',
    };
    if (ji12clash[me.dayPillar.jiJi] == partner.dayPillar.jiJi) {
      base -= 12;
    }
    return base.clamp(15, 99);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final me = ref.watch(sajuResultProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.compatTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (me != null)
                _MyPillarCard(label: l.compatYouLabel, result: me),
              const SizedBox(height: 16),
              _PartnerInput(
                nameCtrl: _partnerNameCtrl,
                date: _partnerDate,
                time: _partnerTime,
                unknownTime: _unknownTime,
                onDate: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    initialDate: _partnerDate ?? DateTime(1995),
                  );
                  if (picked != null) {
                    setState(() => _partnerDate = picked);
                  }
                },
                onTime: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _partnerTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() => _partnerTime = picked);
                  }
                },
                onUnknownTime: (v) =>
                    setState(() => _unknownTime = v ?? false),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading || _partnerDate == null ? null : _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.celestialGold,
                  foregroundColor: AppColors.cosmicBlack,
                  minimumSize: const Size(double.infinity, 52),
                  disabledBackgroundColor:
                      AppColors.celestialGold.withValues(alpha: 0.3),
                ),
                child: Text(
                  l.compatCalculate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (_score != null) ...[
                const SizedBox(height: 24),
                _ScoreCard(
                  score: _score!,
                  verdict: _verdict ?? '',
                ),
                const SizedBox(height: 16),
                if (_partner != null) ...[
                  _ResonanceCard(me: me!, partner: _partner!),
                  const SizedBox(height: 12),
                  _CompatDetailCard(me: me, partner: _partner!),
                ],
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }
}

class _MyPillarCard extends StatelessWidget {
  final String label;
  final SajuResult result;
  const _MyPillarCard({required this.label, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderStrong),
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              color: AppColors.moonlightGray,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Builder(builder: (context) {
              final useKo =
                  (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') ==
                      'ko';
              final label = useKo
                  ? '${result.dayPillar.pairKoreanMeaning} · ${result.day60ji}'
                  : '${result.dayMasterName} · ${result.day60ji}';
              return Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.ghostlyWhite,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PartnerInput extends StatelessWidget {
  final TextEditingController nameCtrl;
  final DateTime? date;
  final TimeOfDay? time;
  final bool unknownTime;
  final VoidCallback onDate;
  final VoidCallback onTime;
  final ValueChanged<bool?> onUnknownTime;

  const _PartnerInput({
    required this.nameCtrl,
    required this.date,
    required this.time,
    required this.unknownTime,
    required this.onDate,
    required this.onTime,
    required this.onUnknownTime,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.compatEnterPartner,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.moonlightGray,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameCtrl,
            style: const TextStyle(color: AppColors.ghostlyWhite),
            decoration: InputDecoration(
              hintText: l.compatPartnerName,
              hintStyle:
                  const TextStyle(color: AppColors.fadedSilver, fontSize: 13),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.mysticViolet),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Field(
            icon: Icons.calendar_today_outlined,
            label: date == null
                ? l.inputBirthday
                : DateFormat('yyyy-MM-dd').format(date!),
            onTap: onDate,
          ),
          const SizedBox(height: 10),
          _Field(
            icon: Icons.schedule,
            label: time == null
                ? l.inputTime
                : time!.format(context),
            onTap: unknownTime ? null : onTime,
            disabled: unknownTime,
          ),
          Row(
            children: [
              Checkbox(
                value: unknownTime,
                onChanged: onUnknownTime,
                fillColor: WidgetStatePropertyAll(
                    AppColors.mysticViolet.withValues(alpha: 0.65)),
              ),
              Text(
                l.inputUnknownTime,
                style: const TextStyle(
                  color: AppColors.moonlightGray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  const _Field({
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.midnightPurple.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled
                ? AppColors.cardBorder.withValues(alpha: 0.45)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: disabled ? AppColors.fadedSilver : AppColors.mysticViolet,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: disabled
                      ? AppColors.fadedSilver
                      : AppColors.ghostlyWhite,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final String verdict;
  const _ScoreCard({required this.score, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStrong),
      ),
      child: Column(
        children: [
          Text(
            l.compatMatchScore.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.6,
              color: AppColors.moonlightGray,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.celestialGold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            verdict,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.ghostlyWhite,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResonanceCard extends StatelessWidget {
  final SajuResult me;
  final SajuResult partner;
  const _ResonanceCard({required this.me, required this.partner});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.compatPillarHeader.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              color: AppColors.moonlightGray,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Builder(builder: (context) {
            final useKo =
                (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') ==
                    'ko';
            String dmLabel(SajuResult r) => useKo
                ? '${r.dayPillar.pairKoreanMeaning} (${r.day60ji})'
                : '${r.dayMasterName} (${r.day60ji})';
            return _row(
                useKo ? '일간' : 'Day Master', dmLabel(me), dmLabel(partner));
          }),
          const SizedBox(height: 4),
          Builder(builder: (context) {
            final useKo =
                (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') ==
                    'ko';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(
                  l.resultDominant,
                  _elName(me.elements.dominant, useKo),
                  _elName(partner.elements.dominant, useKo),
                ),
                const SizedBox(height: 4),
                _row(
                  l.resultDeficit,
                  _elName(me.elements.deficit, useKo),
                  _elName(partner.elements.deficit, useKo),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _row(String label, String mine, String theirs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.moonlightGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              mine,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.ghostlyWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              theirs,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.moonlightGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _elName(String han, bool useKo) {
    if (useKo) {
      const koMap = {
        '木': '나무 (木)',
        '火': '불 (火)',
        '土': '흙 (土)',
        '金': '쇠 (金)',
        '水': '물 (水)',
      };
      return koMap[han] ?? han;
    }
    const enMap = {
      '木': 'Wood (木)',
      '火': 'Fire (火)',
      '土': 'Earth (土)',
      '金': 'Metal (金)',
      '水': 'Water (水)',
    };
    return enMap[han] ?? han;
  }
}

// ──────── 깊이 보강: 상생/상극 + 일지 충 + 추천 행동 카드 (codex Round 24 권고)

class _CompatDetailCard extends StatelessWidget {
  final SajuResult me;
  final SajuResult partner;
  const _CompatDetailCard({required this.me, required this.partner});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final analysis = _analyze(me, partner, useKo);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(useKo ? '관계의 결' : 'RELATIONSHIP TEXTURE'),
          const SizedBox(height: 10),
          Text(
            analysis.summary,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.ghostlyWhite,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 18),
          _label(useKo ? '끌리는 지점' : 'WHAT DRAWS YOU CLOSE'),
          const SizedBox(height: 8),
          Text(
            analysis.attract,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.ghostlyWhite,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 18),
          _label(useKo ? '부딪히는 지점' : 'WHERE FRICTION SHOWS'),
          const SizedBox(height: 8),
          Text(
            analysis.friction,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.ghostlyWhite,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 18),
          _label(useKo ? '함께 할 수 있는 것 3가지' : '3 ACTIONS TO TRY'),
          const SizedBox(height: 8),
          for (final action in analysis.actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: 8),
                    child: Icon(Icons.circle,
                        size: 6, color: AppColors.mysticViolet),
                  ),
                  Expanded(
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.ghostlyWhite,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.4,
          color: AppColors.moonlightGray,
          fontWeight: FontWeight.w800,
        ),
      );

  _CompatAnalysis _analyze(SajuResult me, SajuResult partner, bool useKo) {
    final myEl = me.dayPillar.chunGanElement;
    final ptEl = partner.dayPillar.chunGanElement;
    const generates = {
      '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
    };
    const overcomes = {
      '木': '土', '土': '水', '水': '火', '火': '金', '金': '木',
    };
    const ji12clash = {
      '子': '午', '丑': '未', '寅': '申', '卯': '酉', '辰': '戌', '巳': '亥',
      '午': '子', '未': '丑', '申': '寅', '酉': '卯', '戌': '辰', '亥': '巳',
    };
    final clash =
        ji12clash[me.dayPillar.jiJi] == partner.dayPillar.jiJi;
    final complementary =
        me.elements.deficit == partner.elements.dominant ||
            partner.elements.deficit == me.elements.dominant;

    String summary;
    String attract;
    String friction;
    List<String> actions;

    if (myEl == ptEl) {
      summary = useKo
          ? '같은 오행 결을 가진 사이예요. 처음 만남이 빠르게 편안해지지만, 같은 약점이 동시에 드러나기 쉽습니다.'
          : 'Same element grain. Comfort comes fast — but the same blind spots also surface at once.';
      attract = useKo
          ? '리듬·말투·결정 속도가 비슷해 설명 없이도 통하는 느낌이 큽니다.'
          : 'Rhythm, tone, and decision speed align — you read each other without explaining.';
      friction = useKo
          ? '결핍이 겹쳐 있어 한 사람이 약해진 순간 둘 다 같이 가라앉기 쉽습니다.'
          : 'Shared deficit means one person\'s dip pulls both down at the same time.';
    } else if (generates[myEl] == ptEl || generates[ptEl] == myEl) {
      summary = useKo
          ? '한쪽이 다른 쪽을 살리는 상생(相生) 관계예요. 시간이 갈수록 깊어지고, 서로의 결이 다듬어집니다.'
          : 'A nourishing (相生) bond — one element feeds the other. Depth compounds over time.';
      attract = useKo
          ? '서로 부족한 결을 자연스럽게 채워주고, 보호받는 느낌이 큽니다.'
          : 'You fill each other\'s gaps naturally; both feel quietly protected.';
      friction = useKo
          ? '한 사람이 계속 주기만 하면 균형이 깨질 수 있어요. 받는 쪽의 표현이 중요합니다.'
          : 'If one keeps giving, balance frays. The receiver\'s gratitude has to be visible.';
    } else if (overcomes[myEl] == ptEl || overcomes[ptEl] == myEl) {
      summary = useKo
          ? '한쪽이 다른 쪽을 누르는 상극(相剋) 관계입니다. 처음엔 자극이지만, 잘 다루면 둘 다 더 단단해집니다.'
          : 'A controlling (相剋) bond — friction is structural. Handled well, both grow tougher.';
      attract = useKo
          ? '서로 약점을 정확히 짚어주고, 끌어올려 주는 코치 같은 면이 강해요.'
          : 'You both name each other\'s weak spots cleanly — coach energy, not flatter energy.';
      friction = useKo
          ? '말의 톤이 한 단계만 높아져도 통제처럼 느껴질 수 있어요. 의도와 표현의 거리가 중요합니다.'
          : 'One notch sharper tone can read as control. Distance between intent and delivery is everything.';
    } else {
      summary = useKo
          ? '약한 상호작용 — 충돌도 적고 흥분도 적습니다. 의식적으로 관계의 결을 만들 때 의미가 생깁니다.'
          : 'Mild interaction — neither clash nor spark dominates. You build the texture deliberately.';
      attract = useKo
          ? '판단을 강요하지 않는 편안함이 매력입니다.'
          : 'A quiet comfort that doesn\'t demand alignment.';
      friction = useKo
          ? '서로 따로 살 수도 있는 관계라서 적극적인 신호가 없으면 거리감이 늘어요.'
          : 'You can drift apart easily — without active signals, distance grows.';
    }

    if (clash) {
      friction += useKo
          ? ' 일지 12지 충(沖)이 있어 결정·여행·이사 같은 큰 선택에서 의견이 엇갈리기 쉽습니다.'
          : ' Day-branch clash (沖) adds friction around big decisions — moving, travel, money.';
    }
    if (complementary) {
      attract += useKo
          ? ' 한쪽의 강한 기운이 다른 쪽의 결핍을 정확히 채우는 보완 구조도 있어요.'
          : ' One person\'s dominant element fills the other\'s deficit — true complementary fit.';
    }

    actions = useKo
        ? [
            '매주 한 가지 결정은 상대 의견을 먼저 듣고 정해보기.',
            '같은 약점이 보이는 날은 둘 중 한 명이 의식적으로 다른 행동 선택.',
            '서로의 결핍 오행이 무엇인지 카드로 공유하고, 그 기운을 보충하는 사소한 의식 (색·음식·장소) 한 가지 함께.',
          ]
        : [
            'Once a week, let the other go first on one real decision.',
            'On days when shared weak spots show, one of you intentionally picks the opposite move.',
            'Share each other\'s deficit element openly — pick one small ritual (color, food, place) that adds it together.',
          ];

    return _CompatAnalysis(
      summary: summary,
      attract: attract,
      friction: friction,
      actions: actions,
    );
  }
}

class _CompatAnalysis {
  final String summary;
  final String attract;
  final String friction;
  final List<String> actions;
  _CompatAnalysis({
    required this.summary,
    required this.attract,
    required this.friction,
    required this.actions,
  });
}
