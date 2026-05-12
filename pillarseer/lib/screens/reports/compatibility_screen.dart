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
                if (_partner != null)
                  _ResonanceCard(me: me!, partner: _partner!),
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
