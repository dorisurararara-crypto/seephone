// Pillar Seer — Compatibility (Aesop Luxury).
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
// 두 사주의 오행 공명 + 일주 케미 → 점수 + verdict + relationship texture.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // R93 sprint 3 — 사용자 mandate verbatim: "달력이랑 시계같은거 없애주고 키보드로 직접 치게"
  // input_screen.dart 와 같은 4 TextField (YYYY/MM/DD/HHMM) 패턴.
  final _yearCtl = TextEditingController();
  final _monthCtl = TextEditingController();
  final _dayCtl = TextEditingController();
  final _timeCtl = TextEditingController();
  final _yearFocus = FocusNode();
  final _monthFocus = FocusNode();
  final _dayFocus = FocusNode();
  final _timeFocus = FocusNode();
  DateTime? _partnerDate;
  TimeOfDay? _partnerTime;
  String? _dateError;
  String? _timeError;
  bool _unknownTime = false;
  SajuResult? _partner;
  int? _score;
  String? _verdict;
  bool _loading = false;
  // Round 77 sprint 7 — discover 모달 prefill 시 셀럽 이름 표시 chip.
  String? _prefilledFromCeleb;

  @override
  void dispose() {
    _partnerNameCtrl.dispose();
    _yearCtl.dispose();
    _monthCtl.dispose();
    _dayCtl.dispose();
    _timeCtl.dispose();
    _yearFocus.dispose();
    _monthFocus.dispose();
    _dayFocus.dispose();
    _timeFocus.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      final leap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return leap ? 29 : 28;
    }
    const month31 = {1, 3, 5, 7, 8, 10, 12};
    return month31.contains(month) ? 31 : 30;
  }

  void _recomputeDate() {
    final yt = _yearCtl.text;
    final mt = _monthCtl.text;
    final dt = _dayCtl.text;
    if (yt.length != 4 || mt.isEmpty || dt.isEmpty) {
      setState(() {
        _partnerDate = null;
        _dateError = null;
      });
      return;
    }
    final y = int.tryParse(yt);
    final m = int.tryParse(mt);
    final d = int.tryParse(dt);
    final nowYear = DateTime.now().year;
    if (y == null || m == null || d == null) {
      setState(() {
        _partnerDate = null;
        _dateError = '숫자만 적어줘.';
      });
      return;
    }
    if (y < 1900 || y > nowYear) {
      setState(() {
        _partnerDate = null;
        _dateError = '태어난 해는 1900~$nowYear 사이로 적어줘.';
      });
      return;
    }
    if (m < 1 || m > 12) {
      setState(() {
        _partnerDate = null;
        _dateError = '월은 1~12 중에 골라줘.';
      });
      return;
    }
    final maxDay = _daysInMonth(y, m);
    if (d < 1 || d > maxDay) {
      setState(() {
        _partnerDate = null;
        _dateError = '$m월은 $maxDay일까지 있어 — 그 안에서 골라줘.';
      });
      return;
    }
    setState(() {
      _partnerDate = DateTime(y, m, d);
      _dateError = null;
    });
  }

  void _recomputeTime() {
    if (_unknownTime) {
      setState(() {
        _partnerTime = null;
        _timeError = null;
      });
      return;
    }
    final raw = _timeCtl.text;
    if (raw.length < 4) {
      setState(() {
        _partnerTime = null;
        _timeError = null;
      });
      return;
    }
    final h = int.tryParse(raw.substring(0, 2));
    final m = int.tryParse(raw.substring(2, 4));
    if (h == null || m == null) {
      setState(() {
        _partnerTime = null;
        _timeError = '숫자만 적어줘.';
      });
      return;
    }
    if (h < 0 || h > 23) {
      setState(() {
        _partnerTime = null;
        _timeError = '시는 00~23 안에서 적어줘.';
      });
      return;
    }
    if (m < 0 || m > 59) {
      setState(() {
        _partnerTime = null;
        _timeError = '분은 00~59 안에서 적어줘.';
      });
      return;
    }
    setState(() {
      _partnerTime = TimeOfDay(hour: h, minute: m);
      _timeError = null;
    });
  }

  @override
  void initState() {
    super.initState();
    // initState 시 GoRouterState 접근 불가 → didChangeDependencies 에서 1회 prefill.
  }

  bool _prefillApplied = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefillApplied) return;
    _prefillApplied = true;
    // Round 77 sprint 7 — discover 모달 셀럽 prefill query 읽기.
    final qp = GoRouterState.of(context).uri.queryParameters;
    final pName = qp['partnerName'];
    final pBirth = qp['partnerBirth'];
    if (pName != null && pName.isNotEmpty) {
      _partnerNameCtrl.text = pName;
      _prefilledFromCeleb = pName;
    }
    if (pBirth != null && pBirth.isNotEmpty) {
      // pBirth 형식: 'YYYY-MM-DD' 또는 'YYYY-MM-DDTHH:MM' 등. 앞 10자만 사용.
      try {
        final iso = pBirth.length >= 10 ? pBirth.substring(0, 10) : pBirth;
        final parsed = DateTime.tryParse(iso);
        if (parsed != null) {
          _yearCtl.text = parsed.year.toString();
          _monthCtl.text = parsed.month.toString().padLeft(2, '0');
          _dayCtl.text = parsed.day.toString().padLeft(2, '0');
          _partnerDate = parsed;
          // 시간 모름 가정 — 셀럽 birth time 알 수 없음.
          _unknownTime = true;
        }
      } catch (_) {/* silent — prefill 실패해도 사용자 직접 입력 가능 */}
    }
    if (_prefilledFromCeleb != null) {
      setState(() {});
    }
  }

  Future<void> _calculate() async {
    if (_partnerDate == null) return;
    setState(() => _loading = true);
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
      isMale: true,
      unknownTime: _unknownTime,
    );
    if (!mounted) return;
    final me = ref.read(sajuResultProvider);
    if (me == null) {
      setState(() => _loading = false);
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
      base = 78;
    } else if (generates[myEl] == ptEl || generates[ptEl] == myEl) {
      base = 88;
    } else if (overcomes[myEl] == ptEl || overcomes[ptEl] == myEl) {
      base = 52;
    } else {
      base = 65;
    }
    if (me.elements.deficit == partner.elements.dominant) base += 8;
    if (partner.elements.deficit == me.elements.dominant) base += 4;
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
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.go('/reports'),
        ),
        title: Text(
          useKo ? '궁합 · 宮 合' : 'COMPATIBILITY · 宮 合',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 5,
            color: AppColors.ink,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (me != null) _PillarHero(label: 'YOU · 我', result: me),
            // Round 14 codex P1 — sample hint 폼 위에 노출 (첫 viewport)
            if (_score == null) _CompatExampleHint(useKo: useKo),
            // Round 77 sprint 7 — discover 모달 prefill 표시 chip.
            if (_prefilledFromCeleb != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  border: Border(
                      bottom: BorderSide(color: AppColors.line, width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.accent, width: 1),
                      ),
                      child: Text(
                        l.compatPrefilledTag.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _prefilledFromCeleb!,
                        style: GoogleFonts.notoSerifKr(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            _PartnerForm(
              nameCtrl: _partnerNameCtrl,
              yearCtl: _yearCtl,
              monthCtl: _monthCtl,
              dayCtl: _dayCtl,
              timeCtl: _timeCtl,
              yearFocus: _yearFocus,
              monthFocus: _monthFocus,
              dayFocus: _dayFocus,
              timeFocus: _timeFocus,
              dateError: _dateError,
              timeError: _timeError,
              hasDate: _partnerDate != null,
              hasTime: _partnerTime != null,
              unknownTime: _unknownTime,
              onYearChanged: (_) => _recomputeDate(),
              onMonthChanged: (_) => _recomputeDate(),
              onDayChanged: (_) => _recomputeDate(),
              onTimeChanged: (_) => _recomputeTime(),
              onUnknownTime: (v) {
                setState(() {
                  _unknownTime = v;
                  if (v) _timeCtl.clear();
                });
                _recomputeTime();
              },
              onSubmit: _loading ||
                      _partnerDate == null ||
                      (!_unknownTime && _partnerTime == null)
                  ? null
                  : _calculate,
              loading: _loading,
              submitLabel: l.compatCalculate,
            ),
            if (_score != null) ...[
              _ScoreSection(score: _score!, verdict: _verdict ?? ''),
              if (_partner != null && me != null) ...[
                _ResonanceSection(me: me, partner: _partner!),
                _DetailSection(me: me, partner: _partner!),
              ],
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }

  // R93 sprint 3 — _pickDate / _pickTime 제거 (사용자 mandate: 키보드 직접 입력).
}

class _PillarHero extends StatelessWidget {
  final String label;
  final SajuResult result;
  const _PillarHero({required this.label, required this.result});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.day60ji,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 34,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                  color: AppColors.accent,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  useKo
                      ? result.dayPillar.pairKoreanMeaning
                      : result.dayMasterName,
                  style: useKo
                      ? GoogleFonts.notoSerifKr(
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          color: AppColors.ink,
                          letterSpacing: 0.3,
                        )
                      : GoogleFonts.cormorantGaramond(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: AppColors.ink,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Round 13 codex P0 — 입력 전 hint (빈 화면 X)
class _CompatExampleHint extends StatelessWidget {
  final bool useKo;
  const _CompatExampleHint({required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useKo ? '결과 예시 · SAMPLE' : 'SAMPLE',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 22),
          // 샘플 점수 87 — 시각 예시
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '87',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  color: AppColors.accent.withValues(alpha: 0.4),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  useKo ? '점 / 100' : '/ 100',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.taupe,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(width: 36, height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          Text(
            useKo
                ? '"자력처럼 끌리는 결합 — 오행이 서로를 살리는 사이클."'
                : '"A magnetic alignment — your elements feed each other in cycles of growth."',
            style: GoogleFonts.notoSerifKr(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: AppColors.inkLight,
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            useKo
                ? '위는 샘플입니다. 상대방 생년월일을 입력하면 두 사람의 사주 일치율 + 끌림과 갈등 + 3가지 행동 제안을 받습니다.'
                : 'Sample shown above. Enter the other person\'s birth date to receive your match score, attraction/friction insights, and 3 actions.',
            style: GoogleFonts.notoSansKr(
              fontSize: 12.5,
              color: AppColors.taupe,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// R93 sprint 3 — _PartnerForm 키보드 직접 입력 패턴 (input_screen.dart 와 일관).
// 4 TextField (YYYY / MM / DD / HHMM) + 시간 모름 checkbox + 제출.
class _PartnerForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController yearCtl;
  final TextEditingController monthCtl;
  final TextEditingController dayCtl;
  final TextEditingController timeCtl;
  final FocusNode yearFocus;
  final FocusNode monthFocus;
  final FocusNode dayFocus;
  final FocusNode timeFocus;
  final String? dateError;
  final String? timeError;
  final bool hasDate;
  final bool hasTime;
  final bool unknownTime;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<String> onDayChanged;
  final ValueChanged<String> onTimeChanged;
  final ValueChanged<bool> onUnknownTime;
  final VoidCallback? onSubmit;
  final bool loading;
  final String submitLabel;

  const _PartnerForm({
    required this.nameCtrl,
    required this.yearCtl,
    required this.monthCtl,
    required this.dayCtl,
    required this.timeCtl,
    required this.yearFocus,
    required this.monthFocus,
    required this.dayFocus,
    required this.timeFocus,
    required this.dateError,
    required this.timeError,
    required this.hasDate,
    required this.hasTime,
    required this.unknownTime,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onDayChanged,
    required this.onTimeChanged,
    required this.onUnknownTime,
    required this.onSubmit,
    required this.loading,
    required this.submitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PARTNER · 對 象',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 20),
          _Label(l.compatPartnerName),
          TextField(
            controller: nameCtrl,
            style: GoogleFonts.notoSerifKr(
              fontSize: 18,
              color: AppColors.ink,
            ),
            cursorColor: AppColors.ink,
            decoration: _underlineDeco(),
          ),
          const SizedBox(height: 24),
          _Label(l.inputBirthday),
          // R93 sprint 3 — YYYY · MM · DD 3 TextField (input_screen.dart 패턴 일관).
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 4,
                child: _DigitField(
                  controller: yearCtl,
                  focusNode: yearFocus,
                  maxLength: 4,
                  hint: 'YYYY',
                  nextFocus: monthFocus,
                  onChanged: onYearChanged,
                ),
              ),
              const SizedBox(width: 10),
              Text('·',
                  style: GoogleFonts.notoSerifKr(
                      fontSize: 22,
                      color: AppColors.taupe,
                      fontWeight: FontWeight.w300)),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _DigitField(
                  controller: monthCtl,
                  focusNode: monthFocus,
                  maxLength: 2,
                  hint: 'MM',
                  nextFocus: dayFocus,
                  onChanged: onMonthChanged,
                ),
              ),
              const SizedBox(width: 10),
              Text('·',
                  style: GoogleFonts.notoSerifKr(
                      fontSize: 22,
                      color: AppColors.taupe,
                      fontWeight: FontWeight.w300)),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _DigitField(
                  controller: dayCtl,
                  focusNode: dayFocus,
                  maxLength: 2,
                  hint: 'DD',
                  nextFocus: timeFocus,
                  onChanged: onDayChanged,
                ),
              ),
            ],
          ),
          if (dateError != null) ...[
            const SizedBox(height: 8),
            Text(
              dateError!,
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: const Color(0xFFB14A3F),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _Label(l.inputTime),
          _DigitField(
            controller: timeCtl,
            focusNode: timeFocus,
            maxLength: 4,
            hint: 'HHMM (예: 1543)',
            nextFocus: null,
            enabled: !unknownTime,
            onChanged: onTimeChanged,
          ),
          if (timeError != null) ...[
            const SizedBox(height: 8),
            Text(
              timeError!,
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: const Color(0xFFB14A3F),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: unknownTime,
                  activeColor: AppColors.ink,
                  checkColor: AppColors.bg,
                  side: const BorderSide(color: AppColors.taupe),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                  onChanged: (v) => onUnknownTime(v ?? false),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l.inputUnknownTime.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 3,
                  color: AppColors.inkLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.bg,
                disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.3),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 22),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
                textStyle: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.bg, strokeWidth: 2),
                    )
                  : Text(submitLabel.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _underlineDeco() => InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        filled: false,
        border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.line)),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.line)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.ink, width: 1.2)),
      );
}

/// R93 sprint 3 — 숫자만 받는 underline TextField. maxLength 도달 시 다음 focus 자동 이동.
class _DigitField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final String hint;
  final FocusNode? nextFocus;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _DigitField({
    required this.controller,
    required this.focusNode,
    required this.maxLength,
    required this.hint,
    required this.nextFocus,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      style: GoogleFonts.notoSerifKr(
        fontSize: 22,
        color: enabled ? AppColors.ink : AppColors.taupe,
        fontWeight: FontWeight.w300,
        letterSpacing: 1.5,
      ),
      cursorColor: AppColors.ink,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        hintText: hint,
        hintStyle: GoogleFonts.notoSerifKr(
          fontSize: 16,
          color: AppColors.taupe,
          fontWeight: FontWeight.w300,
        ),
        filled: false,
        border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.line)),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.line)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.ink, width: 1.2)),
      ),
      onChanged: (v) {
        onChanged(v);
        if (v.length == maxLength && nextFocus != null) {
          nextFocus!.requestFocus();
        }
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          letterSpacing: 4,
          fontWeight: FontWeight.w500,
          color: AppColors.taupe,
        ),
      ),
    );
  }
}

