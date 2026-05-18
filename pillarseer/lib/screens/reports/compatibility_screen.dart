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

    // ── [1] summary — 첫 만남 + 오행 base + 일상 호흡 anchor (3~5 문장) ─────────
    final summary = StringBuffer();
    if (useKo) {
      if (myEl == ptEl) {
        summary.write(
            '두 사람은 같은 오행($myEl) 결을 타고 났어요. 처음 만났을 때부터 별 설명 없이도 결이 닿고, 좋아하는 톤·결정 속도·일상 리듬이 비슷해서 빠르게 편해지는 사이예요. 다만 결이 같은 만큼 약한 자리도 겹쳐서 한 명이 가라앉으면 같이 가라앉기 쉬운 구조예요.');
      } else if (iGenerate) {
        summary.write(
            '내 기운이 상대를 살리는 상생(相生) 관계예요. 내가 한 마디 한 행동이 상대한테 깊게 닿고, 상대가 자라는 모습을 보면서 내가 더 단단해지는 결이에요. 천천히 가도 시간이 쌓이면 누구도 못 깨는 인연으로 자리잡아요.');
      } else if (theyGenerate) {
        summary.write(
            '상대가 나를 살리는 상생(相生) 관계예요. 상대의 결이 내 부족한 자리를 자연스럽게 채워줘서 가까이 있을수록 내가 편해지는 사이예요. 받는 쪽이 표현을 자주 안 해도 상대는 알아주지만, 한 번씩 고마움을 말로 전하면 관계가 한 단계 깊어져요.');
      } else if (iOvercome) {
        summary.write(
            '내 기운이 상대를 누르는 상극(相剋) 관계예요. 처음엔 내가 주도하는 자리가 자연스럽고 상대 약점을 정확히 짚어내는 코치 같은 결이지만, 톤이 한 단계만 올라가도 통제처럼 느껴질 수 있어요. 의도와 표현의 거리를 늘 의식해야 오래 가요.');
      } else if (theyOvercome) {
        summary.write(
            '상대가 나를 누르는 상극(相剋) 관계예요. 상대 한 마디가 내 페이스를 흔드는 경우가 종종 있고, 가까워질수록 내가 자기 색을 지키는 연습이 필요한 결이에요. 잘 다루면 둘 다 단단해지지만 그 전에 서로의 톤 차이를 인정하는 게 먼저예요.');
      } else {
        summary.write(
            '두 사람의 오행이 직접 생극(生剋) 관계가 없어요. 자극도 충돌도 크지 않고, 첫인상은 잔잔하고 편안하지만 누군가 적극적으로 신호를 보내지 않으면 자연스럽게 거리가 벌어질 수 있어요. 의식적으로 무게를 만들 때 비로소 깊이가 생기는 인연이에요.');
      }
      // 일주 동일 / 일지 동일 추가 한 줄
      if (sameDay) {
        summary.write(
            ' 게다가 같은 60갑자 일주(${me.day60ji})를 공유해요. 거울 보듯 닮은 면이 많고, 한 사람이 깨달은 건 다른 사람도 곧 깨달아요.');
      } else if (sameBranch) {
        summary.write(
            ' 같은 일지($myJi)를 공유해서 인생 리듬·계절감·체질이 비슷해요. 함께 있는 시간 자체가 안정적인 결이에요.');
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
      if (sameDay) {
        summary.write(
            ' You also share the same day pillar (${me.day60ji}) — a mirror bond.');
      } else if (sameBranch) {
        summary.write(' Same day branch ($myJi) — life rhythm aligns.');
      }
    }

    // ── [2] attract — 끌리는 지점 (천간합 / 지지합 / 보완 구조) ──────────────────
    final attract = StringBuffer();
    if (useKo) {
      if (isGanHap) {
        attract.write(
            '천간 오합($myGan·$ptGan)이 맺어진 사이예요. 천간합은 사주에서 가장 강한 끌림 중 하나로, 처음 봤을 때부터 끌리는 자석 같은 결이에요. 한 번 가까워지면 떨어지기 힘든 구조라, 평생 친구·연인·동업자 어느 자리로 두어도 결이 단단해져요.');
      } else if (isJiHap6) {
        attract.write(
            '지지 육합($myJi·$ptJi)이 있어서 가까워질수록 일상 호흡이 자연스럽게 맞아져요. 같이 살거나 같이 일하는 자리에 잘 어울리고, 의식하지 않아도 둘의 페이스가 합쳐지는 결이에요. 함께 한 공간에 있을 때 가장 빛나는 관계예요.');
      } else if (isJiSamhap) {
        attract.write(
            '지지 삼합 일부($myJi·$ptJi)가 맺어져 있어서 같은 목표를 향해 움직일 때 시너지가 가장 잘 나와요. 함께 프로젝트 하나, 여행 한 번, 가게 하나 만들어가는 자리가 잘 맞고, 결과를 같이 만든 경험이 관계를 두텁게 해요.');
      } else if (myEl == ptEl) {
        attract.write(
            '오행 비화(比和) — 같은 결이라 첫인상이 익숙하고, 둘만의 말투·취향·결정 속도가 빠르게 맞아져요. 굳이 설명 안 해도 통하는 자리에 같이 있을 때 편안함이 가장 커요.');
      } else if (iGenerate || theyGenerate) {
        attract.write(
            '오행 상생(相生) — 한 사람이 다른 사람을 자연스럽게 자라게 하는 결이에요. 받는 쪽은 보호받는 느낌이 크고, 주는 쪽은 자기가 만들어낸 변화에서 보람을 느껴요. 시간이 지날수록 깊어지는 관계예요.');
      } else {
        attract.write(
            '판단을 강요하지 않는 잔잔한 편안함이 매력이에요. 강한 끌림은 없지만 한 번 가까워지면 부담 없이 오래 가는 결이에요.');
      }
      if (complementary) {
        attract.write(
            ' 게다가 한 사람이 많이 가진 오행이 다른 사람이 부족한 자리를 정확히 채우는 보완 구조도 있어요. 같이 있을 때 둘 다 균형이 잡혀서 결정·건강·돈 흐름이 모두 안정돼요.');
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
    }

    // ── [3] friction — 부딪힘 (지지충 / 형 / 상극 detailed) ──────────────────────
    final friction = StringBuffer();
    if (useKo) {
      if (isClash) {
        friction.write(
            '지지 충($myJi·$ptJi)이 있어요. 일주끼리 충이 있으면 큰 결정·이사·여행·돈 결정에서 의견이 자주 엇갈려요. 사주가 말하는 한 가지 — 미리 룰을 정하는 것. "이건 누구 결정으로 가자" 같은 합의를 평소에 해두면 한 번씩 부딪힐 때도 큰 다툼으로 안 가요. 충이 있는 사이는 한 번 제대로 부딪히고 나면 오히려 깊어지는 경우가 많아요.');
      } else if (isHyeong) {
        friction.write(
            '지지 형($myJi·$ptJi)이 걸려 있어요. 한 번씩 강한 한 마디가 오갈 수 있고, 그 한 마디가 평소 누적된 작은 서운함에서 시작되는 경우가 많아요. 평소에 작은 인정과 칭찬을 자주 챙겨주는 게 큰 다툼을 막아요.');
      } else if (iOvercome || theyOvercome) {
        friction.write(
            '오행 상극이 있어서 말의 톤이 한 단계만 높아져도 통제처럼 느껴질 수 있어요. 의도와 표현의 거리가 가장 중요한 사이라, 같은 말이라도 "왜"부터 짚어주는 습관이 필요해요. 한 번 잘 풀면 둘 다 단단해지는 관계예요.');
      } else if (myEl == ptEl) {
        friction.write(
            '결이 같아서 약한 자리도 겹쳐요. 한 사람이 가라앉으면 다른 사람도 같이 가라앉기 쉬운 구조라, 둘 중 한 명이 의식적으로 다른 행동을 선택해주는 룰이 필요해요.');
      } else {
        friction.write(
            '강한 부딪힘은 없지만, 적극적인 신호가 없으면 자연스럽게 거리가 벌어질 수 있어요. 한 사람이 먼저 신호를 보내는 룰을 정해두면 관계가 흔들리지 않아요.');
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
    }

    // ── [4] actions — 3 가지 실천 (anchor 따라 맞춤) ─────────────────────────────
    final List<String> actions;
    if (useKo) {
      actions = [
        if (isClash)
          '큰 결정 (이사·여행·돈) 은 미리 룰을 정해두기 — "이런 결정은 누구 의견으로 가자" 합의 한 줄이면 충돌이 줄어요.'
        else if (isGanHap || isJiHap6)
          '천간합·지지합이 있어서 자연스럽게 가까워지는 결 — 일주일에 한 번 둘만 보내는 시간 만들기.'
        else
          '매주 한 가지 결정은 상대 의견을 먼저 듣고 정해보기.',
        if (myEl == ptEl)
          '같은 약점이 보이는 날은 둘 중 한 명이 의식적으로 다른 행동 선택 (예: 둘 다 지쳤을 때 한 명은 산책, 한 명은 휴식).'
        else if (complementary)
          '서로 부족한 오행을 카드로 공유하고, 색·음식·장소 중 하나로 작게 챙겨주기.'
        else
          '한 달에 한 번은 둘이 사주 8글자 같이 보면서 서로 어디가 강하고 어디가 약한지 확인해보기.',
        if (isHyeong || isClash)
          '평소에 작은 인정·칭찬 자주 챙기기 — 큰 한 마디 갈등은 작은 누적에서 시작돼요.'
        else if (iGenerate || theyGenerate)
          '받는 쪽이 한 번씩 고마움을 말로 전하기 — 보이지 않으면 주는 쪽이 지쳐요.'
        else
          '같이 한 가지 작은 루틴 만들기 (예: 매일 밤 한 마디 인사 / 주 1회 같이 산책).',
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

    return _CompatAnalysis(
      summary: summary.toString(),
      attract: attract.toString(),
      friction: friction.toString(),
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
