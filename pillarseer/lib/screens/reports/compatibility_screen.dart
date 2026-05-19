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
          _sectionLabel(useKo ? '연애·결혼·자녀 · LOVE & MARRIAGE' : 'LOVE · MARRIAGE · CHILDREN'),
          const SizedBox(height: 10),
          Text(
            a.loveMarriage,
            style: GoogleFonts.notoSansKr(
              fontSize: 13.5,
              color: AppColors.ink,
              height: 1.85,
            ),
          ),
          const SizedBox(height: 28),
          _sectionLabel(useKo ? '실천 · ACTIONS' : 'ACTIONS TO TRY'),
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

  // R94 sprint 4 — 사용자 mandate verbatim: "이와같이 중복된 패턴있으면 다 수정해".
  // 같은 element-relation 분기에서 두 사주가 달라도 summary/attract/friction 본문이 동일
  // 했던 hotspot. 이제 element pair (예: 木→火) / branch pair (예: 子午 충) 별 specific
  // scene 을 분기 본문 뒤에 추가. 두 사람 고유 8글자 anchor 가 본문에 드러나도록.
  _RelationshipAnchorProfile _relationshipAnchorProfile(
      SajuResult me, SajuResult partner) {
    final myGan = me.dayPillar.chunGan;
    final myJi = me.dayPillar.jiJi;
    final ptGan = partner.dayPillar.chunGan;
    final ptJi = partner.dayPillar.jiJi;
    final myEl = me.dayPillar.chunGanElement;
    final ptEl = partner.dayPillar.chunGanElement;
    return _RelationshipAnchorProfile(
      myGan: myGan,
      myJi: myJi,
      ptGan: ptGan,
      ptJi: ptJi,
      myEl: myEl,
      ptEl: ptEl,
      elementPair: '$myEl·$ptEl',
      elementFlow: '$myEl→$ptEl',
      branchPair: '$myJi·$ptJi',
      myDay60: me.day60ji,
      ptDay60: partner.day60ji,
    );
  }

  // ── element pair scene (오행 5×5 = 25 분기, 같은 element-relation 안에서 변별) ──
  String _elementPairSceneKo(_RelationshipAnchorProfile p) {
    final flow = p.elementFlow;
    const map = {
      // 비화 (같은 오행) — 5
      '木·木': '木·木 결은 봄 숲처럼 같이 자라는 자리. 둘 다 새로운 시작·여행·이직 같은 \'벌리는\' 자리를 좋아하지만, 한 번 끝낸 자리를 정리하는 결은 약해서 미완성 프로젝트가 둘 다 쌓이기 쉬워요.',
      '火·火': '火·火 결은 같은 화로 같이 타오르는 자리. 둘이 만나면 표현·즐거움·이벤트가 폭발하지만, 식는 자리도 같이 와서 잔잔한 일상을 유지하는 결이 약해요.',
      '土·土': '土·土 결은 같은 땅에 뿌리내린 자리. 약속·돈·집 같은 기반 결정에서 자연스럽게 합이 맞고 안정적이지만, 변화·모험·새 시도 앞에서는 둘 다 망설이는 자리가 자주 와요.',
      '金·金': '金·金 결은 같은 칼끝으로 닦이는 자리. 원칙·기준·정리 같은 자리에서 강하게 통하지만, 부드러운 감정 표현이 둘 다 어색해서 의식적으로 톤을 풀어주는 연습이 필요해요.',
      '水·水': '水·水 결은 같은 강물처럼 흐르는 자리. 깊은 대화·내면 탐색·창작 자리에서 가장 잘 통하지만, 결정 미루기·생각 과잉이 둘 다 와서 행동 트리거가 필요해요.',
      // 상생 5 — A→B 형태
      '木→火': '木→火 결은 나무가 불을 피우는 자리. 내가 한 마디 던지면 상대가 그걸 표현·실행으로 펼쳐줘서 아이디어가 빠르게 현실이 되는 결이에요. 창작·발표·이벤트 자리에 둘이 함께 있으면 결과물이 더 또렷하게 살아나요.',
      '火→土': '火→土 결은 불이 땅을 데우는 자리. 내 열정이 상대의 안정 자리를 따뜻하게 만들어줘서 상대가 둥지를 만드는 결이에요. 집·살림·기반 자리에 상대가 자연스럽게 자리잡아요.',
      '土→金': '土→金 결은 땅이 금속을 품는 자리. 내 안정감이 상대의 원칙·기준 자리를 단단하게 만들어줘서 상대가 자기 결을 또렷이 가지는 결이에요. 정리·결정·기준 세우는 자리에 상대가 능력을 펴요.',
      '金→水': '金→水 결은 금속이 물을 맑게 거르는 자리. 내 분별력이 상대의 깊은 자리를 정제해줘서 상대가 자기 본질에 더 가깝게 가요. 내면 탐색·창작·연구 자리에 상대가 깊어져요.',
      '水→木': '水→木 결은 물이 나무를 키우는 자리. 내 직관·이해가 상대의 새 시도 자리를 키워줘서 상대가 자기 가능성을 펼치는 결이에요. 시작·도전·확장 자리에 상대가 자라요.',
      // 반대 상생 5 — B→A 형태 (theyGenerate)
      '火→木': '火→木 결은 거꾸로, 상대가 불처럼 내 나무 결을 데워주는 자리. 상대가 표현·즐거움을 끌어내줘서 내가 평소 못 내놓던 색을 자연스럽게 펴게 되는 결이에요.',
      '土→火': '土→火 결은 거꾸로, 상대가 땅처럼 내 불의 자리를 받쳐주는 자리. 상대 곁에 있으면 내가 들떠도 자리가 잡혀서 무리하지 않게 되는 결이에요.',
      '金→土': '金→土 결은 거꾸로, 상대가 금속의 결로 내 땅을 다듬어주는 자리. 상대 한 마디로 내가 정리해야 할 자리가 보이고, 미루던 결정이 자연스럽게 정해지는 결이에요.',
      '水→金': '水→金 결은 거꾸로, 상대가 물처럼 내 금속의 결을 흐르게 해주는 자리. 평소 굳어 있던 자리에서 상대 곁에 있으면 부드럽게 풀리는 결이에요.',
      '木→水': '木→水 결은 거꾸로, 상대가 나무처럼 내 물의 자리를 끌어올려주는 자리. 평소 잠겨 있던 생각이 상대 곁에 있으면 행동으로 자연스럽게 옮겨지는 결이에요.',
      // 상극 — 10 (A→B + B→A)
      '木→土': '木→土 결은 나무 뿌리가 땅을 뚫는 자리. 내가 새 시도를 권하면 상대 기반이 흔들리는 자리에 가요. 상대 안정감을 인정한 후 새 시도를 권하는 결이 핵심.',
      '土→木': '土→木 결은 거꾸로, 땅이 나무를 누르는 자리. 상대가 안정·기반을 우선시할 때 내 새 시도 자리가 막히는 느낌이 와요.',
      '土→水': '土→水 결은 땅이 물길을 막는 자리. 내가 안정·룰을 권하면 상대 깊은 자리가 막히는 느낌이 와요. 상대 흐름을 먼저 인정한 후 룰을 제안하는 결이 필요.',
      '水→土': '水→土 결은 거꾸로, 물이 땅을 무너뜨리는 자리. 상대 깊은 질문이 내 안정 자리를 흔드는 자리가 자주 와요.',
      '水→火': '水→火 결은 물이 불을 끄는 자리. 내 차분한 한 마디가 상대 열정을 식히는 자리에 가요. 상대 불씨를 먼저 인정한 후 톤 조절하는 결이 핵심.',
      '火→水': '火→水 결은 거꾸로, 불이 물을 끓이는 자리. 상대 열정이 내 잔잔한 자리를 들끓게 만드는 자리가 자주 와요.',
      '火→金': '火→金 결은 불이 금속을 녹이는 자리. 내 열정·표현이 상대의 정리된 원칙을 녹여서 상대가 자기 기준을 잃는 자리에 가요.',
      '金→火': '金→火 결은 거꾸로, 금속이 불에 녹는 자리. 상대 원칙·정리가 내 열정을 끊는 자리가 자주 와요.',
      '金→木': '金→木 결은 금속이 나무를 베는 자리. 내 원칙·기준이 상대 새 시도를 잘라내는 자리에 가요. 상대 시작 자리를 먼저 인정한 후 기준을 적용하는 결이 필요.',
      '木→金': '木→金 결은 거꾸로, 나무가 금속을 둔하게 만드는 자리. 상대 원칙 자리를 내 새 시도가 흔드는 자리가 자주 와요.',
    };
    return map[flow] ?? '';
  }

  String _elementPairSceneEn(_RelationshipAnchorProfile p) {
    final flow = p.elementFlow;
    const map = {
      '木·木': 'Wood·Wood — both love starting (trips, jobs, ventures) but neither closes well; unfinished projects pile on both sides.',
      '火·火': 'Fire·Fire — when you meet, expression and events explode; staying steady through quiet days is the weak spot.',
      '土·土': 'Earth·Earth — stable on promises, money, home; both hesitate at change or adventure.',
      '金·金': 'Metal·Metal — principles and clarity click; soft emotional expression feels awkward for both.',
      '水·水': 'Water·Water — deep talk, inner work, creation align; decision-deferring and overthinking show on both sides.',
      '木→火': 'Wood→Fire — your one word, their expression. Ideas turn into reality fast together.',
      '火→土': 'Fire→Earth — your warmth heats their soil; they build a nest you keep alive.',
      '土→金': 'Earth→Metal — your steadiness sharpens their principles; their boundaries grow clear.',
      '金→水': 'Metal→Water — your discernment clears their depth; they reach their own essence faster.',
      '水→木': 'Water→Wood — your intuition feeds their new attempts; they grow into their potential.',
      '火→木': 'Fire→Wood (reverse) — they warm your wood; colors you usually hide come out easily.',
      '土→火': 'Earth→Fire (reverse) — they ground your fire; even when you spike, you stay anchored.',
      '金→土': 'Metal→Earth (reverse) — one word from them and the cleanup you postponed becomes clear.',
      '水→金': 'Water→Metal (reverse) — what felt rigid in you softens beside them.',
      '木→水': 'Wood→Water (reverse) — submerged thoughts become action when they are near.',
      '木→土': 'Wood→Earth — your roots crack their soil. Honor their stability first, then suggest the new.',
      '土→木': 'Earth→Wood (reverse) — when they prioritize stability, your new attempt feels blocked.',
      '土→水': 'Earth→Water — your rules dam their flow. Honor their current first, then propose structure.',
      '水→土': 'Water→Earth (reverse) — their deep questions can shake your foundation.',
      '水→火': 'Water→Fire — your calm word cools their flame. Honor the spark first, then adjust tone.',
      '火→水': 'Fire→Water (reverse) — their heat boils your stillness.',
      '火→金': 'Fire→Metal — your heat melts their clean lines; they may lose their standard.',
      '金→火': 'Metal→Fire (reverse) — their precision cuts off your flame.',
      '金→木': 'Metal→Wood — your rule cuts their fresh attempt. Honor the start first, then apply standards.',
      '木→金': 'Wood→Metal (reverse) — your new attempt shakes their principled place.',
    };
    return map[flow] ?? '';
  }

  // ── branch pair scene (지지 충 6 / 육합 6 / 형 / 삼합 partial — 각 분기 다른 microcopy) ──
  String _branchPairSceneKo(_RelationshipAnchorProfile p) {
    final pair = '${p.myJi}·${p.ptJi}';
    // 충 6 (양방향 같은 분기)
    const clash = {
      '子·午': '子午 충은 \'밤·낮\' 충돌. 생활 리듬이 정반대로 가요. 한 명이 새벽형, 한 명이 야간형이면 평소 만나는 자리부터 조율이 필요해요. 깊은 결정에서 둘 다 \'내 시간\'을 우선시해서 부딪힘.',
      '午·子': '子午 충은 \'밤·낮\' 충돌. 생활 리듬이 정반대로 가요. 한 명이 새벽형, 한 명이 야간형이면 평소 만나는 자리부터 조율이 필요해요. 깊은 결정에서 둘 다 \'내 시간\'을 우선시해서 부딪힘.',
      '卯·酉': '卯酉 충은 \'동·서\' 충돌. 방향성·가치관이 정반대 자리에서 부딪혀요. 한 명이 진보·새로움, 한 명이 보수·전통이면 인생 방향 결정에서 의견이 갈리는 자리가 자주 와요.',
      '酉·卯': '卯酉 충은 \'동·서\' 충돌. 방향성·가치관이 정반대 자리에서 부딪혀요. 한 명이 진보·새로움, 한 명이 보수·전통이면 인생 방향 결정에서 의견이 갈리는 자리가 자주 와요.',
      '寅·申': '寅申 충은 \'이동·정착\' 충돌. 한 명은 여행·이사·새 시도, 한 명은 한 자리 깊이 파는 결. 큰 이동 결정 (이사·이직·여행) 앞에서 의견이 정반대로 나오는 자리가 자주 와요.',
      '申·寅': '寅申 충은 \'이동·정착\' 충돌. 한 명은 여행·이사·새 시도, 한 명은 한 자리 깊이 파는 결. 큰 이동 결정 (이사·이직·여행) 앞에서 의견이 정반대로 나오는 자리가 자주 와요.',
      '巳·亥': '巳亥 충은 \'드러냄·감춤\' 충돌. 한 명은 표현·공개, 한 명은 사적·내면. SNS·외부 자리 노출도에서 의견이 자주 갈리고, 둘만의 비밀 vs 공개 자리 합의가 필요해요.',
      '亥·巳': '巳亥 충은 \'드러냄·감춤\' 충돌. 한 명은 표현·공개, 한 명은 사적·내면. SNS·외부 자리 노출도에서 의견이 자주 갈리고, 둘만의 비밀 vs 공개 자리 합의가 필요해요.',
      '辰·戌': '辰戌 충은 \'기반·정리\' 충돌. 둘 다 土라 평소엔 안정적이지만, 살림·집·재정 정리 자리에서 \'내 방식\'을 양보 못 해서 부딪히는 자리가 자주 와요.',
      '戌·辰': '辰戌 충은 \'기반·정리\' 충돌. 둘 다 土라 평소엔 안정적이지만, 살림·집·재정 정리 자리에서 \'내 방식\'을 양보 못 해서 부딪히는 자리가 자주 와요.',
      '丑·未': '丑未 충은 \'겨울·여름 土\' 충돌. 한 명은 보수적·신중, 한 명은 개방적·확장. 가족·돈·시간 분배에서 우선순위가 정반대로 갈리는 자리가 자주 와요.',
      '未·丑': '丑未 충은 \'겨울·여름 土\' 충돌. 한 명은 보수적·신중, 한 명은 개방적·확장. 가족·돈·시간 분배에서 우선순위가 정반대로 갈리는 자리가 자주 와요.',
    };
    if (clash.containsKey(pair)) return clash[pair]!;
    // 육합 6
    const hap6 = {
      '子·丑': '子丑 합은 \'겨울 합\'. 같이 있을 때 잔잔하고 따뜻한 결이 만들어져요. 추운 날 같이 있는 자리, 조용한 카페·집 같은 자리가 가장 잘 어울려요.',
      '丑·子': '子丑 합은 \'겨울 합\'. 같이 있을 때 잔잔하고 따뜻한 결이 만들어져요. 추운 날 같이 있는 자리, 조용한 카페·집 같은 자리가 가장 잘 어울려요.',
      '寅·亥': '寅亥 합은 \'생명 합\'. 같이 있을 때 새 시작·도전 자리에 자연스럽게 가요. 여행·창업·이사 같은 큰 시작을 둘이 같이 할 때 결과가 좋아요.',
      '亥·寅': '寅亥 합은 \'생명 합\'. 같이 있을 때 새 시작·도전 자리에 자연스럽게 가요. 여행·창업·이사 같은 큰 시작을 둘이 같이 할 때 결과가 좋아요.',
      '卯·戌': '卯戌 합은 \'화 합\'. 같이 있을 때 표현·열정 자리에 자연스럽게 가요. 둘 다 평소엔 차분해도 함께 있으면 활기가 살아나는 결이에요.',
      '戌·卯': '卯戌 합은 \'화 합\'. 같이 있을 때 표현·열정 자리에 자연스럽게 가요. 둘 다 평소엔 차분해도 함께 있으면 활기가 살아나는 결이에요.',
      '辰·酉': '辰酉 합은 \'금 합\'. 같이 있을 때 원칙·기준·정리 자리에 자연스럽게 가요. 살림·정리·관리 자리에 둘이 같이 있으면 결과가 빠르게 나와요.',
      '酉·辰': '辰酉 합은 \'금 합\'. 같이 있을 때 원칙·기준·정리 자리에 자연스럽게 가요. 살림·정리·관리 자리에 둘이 같이 있으면 결과가 빠르게 나와요.',
      '巳·申': '巳申 합은 \'수 합\'. 같이 있을 때 깊은 대화·내면 탐색 자리에 자연스럽게 가요. 산책·여행·조용한 시간 자리에 가장 잘 어울려요.',
      '申·巳': '巳申 합은 \'수 합\'. 같이 있을 때 깊은 대화·내면 탐색 자리에 자연스럽게 가요. 산책·여행·조용한 시간 자리에 가장 잘 어울려요.',
      '午·未': '午未 합은 \'한여름 합\'. 같이 있을 때 즐거움·이벤트·축제 자리에 자연스럽게 가요. 외출·여행·모임 같은 활기찬 자리가 가장 어울려요.',
      '未·午': '午未 합은 \'한여름 합\'. 같이 있을 때 즐거움·이벤트·축제 자리에 자연스럽게 가요. 외출·여행·모임 같은 활기찬 자리가 가장 어울려요.',
    };
    if (hap6.containsKey(pair)) return hap6[pair]!;
    return '';
  }

  String _branchPairSceneEn(_RelationshipAnchorProfile p) {
    final pair = '${p.myJi}·${p.ptJi}';
    const clash = {
      '子·午': 'Zi·Wu clash — night vs day rhythm; meeting times themselves need negotiation.',
      '午·子': 'Zi·Wu clash — night vs day rhythm; meeting times themselves need negotiation.',
      '卯·酉': 'Mao·You clash — east vs west direction; progressive vs traditional values often split.',
      '酉·卯': 'Mao·You clash — east vs west direction; progressive vs traditional values often split.',
      '寅·申': 'Yin·Shen clash — move vs settle; big moves (relocation, job change, travel) bring opposite views.',
      '申·寅': 'Yin·Shen clash — move vs settle; big moves (relocation, job change, travel) bring opposite views.',
      '巳·亥': 'Si·Hai clash — exposure vs concealment; SNS, public visibility settings need agreement.',
      '亥·巳': 'Si·Hai clash — exposure vs concealment; SNS, public visibility settings need agreement.',
      '辰·戌': 'Chen·Xu clash — both Earth, but household and finance organization styles refuse to yield.',
      '戌·辰': 'Chen·Xu clash — both Earth, but household and finance organization styles refuse to yield.',
      '丑·未': 'Chou·Wei clash — winter vs summer Earth; conservative vs expansive priorities split.',
      '未·丑': 'Chou·Wei clash — winter vs summer Earth; conservative vs expansive priorities split.',
    };
    if (clash.containsKey(pair)) return clash[pair]!;
    const hap6 = {
      '子·丑': 'Zi·Chou union — quiet winter warmth; cafes and home spaces suit best.',
      '丑·子': 'Zi·Chou union — quiet winter warmth; cafes and home spaces suit best.',
      '寅·亥': 'Yin·Hai union — life-spark union; travel, new ventures, moves do well together.',
      '亥·寅': 'Yin·Hai union — life-spark union; travel, new ventures, moves do well together.',
      '卯·戌': 'Mao·Xu union — fire union; calm individually, lively together.',
      '戌·卯': 'Mao·Xu union — fire union; calm individually, lively together.',
      '辰·酉': 'Chen·You union — metal union; cleanup, organizing produces fast results together.',
      '酉·辰': 'Chen·You union — metal union; cleanup, organizing produces fast results together.',
      '巳·申': 'Si·Shen union — water union; walks, travel, quiet time suit best.',
      '申·巳': 'Si·Shen union — water union; walks, travel, quiet time suit best.',
      '午·未': 'Wu·Wei union — midsummer union; outings, parties, festivals fit best.',
      '未·午': 'Wu·Wei union — midsummer union; outings, parties, festivals fit best.',
    };
    if (hap6.containsKey(pair)) return hap6[pair]!;
    return '';
  }

  // ── stem pair scene (천간합 5 / 천간충 — 각 다른 microcopy) ──
  String _stemPairSceneKo(_RelationshipAnchorProfile p) {
    final pair = '${p.myGan}·${p.ptGan}';
    const ganHapPairs = {
      '甲·己': '甲己 합은 \'중정의 합\' — 책임감·중심 잡는 자리에 둘이 함께 가요.',
      '己·甲': '甲己 합은 \'중정의 합\' — 책임감·중심 잡는 자리에 둘이 함께 가요.',
      '乙·庚': '乙庚 합은 \'인의의 합\' — 원칙·약속 지키는 자리에 둘이 함께 가요.',
      '庚·乙': '乙庚 합은 \'인의의 합\' — 원칙·약속 지키는 자리에 둘이 함께 가요.',
      '丙·辛': '丙辛 합은 \'위엄의 합\' — 권위·결정 자리에 둘이 함께 가요.',
      '辛·丙': '丙辛 합은 \'위엄의 합\' — 권위·결정 자리에 둘이 함께 가요.',
      '丁·壬': '丁壬 합은 \'인정의 합\' — 표현·예술·연애 자리에 둘이 함께 가요.',
      '壬·丁': '丁壬 합은 \'인정의 합\' — 표현·예술·연애 자리에 둘이 함께 가요.',
      '戊·癸': '戊癸 합은 \'무정의 합\' — 깊은 신뢰·오래된 인연 자리에 둘이 함께 가요.',
      '癸·戊': '戊癸 합은 \'무정의 합\' — 깊은 신뢰·오래된 인연 자리에 둘이 함께 가요.',
    };
    return ganHapPairs[pair] ?? '';
  }

  String _stemPairSceneEn(_RelationshipAnchorProfile p) {
    final pair = '${p.myGan}·${p.ptGan}';
    const ganHapPairs = {
      '甲·己': 'Jia·Ji union — \'central balance\' union; both step into responsibility together.',
      '己·甲': 'Jia·Ji union — \'central balance\' union; both step into responsibility together.',
      '乙·庚': 'Yi·Geng union — \'principled\' union; promise-keeping spaces unite you.',
      '庚·乙': 'Yi·Geng union — \'principled\' union; promise-keeping spaces unite you.',
      '丙·辛': 'Bing·Xin union — \'authority\' union; decision-making seats fit you both.',
      '辛·丙': 'Bing·Xin union — \'authority\' union; decision-making seats fit you both.',
      '丁·壬': 'Ding·Ren union — \'recognition\' union; expression, art, romance bind you.',
      '壬·丁': 'Ding·Ren union — \'recognition\' union; expression, art, romance bind you.',
      '戊·癸': 'Wu·Gui union — \'silent trust\' union; deep, longstanding bonds form here.',
      '癸·戊': 'Wu·Gui union — \'silent trust\' union; deep, longstanding bonds form here.',
    };
    return ganHapPairs[pair] ?? '';
  }

  // R93 sprint 4 — 사용자 mandate verbatim: "오늘사주나 내 사주느낌으로 자세히 분석하는
  // 느낌으로 되야하고". 사주 9 anchor 다 활용 + 각 섹션 길이 ×2~3 + 새 섹션 (첫 만남 /
  // 일상 호흡 / 깊어지는 결).
  _CompatAnalysis _analyze(SajuResult me, SajuResult partner, bool useKo) {
    final myGan = me.dayPillar.chunGan;
    final myJi = me.dayPillar.jiJi;
    final ptGan = partner.dayPillar.chunGan;
    final ptJi = partner.dayPillar.jiJi;
    final myEl = me.dayPillar.chunGanElement;
    final ptEl = partner.dayPillar.chunGanElement;

    const generates = {
      '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
    };
    const overcomes = {
      '木': '土', '土': '水', '水': '火', '火': '金', '金': '木',
    };
    const ganHap = {
      '甲': '己', '己': '甲', '乙': '庚', '庚': '乙', '丙': '辛',
      '辛': '丙', '丁': '壬', '壬': '丁', '戊': '癸', '癸': '戊',
    };
    const jiHap6 = {
      '子': '丑', '丑': '子', '寅': '亥', '亥': '寅', '卯': '戌',
      '戌': '卯', '辰': '酉', '酉': '辰', '巳': '申', '申': '巳',
      '午': '未', '未': '午',
    };
    const jiSamhapPairs = {
      '子': ['辰', '申'], '辰': ['子', '申'], '申': ['子', '辰'],
      '寅': ['午', '戌'], '午': ['寅', '戌'], '戌': ['寅', '午'],
      '巳': ['酉', '丑'], '酉': ['巳', '丑'], '丑': ['巳', '酉'],
      '亥': ['卯', '未'], '卯': ['亥', '未'], '未': ['亥', '卯'],
    };
    const ji12clash = {
      '子': '午', '丑': '未', '寅': '申', '卯': '酉', '辰': '戌', '巳': '亥',
      '午': '子', '未': '丑', '申': '寅', '酉': '卯', '戌': '辰', '亥': '巳',
    };
    const jiHyeong = {
      '寅': ['巳', '申'], '巳': ['寅', '申'], '申': ['寅', '巳'],
      '丑': ['戌', '未'], '戌': ['丑', '未'], '未': ['丑', '戌'],
      '子': ['卯'], '卯': ['子'],
    };

    // R94 sprint 4 — 두 사주 고유 anchor profile (element pair / branch pair / stem pair
    // 별 specific scene microcopy 분기 wire 에 사용).
    final profile = _relationshipAnchorProfile(me, partner);
    final elPairKo = _elementPairSceneKo(profile);
    final elPairEn = _elementPairSceneEn(profile);
    final brPairKo = _branchPairSceneKo(profile);
    final brPairEn = _branchPairSceneEn(profile);
    final stPairKo = _stemPairSceneKo(profile);
    final stPairEn = _stemPairSceneEn(profile);

    final sameDay = me.day60ji == partner.day60ji;
    final sameBranch = myJi == ptJi;
    final isGanHap = ganHap[myGan] == ptGan;
    final isJiHap6 = jiHap6[myJi] == ptJi;
    final isJiSamhap = (jiSamhapPairs[myJi] ?? const []).contains(ptJi);
    final isClash = ji12clash[myJi] == ptJi;
    final isHyeong = (jiHyeong[myJi] ?? const []).contains(ptJi);
    final iGenerate = generates[myEl] == ptEl;
    final theyGenerate = generates[ptEl] == myEl;
    final iOvercome = overcomes[myEl] == ptEl;
    final theyOvercome = overcomes[ptEl] == myEl;
    final complementary = me.elements.deficit == partner.elements.dominant ||
        partner.elements.deficit == me.elements.dominant;

    // ── [1] summary — 첫 만남 + 오행 base + 일상 호흡 anchor (9줄+, ~600~900 char) ─
    final summary = StringBuffer();
    if (useKo) {
      if (myEl == ptEl) {
        summary.write(
            '두 사람은 같은 오행($myEl) 결을 타고 났어요. 처음 만났을 때부터 별 설명 없이도 결이 닿고, 좋아하는 톤·결정 속도·일상 리듬이 비슷해서 빠르게 편해지는 사이예요. 같은 카페에서 같은 메뉴를 시키거나, 한 영화 보고 비슷한 자리에서 웃거나, 결정 앞에서 비슷한 속도로 답이 나오는 — 그런 자잘한 일치가 자주 발생하는 결이에요.\n\n다만 결이 같은 만큼 약한 자리도 겹쳐서 한 명이 가라앉으면 같이 가라앉기 쉬운 구조예요. 둘 다 피곤한 날, 둘 다 결정 미루는 날, 둘 다 운동 미루는 날이 같은 날에 와요. 그래서 같은 오행 사이는 한 명이 의식적으로 다른 무게를 가져가야 균형이 유지돼요. 평소에 둘 중 한 명이 \'역할 분담\' 한 가지를 정해두면 같이 가라앉는 날을 피할 수 있어요.');
      } else if (iGenerate) {
        summary.write(
            '내 기운이 상대를 살리는 상생(相生) 관계예요. 내가 한 마디 한 행동이 상대한테 깊게 닿고, 상대가 자라는 모습을 보면서 내가 더 단단해지는 결이에요. 가까이 있을수록 상대의 일상 컨디션이 조금씩 좋아지고, 상대가 새로 시작하는 일에 내가 큰 영향을 주는 자리에 자연스럽게 가요.\n\n천천히 가도 시간이 쌓이면 누구도 못 깨는 인연으로 자리잡는 결이지만, 주는 쪽이라 자기 페이스를 잃기 쉬워요. 한 달에 한 번은 자기를 위한 작은 회복 의식을 두는 게 필요해요. 상대가 자라는 모습을 보면서 보람을 느끼는 만큼, 상대도 한 번씩 \'고마워\'를 말로 전해줘야 주는 쪽이 지치지 않아요. 상생은 시간 흐름과 함께 깊어지는 구조라, 조급해하지 말고 1년 단위로 결을 봐도 늦지 않아요.');
      } else if (theyGenerate) {
        summary.write(
            '상대가 나를 살리는 상생(相生) 관계예요. 상대의 결이 내 부족한 자리를 자연스럽게 채워줘서 가까이 있을수록 내가 편해지는 사이예요. 평소에 결정 망설이던 자리에서 상대 한 마디면 답이 나오거나, 컨디션이 흔들리던 날 상대 곁에 있으면 자연스럽게 회복되는 — 그런 보호받는 느낌이 큰 결이에요.\n\n다만 받는 쪽이 표현을 자주 안 해도 상대는 알아주지만, 한 번씩 고마움을 말로 전하면 관계가 한 단계 깊어져요. 받기만 하는 사이는 시간이 지나면 주는 쪽이 지쳐요. 매일 한 번 짧게라도 \'덕분이야\' 한 마디면 충분해요. 또 받는 쪽도 자기가 줄 수 있는 자리 한 가지를 찾아두면 (예: 상대 챙기지 못한 자리 챙겨주기) 관계가 일방통행이 안 돼요.');
      } else if (iOvercome) {
        summary.write(
            '내 기운이 상대를 누르는 상극(相剋) 관계예요. 처음엔 내가 주도하는 자리가 자연스럽고 상대 약점을 정확히 짚어내는 코치 같은 결이에요. 상대가 헤매는 자리에서 내가 한 마디로 길을 잡아주거나, 결정 앞에서 내가 먼저 방향을 정해주는 자리에 자주 가요.\n\n다만 톤이 한 단계만 올라가도 통제처럼 느껴질 수 있어요. 의도와 표현의 거리를 늘 의식해야 오래 가요. 같은 조언이라도 \'이렇게 해\' 보다는 \'이렇게 하는 건 어때\' 식으로 톤을 한 단계 낮추는 게 핵심이에요. 또 상대 약점을 짚어주는 만큼, 상대 강점도 자주 짚어주는 균형이 필요해요. 잘 다루면 상대가 가장 성장하는 코치가 될 수 있는 결이지만, 잘못 다루면 상대가 자기 색을 잃는 구조가 돼요.');
      } else if (theyOvercome) {
        summary.write(
            '상대가 나를 누르는 상극(相剋) 관계예요. 상대 한 마디가 내 페이스를 흔드는 경우가 종종 있고, 가까워질수록 내가 자기 색을 지키는 연습이 필요한 결이에요. 평소엔 부드럽다가도 상대가 한 마디 강하게 던지는 순간 내가 흔들리는 자리가 자주 와요.\n\n잘 다루면 둘 다 단단해지지만 그 전에 서로의 톤 차이를 인정하는 게 먼저예요. 내 입장에선 \'상대가 무겁다\'고 느끼고, 상대 입장에선 \'나는 솔직히 말한 건데 왜 위축되지\' 라고 느끼는 미스매치가 자주 발생해요. 평소에 \'상대 한 마디는 무게가 크다\'는 걸 둘 다 의식하고, 상대도 한 단계 톤 낮추는 연습을 같이 하면 점점 편해져요. 시간이 지나면 상대 강한 톤이 내 본성에 익숙해지면서 단단해지는 구조예요.');
      } else {
        summary.write(
            '두 사람의 오행이 직접 생극(生剋) 관계가 없는 중립적 결이에요. 자극도 충돌도 크지 않고, 첫인상은 잔잔하고 편안하지만 누군가 적극적으로 신호를 보내지 않으면 자연스럽게 거리가 벌어질 수 있어요. 처음 만났을 때 \'좋네\' 정도의 느낌이 오래 가는 결이라, 가벼운 친구로는 편하지만 깊은 관계로 가려면 의식적인 노력이 필요해요.\n\n자극이 적은 만큼 안정감이 큰 결이라, 한 번 가까워지면 부담 없이 오래 가는 구조예요. 다만 자연스럽게 가까워지는 결이 아니라서 한 명이 먼저 신호를 보내는 룰을 정해두면 관계가 흔들리지 않아요. \'매주 한 번 둘만 보는 시간\', \'매일 짧은 안부 한 마디\' 같은 작은 의식이 있으면 자연스럽게 무게가 쌓여요. 중립의 사이는 의식적으로 무게를 만들 때 비로소 깊이가 생겨요.');
      }
      // R94 sprint 4 — element pair (예: 木→火, 子·丑) 별 specific scene 추가.
      // 같은 element-relation 안에서도 두 사주가 다르면 본문이 달라야 한다.
      if (elPairKo.isNotEmpty) {
        summary.write('\n\n$elPairKo');
      }
      // 일주 동일 / 일지 동일 추가 paragraph
      if (sameDay) {
        summary.write(
            '\n\n게다가 같은 60갑자 일주(${me.day60ji})를 공유해요. 60갑자 중 같은 자리에서 시작한 사이라 거울 보듯 닮은 면이 많고, 한 사람이 깨달은 건 다른 사람도 곧 깨달아요. 일주 같으면 인생의 큰 결정 시기·체질·평소 결이 거의 일치해서, 같은 시기에 같은 고민을 하는 결이에요. 사주적으로 가장 강한 \'동기\' 결 중 하나예요.');
      } else if (sameBranch) {
        summary.write(
            '\n\n같은 일지($myJi)를 공유해서 인생 리듬·계절감·체질이 비슷해요. 띠가 같으면 한 해 흐름·세운 영향·신체 컨디션이 비슷하게 와요. 함께 있는 시간 자체가 안정적인 결이고, 평소 결정 속도·생활 리듬이 자연스럽게 맞춰지는 결이에요.');
      }
    } else {
      if (myEl == ptEl) {
        summary.write(
            'You two share the same element ($myEl). Comfort arrives quickly — taste, decision speed, and daily rhythm align without explaining. The flip side: shared weak spots, so when one dips the other dips at the same time.');
      } else if (iGenerate) {
        summary.write(
            'You generate (相生) your partner. Your one word quietly grows them, and their growth in turn steadies you. Slow but durable; the bond hardens with time.');
      } else if (theyGenerate) {
        summary.write(
            'Your partner generates (相生) you. Their grain fills your gaps without effort. You receive more than you give, so showing thanks out loud deepens the bond.');
      } else if (iOvercome) {
        summary.write(
            'You overcome (相剋) your partner. You lead naturally and read their weak spots like a coach. But one notch sharper tone reads as control — intent and delivery must match.');
      } else if (theyOvercome) {
        summary.write(
            'Your partner overcomes (相剋) you. Their one word can shift your pace. The closer you get, the more you must hold your own color. Handle well and both grow tougher.');
      } else {
        summary.write(
            'Mild interaction — neither clash nor spark dominates. Distance grows unless someone deliberately builds weight.');
      }
      if (elPairEn.isNotEmpty) {
        summary.write(' $elPairEn');
      }
      if (sameDay) {
        summary.write(
            ' You also share the same day pillar (${me.day60ji}) — a mirror bond.');
      } else if (sameBranch) {
        summary.write(' Same day branch ($myJi) — life rhythm aligns.');
      }
    }

    // ── [2] attract — 끌리는 지점 (9줄+, ~600~900 char) ──────────────────────────
    final attract = StringBuffer();
    if (useKo) {
      if (isGanHap) {
        attract.write(
            '천간 오합($myGan·$ptGan)이 맺어진 사이예요. 천간합은 사주에서 가장 강한 끌림 중 하나로, 처음 봤을 때부터 끌리는 자석 같은 결이에요. 한 번 가까워지면 떨어지기 힘든 구조라, 평생 친구·연인·동업자 어느 자리로 두어도 결이 단단해져요.\n\n천간합은 \'서로 보완하고 싶은 자리\'를 자극해서 만남 자체가 자연스럽게 이어져요. 둘이 같이 있을 때 시간이 빨리 가는 느낌, 다른 사람과 있을 때보다 자기다워지는 느낌이 자주 와요. 다만 합이 강한 만큼 한쪽이 자기 색을 잃기 쉬워요. 처음엔 \'운명\' 같지만 시간이 지나면서 둘 다 변형되는 결이라, 각자의 페이스를 의식적으로 지키는 게 한 해 두 해 흐를수록 더 중요해져요.');
      } else if (isJiHap6) {
        attract.write(
            '지지 육합($myJi·$ptJi)이 있어서 가까워질수록 일상 호흡이 자연스럽게 맞아져요. 같이 살거나 같이 일하는 자리에 잘 어울리고, 의식하지 않아도 둘의 페이스가 합쳐지는 결이에요. 함께 한 공간에 있을 때 가장 빛나는 관계예요.\n\n육합은 \'일상의 합\'이라 같이 보내는 시간이 늘수록 둘만의 루틴이 자연스럽게 만들어져요. 같이 밥 먹기, 같이 산책, 같이 청소 — 이런 자잘한 일상 자리가 둘에게 가장 큰 의미를 만들어요. 거창한 이벤트보다 작은 매일이 관계를 단단하게 만드는 결이라, 둘이 같이 \'평범한 하루\'를 자주 보내면 자연스럽게 깊어져요. 같이 사는 자리·같이 일하는 자리에 가장 어울리는 합이에요.');
      } else if (isJiSamhap) {
        attract.write(
            '지지 삼합 일부($myJi·$ptJi)가 맺어져 있어서 같은 목표를 향해 움직일 때 시너지가 가장 잘 나와요. 함께 프로젝트 하나, 여행 한 번, 가게 하나 만들어가는 자리가 잘 맞고, 결과를 같이 만든 경험이 관계를 두텁게 해요.\n\n삼합은 \'목표 합\'이라 둘만의 공통 미션이 있을 때 가장 단단해져요. 평소엔 잔잔하다가도 같이 하는 큰 일이 생기면 시너지가 폭발하는 결이라, 한 분기에 한 번 정도는 \'둘이 함께하는 프로젝트\' 한 가지를 만들어두면 좋아요. 여행·운동·창작·창업 — 어떤 자리든 공통 목표가 있는 자리에 둘이 함께 있으면 결과가 자연스럽게 따라와요.');
      } else if (myEl == ptEl) {
        attract.write(
            '오행 비화(比和) — 같은 결이라 첫인상이 익숙하고, 둘만의 말투·취향·결정 속도가 빠르게 맞아져요. 굳이 설명 안 해도 통하는 자리에 같이 있을 때 편안함이 가장 커요.\n\n비화는 \'동기\' 결이라 친구·동료·형제 같은 자리에 가장 잘 어울려요. 같은 결을 가진 사람과 함께 있을 때 자기다운 표현이 가장 잘 나오고, 평소 잠재되어 있던 색이 같이 드러나는 결이에요. 다만 비화는 끌림이 강하기보다는 편함이 큰 결이라, 가까이 있을수록 친밀해지지만 시작은 자연스럽게 일어나지 않을 수 있어요. 한 명이 먼저 신호 보내는 룰을 만들어두면 좋아요.');
      } else if (iGenerate || theyGenerate) {
        attract.write(
            '오행 상생(相生) — 한 사람이 다른 사람을 자연스럽게 자라게 하는 결이에요. 받는 쪽은 보호받는 느낌이 크고, 주는 쪽은 자기가 만들어낸 변화에서 보람을 느껴요. 시간이 지날수록 깊어지는 관계예요.\n\n상생은 \'성장\' 결이라 한 명이 가르치고 한 명이 배우는 자리에 자연스럽게 가요. 같이 보낸 1년이 지나면 받는 쪽이 눈에 띄게 자라있고, 주는 쪽도 자기가 키운 자리에서 자부심을 느껴요. 다만 한쪽으로 흐르는 결이라 균형을 위해 받는 쪽도 자기 자리를 만들어두는 게 좋아요. 시간이 흐르면서 역할이 바뀌는 자리 (받는 쪽이 다른 자리에서 주는 쪽이 되는) 가 자연스럽게 생기면 관계가 더 단단해져요.');
      } else {
        attract.write(
            '판단을 강요하지 않는 잔잔한 편안함이 매력이에요. 강한 끌림은 없지만 한 번 가까워지면 부담 없이 오래 가는 결이에요.\n\n중립의 사이는 \'편안한 공존\'이 가장 큰 매력이에요. 서로의 자리를 침범하지 않고, 자기 페이스를 유지하면서 같이 있는 자리. 부담 없이 만나고, 부담 없이 헤어지고, 부담 없이 다시 만나는 결이라 평생 곁에 두기에는 가장 편한 결 중 하나예요. 다만 자연스럽게 가까워지지 않으니 한 명이 먼저 신호 보내는 룰이 필요해요.');
      }
      if (complementary) {
        attract.write(
            '\n\n게다가 한 사람이 많이 가진 오행이 다른 사람이 부족한 자리를 정확히 채우는 보완 구조도 있어요. 사주적으로 가장 안정적인 결 중 하나로, 같이 있을 때 둘 다 균형이 잡혀서 결정·건강·돈 흐름이 모두 안정돼요. 평소 부족하다 느낀 자리가 상대 곁에 있을 때 자연스럽게 채워지는 — 그런 \'완성\' 결이에요.');
      }
      // R94 sprint 5 — element pair scene 을 attract 본문에도 mirror.
      // (summary/friction 에는 이미 wire 되어 있었으나 attract 누락 — codex 지적.)
      if (elPairKo.isNotEmpty) {
        attract.write('\n\n$elPairKo');
      }
      // R94 sprint 4 — 두 사주 고유 gan/ji pair 별 specific scene.
      // 예: isGanHap 분기 안에서 甲己 vs 乙庚 vs 丙辛 다른 본문.
      if (stPairKo.isNotEmpty) {
        attract.write('\n\n$stPairKo');
      }
      if (brPairKo.isNotEmpty) {
        attract.write('\n\n$brPairKo');
      }
    } else {
      if (isGanHap) {
        attract.write(
            'Heavenly stem union ($myGan·$ptGan) — one of the strongest pulls in saju. Magnetic from first sight; once close, hard to separate. Friend, partner, business — the bond holds wherever you place it.');
      } else if (isJiHap6) {
        attract.write(
            'Six harmony ($myJi·$ptJi) — daily breath syncs without effort. Fits living or working together; shines brightest when sharing space.');
      } else if (isJiSamhap) {
        attract.write(
            "Triad partial ($myJi·$ptJi) — synergy peaks around shared goals. Build a project, take a trip, run a shop together — shared outcomes thicken the bond.");
      } else if (myEl == ptEl) {
        attract.write(
            'Same element grain — first impression feels familiar; tone, taste, and decision speed sync fast. Comfort runs highest in shared space.');
      } else if (iGenerate || theyGenerate) {
        attract.write(
            'Generating (相生) bond — one quietly grows the other. The receiver feels protected; the giver finds meaning. Depth compounds over time.');
      } else {
        attract.write("A quiet ease that doesn't demand alignment. No strong pull, but durable once close.");
      }
      if (complementary) {
        attract.write(
            " Dominant element on one side fills the deficit on the other — together, balance shows in decisions, health, money flow.");
      }
      if (elPairEn.isNotEmpty) {
        attract.write(' $elPairEn');
      }
      if (stPairEn.isNotEmpty) {
        attract.write(' $stPairEn');
      }
      if (brPairEn.isNotEmpty) {
        attract.write(' $brPairEn');
      }
    }

    // ── [3] friction — 부딪힘 (9줄+, ~600~900 char) ──────────────────────────────
    final friction = StringBuffer();
    if (useKo) {
      if (isClash) {
        friction.write(
            '지지 충($myJi·$ptJi)이 있어요. 일주끼리 충이 있으면 큰 결정·이사·여행·돈 결정에서 의견이 자주 엇갈려요. 평소엔 잘 맞다가도 \'이사 갈까\', \'이 차 사도 돼\', \'여행 어디 갈래\' 같은 큰 결정 앞에서 둘의 방향이 다르게 나오는 자리가 자주 와요.\n\n사주가 말하는 한 가지 — 미리 룰을 정하는 것. "이건 누구 결정으로 가자" 같은 합의를 평소에 해두면 한 번씩 부딪힐 때도 큰 다툼으로 안 가요. 예를 들어 \'돈 결정은 한 명, 여행 결정은 다른 한 명\' 식으로 영역을 나누는 룰이 도움돼요. 충이 있는 사이는 한 번 제대로 부딪히고 나면 오히려 깊어지는 경우가 많아요 — 부딪힘 자체가 두 사람이 진심을 꺼내놓는 자리라서요. 충을 겁내지 말고 부딪힐 때 솔직하게 말하는 결이 더 중요해요.');
      } else if (isHyeong) {
        friction.write(
            '지지 형($myJi·$ptJi)이 걸려 있어요. 한 번씩 강한 한 마디가 오갈 수 있고, 그 한 마디가 평소 누적된 작은 서운함에서 시작되는 경우가 많아요. 평소엔 별일 없다가도 한 번에 폭발하는 결이라, 사소한 서운함을 그때그때 풀어주는 습관이 가장 큰 보약이에요.\n\n평소에 작은 인정과 칭찬을 자주 챙겨주는 게 큰 다툼을 막아요. \'잘했어\', \'고마워\', \'네 덕분이야\' — 이런 한 마디를 하루 한 번씩 챙겨주면 큰 한 마디 갈등이 거의 안 와요. 또 형 사이는 \'사소한 일이 갑자기 커지는\' 결이라 다툼이 시작되면 한 박자 쉬는 룰이 필요해요. \'화날 때 10분 자리 떨어지기\' 같은 합의를 미리 해두면 큰 충돌이 안 만들어져요.');
      } else if (iOvercome || theyOvercome) {
        friction.write(
            '오행 상극이 있어서 말의 톤이 한 단계만 높아져도 통제처럼 느껴질 수 있어요. 의도와 표현의 거리가 가장 중요한 사이라, 같은 말이라도 "왜"부터 짚어주는 습관이 필요해요. \'이렇게 해\'보다는 \'이렇게 하는 게 어때, 왜냐면…\' 식으로 톤을 한 단계 낮추는 게 핵심이에요.\n\n상극은 평소엔 단단한 관계를 만드는 결이지만 톤 관리 못 하면 한쪽이 위축되기 쉬워요. 누르는 쪽은 자기 톤이 강한 줄 모를 수 있고, 눌리는 쪽은 점점 자기 색을 잃을 수 있어요. 그래서 \'내 톤이 너무 강했어?\' 한 번씩 묻는 결, \'네 의견 듣고 싶어\' 한 번씩 권하는 결이 필수예요. 한 번 잘 풀면 둘 다 단단해지는 관계지만, 잘못 풀면 한쪽이 점점 작아지는 구조예요.');
      } else if (myEl == ptEl) {
        friction.write(
            '결이 같아서 약한 자리도 겹쳐요. 한 사람이 가라앉으면 다른 사람도 같이 가라앉기 쉬운 구조라, 둘 중 한 명이 의식적으로 다른 행동을 선택해주는 룰이 필요해요. 같이 피곤한 날, 같이 결정 미루는 날, 같이 운동 빠지는 날이 자주 겹쳐요.\n\n그래서 비화 사이는 \'역할 분담\' 룰이 효과 커요. \'둘 다 지친 날 한 명은 산책 한 명은 휴식\', \'둘 다 결정 미룬 날 한 명이 작은 결정 한 가지 먼저 내려주기\' — 이런 자잘한 분담이 같이 가라앉는 날을 피하게 해줘요. 또 같은 결끼리는 \'서로 거울 보듯\' 닮은 단점이 보일 수 있어서, 그게 자기 단점 같아 보일 수 있어요. 그건 상대 단점이지 자기 단점이 아니라는 걸 의식하면 갈등이 줄어요.');
      } else {
        friction.write(
            '강한 부딪힘은 없지만, 적극적인 신호가 없으면 자연스럽게 거리가 벌어질 수 있어요. 한 사람이 먼저 신호를 보내는 룰을 정해두면 관계가 흔들리지 않아요. 중립의 사이는 \'잊혀짐\'이 가장 큰 위험이라, 정기적으로 연락하는 약속 하나가 필요해요.\n\n중립이라 충돌이 적은 만큼 깊이도 자연스럽게 안 생기는 결이에요. 그래서 한 명이 \'우리 이번 주 한 번 보자\' 한 마디 먼저 보내는 자리에 자주 가야 관계가 유지돼요. 또 \'특별히 갈등은 없는데 왜 멀어지지\' 라는 느낌이 자주 와요 — 그건 본인들 잘못이 아니라 단순히 자연스러운 끌림이 없는 결이라서 그래요. 의식적인 정성이 깊이를 만드는 사이예요.');
      }
      // R94 sprint 4 — branch clash 분기 (예: 子午 vs 卯酉 vs 寅申) 별 specific scene.
      // element pair 도 상극·비화 안에서 변별 (예: 木→土 vs 水→火 다른 본문).
      if (brPairKo.isNotEmpty) {
        friction.write('\n\n$brPairKo');
      }
      if (elPairKo.isNotEmpty) {
        friction.write('\n\n$elPairKo');
      }
    } else {
      if (isClash) {
        friction.write(
            "Branch clash ($myJi·$ptJi). Friction shows in big decisions, moves, money. Pre-agree rules — 'this kind of decision goes your way' — and small clashes don't escalate. Often deepens after one real clash.");
      } else if (isHyeong) {
        friction.write(
            "Branch punishment ($myJi·$ptJi). Sharp words may surface, usually from accumulated small slights. Daily acknowledgments prevent the big blow-up.");
      } else if (iOvercome || theyOvercome) {
        friction.write(
            'Overcoming bond — one notch sharper tone reads as control. Lead with "why" before "what". Worked through, both grow tougher.');
      } else if (myEl == ptEl) {
        friction.write(
            "Shared element means shared weak spots. When one dips, the other tends to dip with them. One of you must consciously pick the opposite move.");
      } else {
        friction.write(
            "No strong clash, but distance grows without active signals. Agree who reaches out first when there's silence.");
      }
      if (brPairEn.isNotEmpty) {
        friction.write(' $brPairEn');
      }
      if (elPairEn.isNotEmpty) {
        friction.write(' $elPairEn');
      }
    }

    // ── [4] actions — 실천 (anchor 따라 5~7개 + 자세한 설명) ────────────────────
    final List<String> actions;
    if (useKo) {
      actions = [
        if (isClash)
          '【큰 결정 룰 정하기】 이사·여행·돈·자녀 같은 큰 결정 영역마다 \'누가 주도\'할지 미리 합의해두세요. "이런 결정은 네가, 저런 결정은 내가" 한 줄 룰이면 충돌 빈도가 절반으로 줄어요. 룰은 정한 후에도 6개월에 한 번 재조정하는 게 좋아요.'
        else if (isGanHap || isJiHap6)
          '【둘만의 시간 보호】 합이 있어서 자연스럽게 가까워지는 결이지만, 그만큼 외부 일정에 같이 휩쓸리기 쉬워요. 일주일에 최소 한 번은 둘만 보내는 시간 (한 끼 식사, 한 산책) 을 캘린더에 박아두세요.'
        else
          '【의견 먼저 듣기】 매주 한 가지 결정은 상대 의견을 먼저 묻고 정해보세요. 작은 결정 (오늘 점심) 부터 시작해서 큰 결정으로 확장하는 결이에요. 의식적인 \'먼저 듣기\' 습관이 관계의 가장 큰 약 중 하나예요.',
        if (myEl == ptEl)
          '【역할 분담 룰】 같은 결이라 약한 자리도 같이 와요. 둘 다 지친 날·둘 다 결정 미루는 날을 위해 \'한 명이 산책 한 명이 휴식\', \'한 명이 결정 한 명이 따라가기\' 식 분담 룰을 미리 정해두세요.'
        else if (complementary)
          '【보완 의식 챙기기】 서로 부족한 오행을 카드로 공유하고, 색·음식·장소·계절 중 하나로 작게 챙겨주세요. 예: 본인 부족 오행이 \'금\'이면 상대가 \'단정한 식기·하얀색 옷·서늘한 카페\' 한 가지 챙겨주는 결.'
        else
          '【사주 같이 보기】 한 달에 한 번은 둘이 사주 8글자 같이 보면서 서로 어디가 강하고 어디가 약한지 확인해보세요. 객관적인 anchor 가 있으면 평소엔 안 보이던 자기 단점도 자연스럽게 보여요.',
        if (isHyeong || isClash)
          '【작은 인정 자주 챙기기】 평소에 \'잘했어, 고마워, 네 덕분이야\' 한 마디씩 자주 챙겨주세요. 큰 한 마디 갈등은 거의 항상 작은 누적된 서운함에서 시작돼요. 매일 한 번 작은 인정 한 마디면 큰 충돌이 거의 사라져요.'
        else if (iGenerate || theyGenerate)
          '【받는 쪽이 표현 챙기기】 받는 쪽이 한 번씩 \'덕분이야\' 한 마디만 말로 전해주세요. 보이지 않으면 주는 쪽이 지치고, 1년 안에 주는 쪽이 먼저 거리를 두는 자리가 옵니다. 표현은 큰 것 필요 X, 한 줄 톡 하나면 충분해요.'
        else
          '【작은 공동 루틴】 같이 한 가지 작은 루틴 만들기. 매일 밤 \'잘 자\' 한 마디, 주 1회 같이 산책, 매달 같이 보는 영화 한 편 — 자잘한 루틴이 깊이를 만들어요.',
        '【다툼 후 24시간 룰】 어떤 사이든 다툼은 와요. \'다툰 후 24시간 안에 한 명이 먼저 손 내밀기\' 룰을 미리 정해두면 작은 다툼이 큰 단절로 안 갑니다. 누가 먼저 손 내밀지 미리 정해두면 더 좋아요.',
        if (iOvercome || theyOvercome)
          '【톤 한 단계 낮추기 연습】 상극 결이라 톤이 자기도 모르게 강해질 수 있어요. \'이렇게 해\' → \'이렇게 하는 게 어때, 왜냐면…\' 식으로 한 단계 낮추는 연습을 평소에 해두세요.'
        else
          '【1년에 한 번 관계 점검】 매년 같은 날 (만난 날, 결혼 기념일, 새해 첫날 등) 둘이 1년을 되돌아보면서 \'잘된 자리·아쉬운 자리·다음 해 목표\' 한 가지씩 적어보세요.',
      ];
    } else {
      actions = [
        if (isClash)
          'Pre-agree rules on big decisions (move, travel, money) — one line of consensus prevents escalation.'
        else if (isGanHap || isJiHap6)
          'Stem/branch union means natural closeness — protect one weekly time slot for just the two of you.'
        else
          'Once a week, let the other go first on one real decision.',
        if (myEl == ptEl)
          "When both feel the same dip, one of you picks the opposite move."
        else if (complementary)
          "Share each other's deficit element — pick one small ritual (color, food, place)."
        else
          "Once a month, look at both 8-character saju together; name strengths and weaknesses.",
        if (isHyeong || isClash)
          "Daily small acknowledgments — big-blow-up words start from accumulated small slights."
        else if (iGenerate || theyGenerate)
          "The receiver says thanks out loud once in a while — invisible gratitude burns the giver out."
        else
          "Build one small shared ritual (nightly greeting, weekly walk).",
      ];
    }

    // ── [5] loveMarriage — 연애·결혼·자녀 (사용자 mandate verbatim "연애 결혼 아이등") ─
    final loveMarriage = StringBuffer();
    if (useKo) {
      // 연애
      if (isGanHap) {
        loveMarriage.write(
            '【연애】 천간합이 있는 사이라 사주가 가장 강하게 권하는 연애 결이에요. 처음부터 자연스럽게 끌리고 한 번 가까워지면 떨어지기 힘든 관계로 자리잡아요. 데이트가 자주 길어지고, 함께 있을 때 시간이 빨리 가는 결이에요. 다만 합이 강한 만큼 한쪽이 빠지면 자기 페이스를 잃기 쉬워서 평소에 \'나만의 시간\' 한 자리는 꼭 챙겨두세요.');
      } else if (isJiHap6 || isJiSamhap) {
        loveMarriage.write(
            '【연애】 지지합이 있어서 일상에서 자연스럽게 가까워지는 결이에요. 데이트보다 같이 보내는 평범한 하루가 더 중요한 사이고, 같이 영화 보고 같이 밥 먹고 같이 산책하는 자잘한 자리가 연애의 핵심이에요. 외부 자극보다 둘만의 루틴이 단단해질수록 깊이가 커져요.');
      } else if (isClash) {
        loveMarriage.write(
            '【연애】 지지 충이 있어서 연애 자체는 강렬하지만 큰 결정 앞에서 자주 부딪히는 결이에요. \'어디 갈래\', \'뭐 먹을래\', \'언제 만날래\' 같은 자리에서 의견이 자주 엇갈리니까 미리 룰을 정해두는 게 도움돼요. 한 번 크게 부딪히고 나면 오히려 깊어지는 사이라, 부딪힘 자체를 피하지 말고 솔직하게 말하는 결이 더 중요해요.');
      } else if (iOvercome || theyOvercome) {
        loveMarriage.write(
            '【연애】 상극 결이라 처음엔 자극이 강한 연애로 시작해요. 누르는 쪽이 결정하고 눌리는 쪽이 따라가는 자리가 자연스럽게 나오지만, 톤 관리 못 하면 한쪽이 위축되기 쉬워요. 평소에 \'네 의견 어때\' 자주 묻는 결이 연애를 길게 가져가는 핵심이에요.');
      } else if (myEl == ptEl) {
        loveMarriage.write(
            '【연애】 같은 결이라 친구 같은 연애 결이에요. 처음 만났을 때부터 편안하고 굳이 잘 보이려 하지 않아도 자연스러운 사이. 강렬한 끌림보다 잔잔한 편안함이 매력이라 \'느낌 없는데 편한\' 단계가 가장 깊은 사랑일 수 있어요.');
      } else {
        loveMarriage.write(
            '【연애】 중립 결이라 자연스러운 끌림은 약하지만 의식적으로 가까워지면 부담 없이 오래 가는 연애 결이에요. 한 명이 먼저 다가가는 룰이 필요하고, 정기적인 데이트 약속이 관계 유지의 핵심이에요.');
      }
      loveMarriage.write('\n\n');
      // 결혼
      if (isClash) {
        loveMarriage.write(
            '【결혼】 충이 있는 사이는 결혼 후 큰 결정 (주거지·자녀·금전) 앞에서 의견이 자주 엇갈리니까 결혼 전에 \'영역 분담\' 룰을 미리 정해두는 게 좋아요. 누가 어떤 결정 영역을 책임지는지 명시적으로 합의해두면 결혼 생활이 훨씬 안정돼요. 충이 있어도 룰만 잘 세우면 평생 가는 결혼이 충분히 가능해요.');
      } else if (isHyeong) {
        loveMarriage.write(
            '【결혼】 형 사이는 평소엔 잘 지내다가 한 번씩 큰 한 마디가 폭발하는 결이라, 결혼 생활에서 \'사소한 서운함 그때그때 풀기\' 습관이 가장 중요해요. 매일 한 마디 칭찬, 한 마디 고마움이 누적되면 큰 다툼이 거의 안 와요.');
      } else if (iGenerate || theyGenerate || isGanHap || isJiHap6 || isJiSamhap) {
        loveMarriage.write(
            '【결혼】 사주적으로 결혼 잘 어울리는 결이에요. 합·상생이 있는 사이는 결혼 생활이 시간 흐름과 함께 깊어지는 구조라, 신혼 때보다 5년·10년 후가 더 단단한 결이에요. 매년 결혼 기념일에 한 해를 되돌아보는 의식 하나만 두어도 관계가 자연스럽게 단단해져요.');
      } else if (iOvercome || theyOvercome) {
        loveMarriage.write(
            '【결혼】 상극 사이의 결혼은 \'역할 분담이 명확한 결혼\' 으로 풀면 가장 잘 작동해요. 누가 결정 자리에 있는지, 누가 챙김 자리에 있는지 자연스럽게 정해지는 결이라, 그 자리를 인정하고 시작하면 평생 단단한 결혼이 가능해요. 다만 톤 관리 못 하면 한쪽이 결혼 안에서 작아질 수 있으니 \'서로 다르게 표현해도 사랑\'이라는 기본 약속이 필요해요.');
      } else {
        loveMarriage.write(
            '【결혼】 중립 결의 결혼은 \'편안한 동반자\' 모델로 풀어요. 강한 합도 없고 강한 충도 없는 사이라 결혼 생활이 잔잔하고 안정적이에요. 둘만의 작은 루틴 (매주 데이트, 매달 짧은 여행, 매년 함께 보는 영화 list 등) 을 만들어두면 자연스럽게 깊이가 쌓여요.');
      }
      loveMarriage.write('\n\n');
      // 자녀
      loveMarriage.write(
          '【자녀】 사주적으로 자녀 운은 두 사람의 일주 조합보다 각자의 자녀궁 (식상·관성 영역) 이 더 큰 영향을 줘요. ');
      if (myEl == ptEl || iGenerate || theyGenerate || isGanHap || isJiHap6 || isJiSamhap) {
        loveMarriage.write(
            '두 사람이 화목한 결인 만큼 자녀에게 안정된 가정 분위기를 만들어주기 좋은 사이예요. 둘이 같은 방향으로 자녀를 키우면 자녀가 자기 결을 또렷이 가지는 결이고, 의견이 갈릴 때도 한쪽이 먼저 한 발 양보하는 습관이 자녀에게 가장 큰 교육이 돼요.');
      } else if (isClash || isHyeong || iOvercome || theyOvercome) {
        loveMarriage.write(
            '두 사람 사이에 충·형·상극이 있는 만큼 자녀 교육 방향에서 의견이 자주 갈릴 수 있어요. 자녀 앞에서 의견 다르게 표현 안 하는 약속, 큰 결정 (학교·진로·생활 룰) 은 자녀 없는 자리에서 먼저 합의하는 룰이 가장 큰 보약이에요. 충돌이 있는 만큼 자녀가 \'양쪽 모두에게 사랑받는다\' 확신만 있으면 두 사람 결을 자기 안에서 통합해 더 단단해질 수 있어요.');
      } else {
        loveMarriage.write(
            '두 사람이 중립 결이라 자녀 교육에서도 잔잔하게 합의하는 자리에 가요. 자녀에게 강한 방향성을 주기보다 자녀 스스로 자기 색을 찾도록 곁에서 지지해주는 결이 두 사람한테 가장 잘 맞아요.');
      }
    } else {
      loveMarriage.write('【LOVE】 ');
      if (isGanHap) {
        loveMarriage.write('Stem union — saju strongly recommends this love. Magnetic from start; once close, hard to separate. Protect one personal time slot each week.\n\n');
      } else if (isJiHap6 || isJiSamhap) {
        loveMarriage.write('Branch union — closeness grows in daily life. Routines matter more than dates.\n\n');
      } else if (isClash) {
        loveMarriage.write('Branch clash — intense love but frequent friction on small decisions. Pre-agree rules.\n\n');
      } else if (iOvercome || theyOvercome) {
        loveMarriage.write('Overcoming bond — start intense; one leads, one follows. Tone matters most.\n\n');
      } else if (myEl == ptEl) {
        loveMarriage.write('Same element — friend-like love. Comfort over passion.\n\n');
      } else {
        loveMarriage.write('Neutral grain — natural pull is mild; intentional closeness builds durable love.\n\n');
      }
      loveMarriage.write('【MARRIAGE】 ');
      if (isClash) {
        loveMarriage.write('Pre-marriage role-allocation rules essential.\n\n');
      } else if (isHyeong) {
        loveMarriage.write('Daily acknowledgments prevent the big blow-up.\n\n');
      } else if (iGenerate || theyGenerate || isGanHap || isJiHap6 || isJiSamhap) {
        loveMarriage.write('Saju-favorable for marriage; depth compounds over years.\n\n');
      } else if (iOvercome || theyOvercome) {
        loveMarriage.write('Works best as clear-role marriage. Mutual "we love differently" promise required.\n\n');
      } else {
        loveMarriage.write('Comfortable-companion model. Build small joint rituals.\n\n');
      }
      loveMarriage.write('【CHILDREN】 Children luck depends more on each person\'s child-palace than the pair combination. ');
      if (myEl == ptEl || iGenerate || theyGenerate || isGanHap || isJiHap6 || isJiSamhap) {
        loveMarriage.write('Harmonious bond builds stable parenting climate.');
      } else if (isClash || isHyeong || iOvercome || theyOvercome) {
        loveMarriage.write('Pre-agree big decisions away from kids; align in front of them.');
      } else {
        loveMarriage.write('Quiet alignment; let kids find their own colors with both of you supporting.');
      }
    }

    return _CompatAnalysis(
      summary: summary.toString(),
      attract: attract.toString(),
      friction: friction.toString(),
      loveMarriage: loveMarriage.toString(),
      actions: actions,
    );
  }
}

class _CompatAnalysis {
  final String summary;
  final String attract;
  final String friction;
  final String loveMarriage;
  final List<String> actions;
  _CompatAnalysis({
    required this.summary,
    required this.attract,
    required this.friction,
    required this.loveMarriage,
    required this.actions,
  });
}

// R94 sprint 4 — 두 사주 고유 8글자를 분기 본문 microcopy 에 wire 하기 위한 anchor 묶음.
class _RelationshipAnchorProfile {
  final String myGan;
  final String myJi;
  final String ptGan;
  final String ptJi;
  final String myEl;
  final String ptEl;
  final String elementPair;
  final String elementFlow;
  final String branchPair;
  final String myDay60;
  final String ptDay60;
  const _RelationshipAnchorProfile({
    required this.myGan,
    required this.myJi,
    required this.ptGan,
    required this.ptJi,
    required this.myEl,
    required this.ptEl,
    required this.elementPair,
    required this.elementFlow,
    required this.branchPair,
    required this.myDay60,
    required this.ptDay60,
  });
}