class _ScoreSection extends StatelessWidget {
  final int score;
  final String verdict;
  const _ScoreSection({required this.score, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.compatMatchScore.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                  color: AppColors.accent,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '/100',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.taupe,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(width: 48, height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          Text(
            verdict,
            style: useKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: AppColors.ink,
                    height: 1.75,
                    letterSpacing: 0.3,
                  )
                : GoogleFonts.cormorantGaramond(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.ink,
                    height: 1.7,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResonanceSection extends StatelessWidget {
  final SajuResult me;
  final SajuResult partner;
  const _ResonanceSection({required this.me, required this.partner});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    String dmLabel(SajuResult r) => useKo
        ? '${r.dayPillar.pairKoreanMeaning} · ${r.day60ji}'
        : '${r.dayMasterName} · ${r.day60ji}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.compatPillarHeader.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 20),
          _row(useKo ? 'DAY MASTER · 日' : 'DAY MASTER · 日',
              dmLabel(me), dmLabel(partner)),
          _row(l.resultDominant,
              _elName(me.elements.dominant, useKo),
              _elName(partner.elements.dominant, useKo)),
          _row(l.resultDeficit,
              _elName(me.elements.deficit, useKo),
              _elName(partner.elements.deficit, useKo),
              isLast: true),
        ],
      ),
    );
  }

  Widget _row(String label, String mine, String theirs, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.line, width: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  mine,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  theirs,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 14,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _elName(String han, bool useKo) {
    if (useKo) {
      const koMap = {
        '木': '나무 (木)', '火': '불 (火)', '土': '흙 (土)',
        '金': '쇠 (金)', '水': '물 (水)',
      };
      return koMap[han] ?? han;
    }
    const enMap = {
      '木': 'Wood (木)', '火': 'Fire (火)', '土': 'Earth (土)',
      '金': 'Metal (金)', '水': 'Water (水)',
    };
    return enMap[han] ?? han;
  }
}

class _DetailSection extends StatelessWidget {
  final SajuResult me;
  final SajuResult partner;
  const _DetailSection({required this.me, required this.partner});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final a = _analyze(me, partner, useKo);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(useKo ? '관계의 무게 · TEXTURE' : 'RELATIONSHIP TEXTURE'),
          const SizedBox(height: 12),
          Text(
            a.summary,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.ink,
              height: 1.85,
            ),
          ),
          const SizedBox(height: 28),
          _sectionLabel(useKo ? '끌리는 지점 · ATTRACTS' : 'WHAT DRAWS YOU CLOSE'),
          const SizedBox(height: 10),
          Text(
            a.attract,
            style: GoogleFonts.notoSansKr(
              fontSize: 13.5,
              color: AppColors.ink,
              height: 1.85,
            ),
          ),
          const SizedBox(height: 28),
          _sectionLabel(useKo ? '부딪히는 지점 · FRICTION' : 'WHERE FRICTION SHOWS'),
          const SizedBox(height: 10),
          Text(
            a.friction,
            style: GoogleFonts.notoSansKr(
              fontSize: 13.5,
              color: AppColors.ink,
              height: 1.85,
            ),
          ),
          const SizedBox(height: 28),
          _sectionLabel(useKo ? '3 가지 실천 · ACTIONS' : '3 ACTIONS TO TRY'),
          const SizedBox(height: 10),
          for (final action in a.actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 10),
                    child: Container(
                      width: 4,
                      height: 4,
                      color: AppColors.accent,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      action,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13.5,
                        color: AppColors.ink,
                        height: 1.8,
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

  Widget _sectionLabel(String t) => Text(
        t.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          letterSpacing: 5,
          fontWeight: FontWeight.w500,
          color: AppColors.taupe,
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
    final clash = ji12clash[me.dayPillar.jiJi] == partner.dayPillar.jiJi;
    final complementary = me.elements.deficit == partner.elements.dominant ||
        partner.elements.deficit == me.elements.dominant;

    String summary;
    String attract;
    String friction;
    List<String> actions;

    if (myEl == ptEl) {
      summary = useKo
          ? '같은 오행 성질을 가진 사이예요. 처음 만남이 빠르게 편안해지지만, 같은 약점이 동시에 드러나기 쉽습니다.'
          : 'Same element vibe. Comfort comes fast — but the same blind spots also surface at once.';
      attract = useKo
          ? '리듬·말투·결정 속도가 비슷해 설명 없이도 통하는 느낌이 큽니다.'
          : 'Rhythm, tone, and decision speed align — you read each other without explaining.';
      friction = useKo
          ? '결핍이 겹쳐 있어 한 사람이 약해진 순간 둘 다 같이 가라앉기 쉽습니다.'
          : "Shared deficit means one person's dip pulls both down at the same time.";
    } else if (generates[myEl] == ptEl || generates[ptEl] == myEl) {
      summary = useKo
          ? '한쪽이 다른 쪽을 살리는 상생(相生) 관계예요. 시간이 갈수록 깊어지고, 서로의 모서리가 다듬어집니다.'
          : 'A nourishing (相生) bond — one element feeds the other. Depth compounds over time.';
      attract = useKo
          ? '서로 부족한 부분을 자연스럽게 채워주고, 보호받는 느낌이 큽니다.'
          : "You fill each other's gaps naturally; both feel quietly protected.";
      friction = useKo
          ? '한 사람이 계속 주기만 하면 균형이 깨질 수 있어요. 받는 쪽의 표현이 중요합니다.'
          : "If one keeps giving, balance frays. The receiver's gratitude has to be visible.";
    } else if (overcomes[myEl] == ptEl || overcomes[ptEl] == myEl) {
      summary = useKo
          ? '한쪽이 다른 쪽을 누르는 상극(相剋) 관계입니다. 처음엔 자극이지만, 잘 다루면 둘 다 더 단단해집니다.'
          : 'A controlling (相剋) bond — friction is structural. Handled well, both grow tougher.';
      attract = useKo
          ? '서로 약점을 정확히 짚어주고, 끌어올려 주는 코치 같은 면이 강해요.'
          : "You both name each other's weak spots cleanly — coach energy, not flatter energy.";
      friction = useKo
          ? '말의 톤이 한 단계만 높아져도 통제처럼 느껴질 수 있어요. 의도와 표현의 거리가 중요합니다.'
          : 'One notch sharper tone can read as control. Distance between intent and delivery is everything.';
    } else {
      summary = useKo
          ? '약한 상호작용 — 충돌도 적고 흥분도 적습니다. 의식적으로 관계의 무게를 만들 때 깊이가 생깁니다.'
          : 'Mild interaction — neither clash nor spark dominates. You build the texture deliberately.';
      attract = useKo
          ? '판단을 강요하지 않는 편안함이 매력입니다.'
          : "A quiet comfort that doesn't demand alignment.";
      friction = useKo
          ? '서로 따로 살 수도 있는 관계라서 적극적인 신호가 없으면 거리감이 늘어요.'
          : 'You can drift apart easily — without active signals, distance grows.';
    }

    if (clash) {
      friction += useKo
          ? ' 일주 띠끼리 충(沖)이 있어서 결정·여행·이사 같은 큰 선택에서 의견이 엇갈리기 쉬워요.'
          : ' Day-branch clash (沖) adds friction around big decisions.';
    }
    if (complementary) {
      attract += useKo
          ? ' 한쪽이 많이 가진 부분이 다른 쪽이 부족한 부분을 정확히 채우는 보완 구조도 있어요.'
          : " One person's dominant element fills the other's deficit.";
    }

    actions = useKo
        ? [
            '매주 한 가지 결정은 상대 의견을 먼저 듣고 정해보기.',
            '같은 약점이 보이는 날은 둘 중 한 명이 의식적으로 다른 행동 선택.',
            '서로 부족한 오행을 카드로 공유하고, 색·음식·장소 중 하나로 작게 챙겨보기.',
          ]
        : [
            'Once a week, let the other go first on one real decision.',
            'On days when shared weak spots show, one of you intentionally picks the opposite move.',
            "Share each other's deficit element openly — pick one small ritual together.",
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
