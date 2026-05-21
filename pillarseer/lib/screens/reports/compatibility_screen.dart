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
import '../../services/compat_v5_service.dart';
import '../../services/korean_josa.dart';
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
                _DetailSection(
                  me: me,
                  partner: _partner!,
                  partnerName: _partnerNameCtrl.text.trim().isEmpty
                      ? _prefilledFromCeleb
                      : _partnerNameCtrl.text.trim(),
                ),
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
  final String? partnerName;
  const _DetailSection({required this.me, required this.partner, this.partnerName});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final a = _analyze(me, partner, useKo, partnerName: partnerName);
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
      '木→火': '木→火 결은 나무가 불을 피우는 자리. 내가 한 마디 던지면 상대가 그걸 표현·실행으로 펼쳐주기 쉬운 결이에요. 창작·발표·이벤트 자리에 둘이 함께 있으면 아이디어가 또렷하게 잡히기 좋아요.',
      '火→土': '火→土 결은 불이 땅을 데우는 자리. 내 열정이 상대의 안정 자리를 따뜻하게 받쳐주기 쉬운 결이에요. 집·살림·기반 자리에 상대가 자연스럽게 둥지를 트기 좋아요.',
      '土→金': '土→金 결은 땅이 금속을 품는 자리. 내 안정감이 상대의 원칙·기준 자리를 받쳐주기 쉬운 결이에요. 정리·결정·기준 세우는 자리에서 상대가 자기 색을 펴기 좋아요.',
      '金→水': '金→水 결은 금속이 물을 맑게 거르는 자리. 내 분별력이 상대의 깊은 자리를 정제해주기 쉬운 결이에요. 내면 탐색·창작·연구 자리에서 상대가 자기 본질에 가까워지기 좋아요.',
      '水→木': '水→木 결은 물이 나무를 키우는 자리. 내 직관·이해가 상대의 새 시도 자리를 받쳐주기 쉬운 결이에요. 시작·도전·확장 자리에서 상대가 자기 가능성을 펴기 좋아요.',
      // 반대 상생 5 — B→A 형태 (theyGenerate)
      '火→木': '火→木 결은 거꾸로, 상대가 불처럼 내 나무 결을 데워주기 쉬운 자리. 상대 곁에서 내가 평소 못 내놓던 색을 자연스럽게 펴기 좋은 결이에요.',
      '土→火': '土→火 결은 거꾸로, 상대가 땅처럼 내 불의 자리를 받쳐주기 쉬운 자리. 상대 곁에 있으면 내가 들떠도 자리가 잡혀서 무리를 한 박자 늦추기 좋은 결이에요.',
      '金→土': '金→土 결은 거꾸로, 상대가 금속의 결로 내 땅을 다듬어주기 쉬운 자리. 상대 한 마디로 내가 정리해야 할 자리가 보여서, 미루던 결정을 잡아가기 좋은 결이에요.',
      '水→金': '水→金 결은 거꾸로, 상대가 물처럼 내 금속의 결을 흐르게 해주기 쉬운 자리. 평소 굳어 있던 자리가 상대 곁에서 부드럽게 풀리기 좋은 결이에요.',
      '木→水': '木→水 결은 거꾸로, 상대가 나무처럼 내 물의 자리를 끌어올려주기 쉬운 자리. 평소 잠겨 있던 생각을 상대 곁에서 행동으로 옮겨가기 좋은 결이에요.',
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
      '木·木': 'Wood·Wood — both of you tend to love starting things (trips, jobs, ventures); closing them out tends to be the shared weak spot, so unfinished projects can pile on both sides.',
      '火·火': 'Fire·Fire — together, expression tends to run big and fast; staying steady through the quiet days tends to be the weak spot.',
      '土·土': 'Earth·Earth — promises, money, and home tend to feel steady here; change and adventure tend to be where you both hesitate.',
      '金·金': 'Metal·Metal — principles and clarity tend to click; softer emotional expression tends to feel less natural for both.',
      '水·水': 'Water·Water — deep talk, inner work, and creation tend to align; deferring decisions and overthinking tend to show on both sides.',
      '木→火': 'Wood→Fire generating line — your one word, their expression. Ideas tend to take shape fast together.',
      '火→土': 'Fire→Earth generating line — your warmth tends to heat their soil; a seat where a nest is easy to build.',
      '土→金': 'Earth→Metal generating line — your steadiness tends to back their principles; a seat where their lines tend to read clear.',
      '金→水': 'Metal→Water generating line — your discernment tends to clear their depth; a seat where reaching their own essence comes easier.',
      '水→木': 'Water→Wood generating line — your intuition tends to feed their new attempts; a seat where opening into potential comes easier.',
      '火→木': 'Fire→Wood generating line (reverse) — they tend to warm your wood; colors you tend to keep in can come out easier.',
      '土→火': 'Earth→Fire generating line (reverse) — they tend to ground your fire; even when you spike, staying anchored comes easier.',
      '金→土': 'Metal→Earth generating line (reverse) — one word from them, and any cleanup you have been putting off tends to read clearer.',
      '水→金': 'Water→Metal generating line (reverse) — what felt rigid in you tends to soften beside them.',
      '木→水': 'Wood→Water generating line (reverse) — submerged thoughts tend to move into action when they are near.',
      '木→土': 'Wood→Earth overcoming line — your roots tend to crack their soil. Honoring their stability first, then suggesting the new, helps.',
      '土→木': 'Earth→Wood overcoming line (reverse) — when they prioritize stability, your new attempt can feel blocked.',
      '土→水': 'Earth→Water overcoming line — your rules tend to dam their flow. Honoring their current first, then proposing structure, helps.',
      '水→土': 'Water→Earth overcoming line (reverse) — their deep questions can shake your foundation.',
      '水→火': 'Water→Fire overcoming line — your calm word tends to cool their flame. Honoring the spark first, then adjusting tone, helps.',
      '火→水': 'Fire→Water overcoming line (reverse) — their heat tends to boil your stillness.',
      '火→金': 'Fire→Metal overcoming line — your heat tends to melt their clean lines; their standard can blur if the tone runs hot.',
      '金→火': 'Metal→Fire overcoming line (reverse) — their precision can cut off your flame.',
      '金→木': 'Metal→Wood overcoming line — your rule tends to cut their fresh attempt. Honoring the start first, then applying standards, helps.',
      '木→金': 'Wood→Metal overcoming line (reverse) — your new attempt tends to shake their principled place.',
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
      '辰·戌': 'Chen·Xu clash — both Earth, but household and finance organizing styles tend to pull in different directions.',
      '戌·辰': 'Chen·Xu clash — both Earth, but household and finance organizing styles tend to pull in different directions.',
      '丑·未': 'Chou·Wei clash — winter vs summer Earth; conservative vs expansive priorities split.',
      '未·丑': 'Chou·Wei clash — winter vs summer Earth; conservative vs expansive priorities split.',
    };
    if (clash.containsKey(pair)) return clash[pair]!;
    const hap6 = {
      '子·丑': 'Zi·Chou branch union — a quiet winter-warmth union; cafes and home spaces tend to suit it best.',
      '丑·子': 'Zi·Chou branch union — a quiet winter-warmth union; cafes and home spaces tend to suit it best.',
      '寅·亥': 'Yin·Hai branch union — a life-spark union; travel, new ventures, and moves tend to suit this pair best done together.',
      '亥·寅': 'Yin·Hai branch union — a life-spark union; travel, new ventures, and moves tend to suit this pair best done together.',
      '卯·戌': 'Mao·Xu branch union — a fire union; calm apart, the seat tends to feel livelier together.',
      '戌·卯': 'Mao·Xu branch union — a fire union; calm apart, the seat tends to feel livelier together.',
      '辰·酉': 'Chen·You branch union — a metal union; cleanup and organizing tend to be the seats you click in.',
      '酉·辰': 'Chen·You branch union — a metal union; cleanup and organizing tend to be the seats you click in.',
      '巳·申': 'Si·Shen branch union — a water union; walks, travel, and quiet time tend to suit it best.',
      '申·巳': 'Si·Shen branch union — a water union; walks, travel, and quiet time tend to suit it best.',
      '午·未': 'Wu·Wei branch union — a midsummer union; outings, parties, and festivals tend to fit it best.',
      '未·午': 'Wu·Wei branch union — a midsummer union; outings, parties, and festivals tend to fit it best.',
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
      '甲·己': "Jia·Ji union — a 'central balance' stem union; the two of you tend to click around shared responsibility.",
      '己·甲': "Jia·Ji union — a 'central balance' stem union; the two of you tend to click around shared responsibility.",
      '乙·庚': "Yi·Geng union — a 'principled' stem union; keeping promises tends to be where the two of you meet.",
      '庚·乙': "Yi·Geng union — a 'principled' stem union; keeping promises tends to be where the two of you meet.",
      '丙·辛': "Bing·Xin union — an 'authority' stem union; making decisions together tends to fit you both.",
      '辛·丙': "Bing·Xin union — an 'authority' stem union; making decisions together tends to fit you both.",
      '丁·壬': "Ding·Ren union — a 'recognition' stem union; expression, art, and romance tend to be where you click.",
      '壬·丁': "Ding·Ren union — a 'recognition' stem union; expression, art, and romance tend to be where you click.",
      '戊·癸': "Wu·Gui union — a 'silent trust' stem union; the quiet, long-standing moments tend to suit this bond.",
      '癸·戊': "Wu·Gui union — a 'silent trust' stem union; the quiet, long-standing moments tend to suit this bond.",
    };
    return ganHapPairs[pair] ?? '';
  }

  // R100 sprint 3 — 사용자 mandate verbatim: "마찬가지로 최애와 케미쪽도 엄청 반복이야
  // 1위만 보는게아니라 여러사람 볼텐데 다 비슷하거나 똑같은 형식으로 나오면 ai가
  // 만든거구나 할거같은데?". 일반 궁합 _analyze 5 섹션 본문도 같은 element-relation 짝이면
  // 100% 동일 문장이던 hotspot (baseline §6.6) 을 seed-based variant pool 로 분해.
  // 각 섹션마다 독립된 salt (summary/attract/friction/love/marriage/children/actions) 로
  // FNV-1a 32bit hash → pool index. 같은 element-relation 안에서 두 사주 day60ji 짝이
  // 다르면 다른 본문이 나오도록 한다. 또 partner 이름이 있으면 본문 안에 inject
  // (korean_josa 헬퍼로 조사 자동 보정).
  _CompatAnalysis _analyze(
    SajuResult me,
    SajuResult partner,
    bool useKo, {
    String? partnerName,
  }) {
    final myGan = me.dayPillar.chunGan;
    final myJi = me.dayPillar.jiJi;
    final ptGan = partner.dayPillar.chunGan;
    final ptJi = partner.dayPillar.jiJi;
    final myEl = me.dayPillar.chunGanElement;
    final ptEl = partner.dayPillar.chunGanElement;

    // R100 sprint 3 — variant seed (FNV-1a 32bit) helper. 같은 section salt 안에서
    // 같은 두 사주 짝은 같은 본문이 나오게 deterministic. 다른 사주 짝이면 다른 index.
    int variantSeed(String salt) {
      final base = '$salt|${me.day60ji}|${partner.day60ji}|$myGan$myJi|$ptGan$ptJi';
      var h = 0x811c9dc5;
      for (final c in base.codeUnits) {
        h ^= c;
        h = (h * 0x01000193) & 0xFFFFFFFF;
      }
      // R100 sprint 3 — xorshift32 mix.
      // FNV-1a 단독은 작은 mod 결과가 인접 입력에서 겹치는 경우 발생 (baseline §6.3
      // 의 37% slot bias 와 동일 원인). 2-pass mix 로 slot 분포를 균등화.
      h ^= (h << 13) & 0xFFFFFFFF;
      h ^= (h >> 17);
      h ^= (h << 5) & 0xFFFFFFFF;
      return h & 0xFFFFFFFF;
    }

    int pick(String salt, int poolSize) {
      if (poolSize <= 0) return 0;
      return variantSeed(salt) % poolSize;
    }

    // R100 sprint 3 — 이름 injection helpers.
    final ptName = (partnerName ?? '').trim();
    final hasName = ptName.isNotEmpty;
    final pName = hasName ? ptName : '상대';        // KO 본문에서 그대로 inject.
    final pNameKo = pName;                          // alias (가독성).
    final pNameEn = hasName ? ptName : 'the other person';
    // KO 조사 보정 (korean_josa helper). 받침 여부에 따라 이/가, 은/는, 을/를, 과/와 결정.
    final pSubj = '$pName${withSubj(pName)}';  // 이/가
    final pTop = '$pName${withTop(pName)}';    // 은/는
    final pObj = '$pName${withObj(pName)}';    // 을/를
    // ignore: unused_local_variable
    final pWith = '$pName${withWith(pName)}';  // 과/와 (직접 inject 자리 예약 — 본문 안에서 ${withWith(pName)} 인라인 호출과 호환).
    final pPossKo = '$pName 의';                // 한국어 소유격 (띄어쓰기 자연스럽게).
    // EN possessive — 자연스러운 영어 (`'s` 가 끝글자 s 이면 `'`).
    final pPoss = hasName
        ? (ptName.endsWith('s') ? "$ptName'" : "$ptName's")
        : 'their';

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

    // ── [1] summary — 첫 만남 + 오행 base + 일상 호흡 anchor ───────────────────
    // R100 sprint 3 — 6 element-relation branch × 8 KO variant + 8 EN variant.
    // pNameKo / pSubj 등은 변수 inject. branch 안에서 같은 두 사주 짝이면 deterministic.
    final summary = StringBuffer();
    String elBranchKey;
    if (myEl == ptEl) {
      elBranchKey = 'same';
    } else if (iGenerate) {
      elBranchKey = 'iGen';
    } else if (theyGenerate) {
      elBranchKey = 'tGen';
    } else if (iOvercome) {
      elBranchKey = 'iOvr';
    } else if (theyOvercome) {
      elBranchKey = 'tOvr';
    } else {
      elBranchKey = 'neut';
    }

    if (useKo) {
      // 6 branch × 8 variant = 48 KO summary 본문 pool.
      final summaryPoolsKo = <String, List<String>>{
        'same': [
          '두 사람 모두 $myEl 결을 타고난 동기예요. 처음부터 별 설명 없이도 톤이 맞아서 $pTop 너랑 비슷한 속도로 결정을 내리고 비슷한 자리에서 웃어요. 같은 결끼리는 시간을 들일수록 결이 진해지기 좋은 자리예요.\n\n다만 약점도 같이 와요. 둘 다 지친 날, 둘 다 미루는 날이 같은 날에 오니까 한 명이 의식적으로 다른 무게를 골라야 균형이 잡혀요.',
          '같은 $myEl 결을 공유해서 $pSubj 곁에 있을 때 \'설명 안 해도 되는 사이\'의 편안함이 가장 크게 와요. 좋아하는 메뉴, 결정 속도, 일상 리듬까지 닮은 결이라 첫 만남부터 익숙한 느낌이 와요.\n\n주의할 자리는 약점 동조. 한쪽이 가라앉으면 다른 쪽도 같이 가라앉는 결이라, 한 명이 \'역할 분담\' 한 가지를 정해두면 같이 가라앉는 날을 피할 수 있어요.',
          '$pSubj 너와 같은 $myEl 결이라 첫인상부터 \'어디서 본 사람 같다\'는 느낌이 와요. 좋아하는 톤·말투·결정 속도가 가깝게 가서 신뢰가 빠르게 쌓이는 결.\n\n그런데 결이 같은 만큼 약한 자리도 겹쳐요. 둘 다 운동 빠지는 날, 둘 다 결정 미루는 날이 같은 날에 와서 평소에 \'한 명은 반대로 움직이기\' 룰이 도움돼요.',
          '같은 $myEl 비화(比和) 결. $pTop 너와 가장 닮은 사람일 수 있어요. 거울 보듯 보이는 사이라 친구·동료·연인 어느 자리에 두어도 자연스럽게 합이 맞고, 굳이 잘 보이려 안 해도 편안한 자리가 만들어져요.\n\n동시에 거울이라 자기 단점이 상대 안에 보일 때 불편함도 같이 와요. 그게 자기 단점이라기보다 결이 같아서 비치는 거라는 걸 의식하면 갈등이 줄어요.',
          '$pName${withWith(pName)} 같은 $myEl 결이 만나는 자리. 같은 카페에서 같은 메뉴 시키거나 한 영화 보고 비슷한 자리에서 웃는 — 그런 자잘한 일치가 자주 발생해요. 신뢰가 빠르게 쌓이는 자리예요.\n\n약점도 같이 오기 때문에 평소에 한 명이 \'다른 무게\' 한 가지 (운동, 결정, 회복) 를 챙기는 자리를 정해두면 균형이 깨지지 않아요.',
          '둘 다 $myEl. 비화 결은 첫 자극은 약해 보여도 시간이 갈수록 단단해지는 결이에요. $pSubj 너와 같은 속도로 결정하고 같은 톤으로 표현해서 갈등이 적은 자리.\n\n다만 끌림이 자연스럽지 않은 결이라 한 명이 먼저 신호 보내는 룰이 있으면 좋아요. 익숙함을 인연으로 키우려면 의식적인 한 걸음이 가끔 필요해요.',
          '$pTop 너랑 같은 $myEl 결이라 일상에서 \'설명 안 해도 통하는 자리\'가 가장 큰 자산이에요. 결정·표현·페이스가 닮아서 단순한 친밀감을 넘어 동지 같은 결이 만들어져요.\n\n같이 가라앉는 날 한 명이 다른 자리로 한 발 빼주는 룰만 미리 정해두면 약점 동조도 충분히 관리돼요.',
          '같은 오행 결끼리는 \'동기(同氣)\'라 불리는 자리예요. 둘 다 $myEl 인 만큼 $pSubj 너의 한 마디를 듣고 \'나도 그랬어\' 하는 자리가 자주 와요. 위로보다 동의가 빠른 사이.\n\n다만 같은 결끼리는 변화가 더디고 새 자극이 약해요. 의식적으로 한 명이 다른 시도를 가져오면 관계가 정체 안 돼요.',
        ],
        'iGen': [
          '내 $myEl 결이 $pPossKo $ptEl 결을 자라게 하는 상생(相生) 자리예요. 한 마디 한 행동이 깊게 닿기 쉽고, $pSubj 곁에 있는 모습을 보면서 나도 든든해지기 쉬워요.\n\n천천히 가도 시간을 들이면 단단해지기 좋은 결이지만, 주는 쪽이라 페이스를 잃기 쉬워요. 한 달에 한 번은 자기 회복 자리를 따로 두는 게 필요해요.',
          '$pTop 너의 $myEl 한 마디로 자라는 자리예요. 결정 망설이던 자리에서 너 곁에 있으면 답이 나오고, 새로 시작하는 일에 네가 큰 영향을 주는 결.\n\n주는 쪽이 더 많이 신경 쓰는 만큼 받는 쪽 표현이 가끔 필요해요. \'덕분이야\' 한 마디가 주는 쪽 피로감을 가장 빠르게 풀어줘요.',
          '$pNameKo한테 너의 결이 자양분처럼 닿는 상생 자리. 큰 변화 한 번보다 매일의 작은 영향이 더 깊게 새겨지는 결이라, 빨리 결과 안 보여도 1년 단위로 봐도 늦지 않아요.\n\n자기 페이스를 지키는 게 가장 큰 미션이에요. 주는 쪽이 자기 자리 잃으면 결이 한쪽으로 무너져요.',
          '$pPossKo $ptEl 자리에 너의 $myEl 결이 흘러들어가요. $pSubj 너 곁에서 조금씩 자기 색을 또렷이 가지는 결.\n\n다만 보람이 자주 안 느껴질 수도 있어요. 변화는 천천히 와요. 한 분기 단위로 \'$pName 의 변화 자리\' 한 가지를 짚어보면 자기가 키운 자리가 보여요.',
          '상생 — 내 결이 $pObj 살리는 자리예요. 한 번 깊이 들어가면 떨어지기 어렵고, 곁에 있는 것만으로도 $pSubj 컨디션이 좋아지는 결.\n\n다만 \'주는 쪽\'이 평생 일방통행이 되면 안 돼요. $pNameKo 도 자기 자리에서 너한테 줄 수 있는 한 가지를 찾아두면 결이 양방향으로 흘러요.',
          '내가 자라게 하는 쪽인 자리. $pSubj 너의 곁에서 한 단계씩 자라는 모습을 보면서, 그 결과만 칭찬하지 말고 과정의 작은 변화도 알아봐 주면 결이 훨씬 단단해져요.\n\n시간이 쌓일수록 천천히 깊어지는 결이라, 조급해하지 말고 계절 단위로 길게 보세요.',
          '$myEl→$ptEl 상생 흐름. $pTop 너의 한 마디로 새로운 결을 만들어가는 자리예요. 시작·도전·확장 같은 결정 자리에 너의 영향이 가장 크게 닿아요.\n\n주의할 점은 너무 앞서 끌어주는 자리에서 $pSubj 자기 결정을 못 하게 되는 자리. 한 번씩 \'어떻게 하고 싶어?\' 먼저 묻는 결이 균형을 잡아줘요.',
          '내 결이 $pObj 자라게 하는 자리라, 평소엔 잔잔해도 $pSubj 위기일 때 가장 빠르게 회복돼요. 큰 갈등 없는 안정된 결이지만 표현이 자주 한쪽으로만 흐를 위험은 있어요.\n\n받는 쪽도 한 번씩 \'고마워\' 말로 전해야 주는 쪽이 지치지 않아요.',
        ],
        'tGen': [
          '$pPossKo $ptEl 결이 내 부족한 자리를 자연스럽게 채워주기 좋은 상생(相生) 자리예요. $pSubj 곁에 있을 때 내가 결정 망설이던 자리에서 답을 찾기 쉽고, 흔들리던 컨디션이 자연스럽게 잡히기 좋은 결.\n\n받는 쪽이 표현 자주 안 해도 $pNameKo 는 알아주지만, 한 번씩 \'덕분이야\' 말로 전해두면 받는 쪽으로만 기우는 자리를 줄이기 좋아요.',
          '$pName${withWith(pName)} 함께 있을 때 내가 \'보호받는 느낌\'이 가장 큰 결. 평소에 못 풀던 자리도 $pSubj 한 마디면 풀리는 — 그런 어른 같은 자리에 가까이 있는 사이예요.\n\n받기만 하는 사이는 시간 지나면 주는 쪽이 지쳐요. 매일 짧게라도 한 마디 표현이 결을 길게 가져가요.',
          '$pPossKo 결이 나의 약한 자리를 데우는 상생 자리예요. 같이 있는 시간만큼 내 회복 속도가 빨라지고, 흔들리던 일상이 자연스럽게 잡혀요.\n\n다만 받는 쪽도 의식적으로 $pPossKo 일상을 들여다보는 습관을 들여야 관계가 한쪽으로 기울지 않아요.',
          '$pTop 너를 자라게 하는 쪽이라, 자기도 모르게 너의 결정 속도가 $pNameKo 영향을 받아요. 결정 망설일 때 \'$pName 면 어떻게 했을까\' 떠올리는 자리도 자주 와요.\n\n받는 쪽이라 자기 결 흐려질 수 있어요. 한 분기에 한 번은 자기 자리만의 결정 한 가지를 의식적으로 가져가는 게 좋아요.',
          '받는 쪽인 상생 결. $pSubj 곁에 있을 때 흔들리던 컨디션이 가라앉기 쉬워서, 평소 너를 받쳐주는 자리에 있는 사람이에요.\n\n다만 받기만 하고 표현을 안 하면 주는 쪽이 \'알아서 잘 받고 있겠지\' 하다가 거리감을 느끼기 쉬워요. \'고마워\' 한 마디씩 챙기면 그런 거리감이 잘 안 생겨요.',
          '$myEl←$ptEl. $pPossKo 결이 내 결을 키우는 자리. 평소 잠재되어 있던 색이 $pNameKo 곁에서 자연스럽게 나오는 결이에요.\n\n받는 쪽도 한 자리에선 줄 수 있는 결이 있어야 일방통행이 안 돼요. 받기만 하는 자리에서 작은 보답 자리 한 가지 찾아두면 결이 양방향이 돼요.',
          '$pPossKo $ptEl 자리가 내 빈 자리를 채우는 결. 첫 만남에서 이미 \'안심되는 사람\' 느낌이 오고, 시간이 갈수록 그 결이 더 또렷해져요.\n\n받는 쪽이 의식적으로 자기 자리를 가꾸지 않으면 \'너 없으면 안 되는\' 결로 흘러서 둘 다 부담돼요. 자기 회복 자리를 따로 두는 결이 필요.',
          '$pSubj 곁에 있으면 흔들리던 컨디션이 자연스럽게 잡혀요. 받는 쪽이 잘 표현 안 해도 $pNameKo 한테 닿지만, 한 번씩 말로 전하면 결이 한 단계 깊어져요.\n\n주는 쪽이 평생 일방통행이 되면 안 돼요. 받는 쪽도 자기 자리에서 줄 수 있는 한 가지를 찾아두면 결이 길게 가요.',
        ],
        'iOvr': [
          '내 $myEl 결이 $pPossKo $ptEl 결을 누르는 상극(相剋) 자리예요. 처음엔 내가 주도하는 자리가 자연스럽고 $pObj 정확히 짚어내는 코치 같은 결.\n\n다만 톤이 한 단계만 높아져도 통제처럼 느껴질 수 있어요. \'이렇게 해\' 보다는 \'이렇게 하는 건 어때\' 식으로 한 단계 낮추는 결이 가장 중요해요.',
          '$pObj 한 마디로 길 잡아주는 자리에 자주 가요. 강한 자리에서 약한 자리로 흐르는 상극 결이라 내가 결정하고 $pSubj 따라오는 자연스러운 흐름.\n\n잘 다루면 $pPossKo 가장 큰 성장 코치, 잘못 다루면 $pPossKo 자기 색을 잃는 자리. 약점 짚는 만큼 강점도 같이 짚어줘야 균형이 잡혀요.',
          '$myEl→$ptEl. 누르는 쪽인 상극. $pSubj 헤매는 자리에서 내가 먼저 방향을 정해주는 자리에 자주 가지만, 강해질수록 $pNameKo 자기 결을 잃는 위험이 같이 와요.\n\n평소에 \'내 톤이 너무 강했어?\' 한 번씩 묻는 결이 필수예요.',
          '내가 주도하기 쉬운 사이예요. $pName${withWith(pName)} 함께할 때 한 단계 앞서 가는 자리가 자연스럽게 오는데, 자기도 모르게 \'$pName 의 결정\'까지 대신 가져가기 쉬워요. \'어떻게 생각해?\' 먼저 묻는 습관이 그걸 막아줘요.\n\n톤을 잘 다루면 단단해지고, 한 마디가 세지면 $pSubj 위축되기 쉬운 자리. 톤 한 단계 낮추는 게 핵심이에요.',
          '상극 결이라 첫 만남에서 자극이 강한 자리. 평소엔 부드럽다가 큰 결정에서 내가 강하게 한 마디 던지면 $pSubj 흔들리는 자리가 자주 와요.\n\n톤 관리가 평생 미션. 같은 조언이라도 표현 방식 한 단계 낮추면 $pNameKo 가장 빠르게 자라요.',
          '내 결이 $pObj 정리시키는 자리. 평소엔 도움되지만 너무 자주 짚어주면 $pSubj 자기 의견 안 내게 돼요. \'이건 네가 정해줘\' 한 번씩 비워주는 결이 균형을 잡아요.\n\n잘 다루면 $pSubj 너 곁에서 가장 빠르게 성장하는 자리.',
          '누르는 자리. 내가 강한 결인 만큼 한 마디가 $pNameKo 한테 무겁게 닿아요. 의도와 표현의 거리를 늘 의식해야 결이 길게 가요.\n\n약점 코치 자리는 보람이 크지만, $pObj 응원하는 자리를 같이 잡지 않으면 결이 한쪽으로 무너져요.',
          '$myEl 결이 $ptEl 결을 다듬는 자리. 정리·기준·룰 같은 자리에 내가 자연스럽게 앞서지만 \'내 방식이 무조건 옳다\' 모드로 들어가면 $pSubj 점점 작아져요.\n\n매주 한 번은 $pPossKo 결정 한 가지에 따라가는 자리를 의식적으로 만들면 결이 단단해져요.',
        ],
        'tOvr': [
          '$pPossKo $ptEl 결이 내 $myEl 결을 누르는 상극(相剋) 자리예요. $pName${withWith(pName)} 가까워질수록 내가 자기 색 지키는 연습이 필요한 결.\n\n잘 다루면 둘 다 단단해지지만 그 전에 서로 톤 차이를 인정하는 게 먼저예요. $pNameKo 도 한 단계 톤 낮추는 자리를 같이 만들면 점점 편해져요.',
          '$pSubj 한 마디로 내 페이스가 흔들리는 자리. 평소엔 부드럽다가 $pNameKo 강하게 한 마디 던지는 순간 내가 위축되는 결이 자주 와요.\n\n\'$pName 한 마디는 무게가 크다\' 는 걸 둘 다 의식하고, 받는 쪽인 내가 자기 결 지키는 연습을 같이 하면 결이 단단해져요.',
          '눌리는 쪽인 상극. $pNameKo 입장에선 \'솔직히 말한 건데 왜 위축되지\' 라고 느끼고, 내 입장에선 \'무겁다\' 고 느끼는 미스매치가 자주 와요.\n\n중간에 \'네 말 무게가 컸어\' 한 번씩 전하는 결이 두 사람 톤 거리를 줄여요.',
          '$pPossKo 결이 내 결을 정리시키는 자리. 시간 지나면 강한 톤이 익숙해지면서 단단해지지만, 그 전에는 자기 색 지키는 의식이 필요해요.\n\n매주 한 번은 \'내 자리에서 내 결로 결정한 자리\' 한 가지 만들어두면 결이 한쪽으로 안 무너져요.',
          '$pSubj 가진 결이 내 약점을 정확히 짚기 쉬운 자리예요. 좋게 다루면 빨리 자라는 코치 같은 자리가 되고, 톤이 세지면 받는 쪽이 자기 색을 놓치기 쉬워요.\n\n$pTop 곁에 있을 때 내가 더 단단해진다 느끼면 잘 흘러가는 거고, 점점 자기 의견을 안 내게 된다 싶으면 그때가 결을 다시 맞춰볼 자리예요.',
          '$myEl 결이 $ptEl 결에 눌리는 자리예요. $pNameKo 곁에서 내가 평소보다 조심스러워지기 쉬워요. 톤을 잘 다루면 둘 다 단단해지고, 톤이 세지면 받는 쪽이 자기 색을 놓치기 쉬워요.\n\n둘 다 의식적으로 톤 한 단계 낮추는 연습을 함께 하면 오래 가기 좋아요.',
          '강한 자리에서 약한 자리로 흐르는 상극. $pTop 자기 결이 강한 만큼 한 마디가 내 자리에 무겁게 닿아요. \'네 말 무게가 컸어\' 자주 전하면 $pNameKo 도 톤 조정 자리를 같이 가져가요.\n\n시간이 흐르면 익숙해지면서 자기 색 잃지 않게 단단해지는 자리.',
          '$pPossKo 한 마디가 내 일상에 강하게 닿는 자리예요. 평소엔 잘 지내다가 큰 결정 자리에서 내가 흔들리는 결.\n\n받는 쪽인 내가 자기 자리 지키는 의식 하나 (예: 매주 자기만의 결정 자리 한 가지) 가 있으면 결이 한쪽으로 안 기울어요.',
        ],
        'neut': [
          '두 사람 오행이 직접 생극(生剋) 관계가 없는 중립적 결이에요. 자극도 충돌도 크지 않고 첫인상은 잔잔한 결.\n\n자연스러운 끌림은 약하지만 한 번 가까워지면 부담 없이 오래 가는 자리. 가볍게 만나기 시작해도 시간이 흐를수록 깊이가 쌓이는 결이에요.',
          '$pName${withWith(pName)} 사이는 \'잊혀짐\'이 가장 큰 위험. 자극이 작아서 자기가 신경 안 쓰면 자연스럽게 거리가 벌어져요. 정기적인 약속 하나가 결을 지켜요.\n\n다만 자극이 적은 만큼 안정감이 가장 큰 결이라, 평생 곁에 두기에는 가장 편한 자리 중 하나예요.',
          '중립 결. $pSubj 너랑 \'좋네\' 정도의 잔잔한 첫인상이 오래 가는 자리. 가벼운 친구로는 편하지만 깊이는 의식적으로 만들어야 해요.\n\n\'매주 한 번 둘만 보는 시간\', \'매일 짧은 안부\' 같은 작은 의식이 있으면 자연스럽게 무게가 쌓여요.',
          '직접 생극 없는 중립의 사이. 강한 끌림은 없지만 강한 부딪힘도 없는 안정 결.\n\n자연스럽게 가까워지는 결이 아니라 한 명이 먼저 신호 보내는 룰을 정해두면 결이 흔들리지 않아요. 의식적으로 무게를 만들 때 비로소 깊이가 생겨요.',
          '$pTop 너와 자극은 작지만 편안함은 큰 결. 가까워질수록 \'없으면 허전한\' 자리에 천천히 자리잡는 결이에요.\n\n중립 결끼리는 적극적인 신호가 없으면 멀어지기 쉬워서, 정기 연락 약속 하나가 결을 길게 가게 해요.',
          '오행끼리 직접 걸린 신호가 없는 자리예요. 강하게 끌리는 느낌은 약해도, $pName${withWith(pName)} 각자 페이스 지키면서 같이 있을 때 편한 결.\n\n자연스럽게 가까워지는 힘이 약한 만큼, 한 명이 먼저 \'우리 이번 주 한 번 보자\' 보내는 자리를 자주 만들면 거리가 잘 안 벌어져요.',
          '중립 자리. 강하게 자극되는 결은 아니지만 \'부담 없이 오래 가는\' 가장 편한 결 중 하나예요. 시간이 흐를수록 잔잔한 깊이가 쌓여요.\n\n자연스러운 끌림이 없으니까 한 명이 먼저 의식적인 한 걸음을 가져오는 게 핵심.',
          '$pName${withWith(pName)} 직접 신호가 없는 결. 첫 만남에서 강한 자극은 없지만 점점 가까워질수록 \'편한 사람\' 자리에 단단히 자리잡아요.\n\n중립의 사이는 적극적 신호가 없으면 자연스럽게 멀어지는 결이라, 한 명이 먼저 룰 만드는 자리가 가장 중요해요.',
        ],
      };
      final summaryPool = summaryPoolsKo[elBranchKey] ?? summaryPoolsKo['neut']!;
      summary.write(summaryPool[pick('summary-ko', summaryPool.length)]);

      // R94 sprint 4 — element pair (예: 木→火, 子·丑) 별 specific scene 추가.
      if (elPairKo.isNotEmpty) {
        summary.write('\n\n$elPairKo');
      }
      // 일주 동일 / 일지 동일 추가 paragraph (variant 2 분기).
      if (sameDay) {
        const sameDayPool = [
          '\n\n게다가 같은 60갑자 일주를 타고났어요. 거울 보듯 닮은 면이 많아서, 한 사람이 깨달은 걸 다른 사람도 곧 따라 깨닫기 쉬운 — 두 사주가 가장 비슷한 \'동기(同氣)\' 결이에요.',
          '\n\n같은 일주를 타고난 사이. 인생의 큰 결정 시기·체질·평소 결이 거의 일치해서, 같은 시기에 같은 고민을 마주하는 결이에요.',
        ];
        summary.write(sameDayPool[pick('summary-sameDay-ko', sameDayPool.length)]);
      } else if (sameBranch) {
        final sameBranchPool = [
          '\n\n같은 일지($myJi)를 공유해서 인생 리듬·계절감·체질이 비슷해요. 함께 있는 시간 자체가 안정적인 결.',
          '\n\n띠가 같으니까 한 해 흐름·세운 영향·신체 컨디션이 비슷하게 와요. 평소 결정 속도·생활 리듬이 자연스럽게 맞춰져요.',
        ];
        summary.write(sameBranchPool[pick('summary-sameBranch-ko', sameBranchPool.length)]);
      }
    } else {
      // 6 branch × 8 variant = 48 EN summary pool. pNameEn (fallback: 'the other person')
      // / pPoss 변수 inject. 같은 element-relation 안에서도 day60ji 짝이 다르면 다른 본문.
      final n = pNameEn;
      final np = pPoss;
      final summaryPoolsEn = <String, List<String>>{
        'same': [
          'You and $n share the same $myEl element — a 比和 (same-element) match. Taste, decision speed, and daily rhythm tend to line up without much explaining. The flip side is shared weak spots: when one of you dips, the other dips easily on the same day, so a small recovery routine helps.',
          'Same $myEl element means $n speaks a language you already know. First impressions tend to feel familiar, and the warm-up time tends to be short here.',
          'You and $n run on the same element. The bond can read as easy from day one — but mirrors cut both ways, so a flaw you spot in $n may sit in you too. Naming that as element, not character, helps.',
          'A 比和 (same-element) match. With $n the small talk tends to be short and the ease comes fast. The one thing to watch is synchronized fatigue — picking days when one of you deliberately moves opposite keeps the bond ventilated.',
          'Sharing $myEl means small daily things tend to click. Tastes and timing tend to line up without much explaining — and that quiet alignment is the bond.',
          "$np element and yours run the same color — a friend-flavored love that leans durable rather than electric. Closeness here tends to build in quiet repetition, so small steady rituals matter.",
          'Same-element pair. The lift is mild but the floor is high; once close, this kind of bond can run long simply because it never strained the air.',
          'You and $n run as same-element peers. Agreement tends to run faster than novelty here, so bringing a different weight on purpose now and then keeps the bond from going static.',
        ],
        'iGen': [
          'You generate (相生) $n — a producing line. Your $myEl tends to feed $np $ptEl side, so small words can land deep. Naming what you notice in $n keeps the giving line two-way.',
          'A slow, durable generating (相生) bond. This kind of line tends to ripen season by season rather than week by week — measuring year to year fits it better than measuring month to month.',
          'You feed what $n runs on. Closeness with $n tends to make new ventures easier to start — and a thank-you said out loud now and then keeps the giver standing.',
          'A giving line. $n tends to find their footing beside you, and you tend to find meaning in shape you helped form — as long as the receiver names the help out loud sometimes.',
          'Your one word tends to turn into $np next step. This bond runs on slow, season-by-season change, so it rewards a long lens more than a short one.',
          'Generating (相生) relationships tend to ripen when you tend them. With $n the curve is slow and steady, so patience reads as the main asset here.',
          "Your $myEl tends to be fuel for $np $ptEl. Beside you, $n often finds it easier to say things they held back before. Keeping one ritual of your own matters — the giver runs dry without it.",
          'You bring the element $n was short on. New starts, hard calls, and recovery all tend to run easier with you close — and the moment $n names that out loud, the bond tends to settle.',
        ],
        'tGen': [
          "$np $ptEl tends to fill the gaps in your $myEl — a generating (相生) line toward you. When you stall, $n often unsticks you; when you wobble, $np steadiness tends to pull you back to the floor.",
          "You tend to receive more than you give here. $n may not ask for thanks, but a real one said out loud once a week is what keeps the giver standing.",
          "$n tends to be the steady current under your day. A decision you might have postponed can feel simpler beside $n, and a low mood is often easier to lift with $n near.",
          'A protective bond. With $n nearby you tend to feel the safety you used to look for — the one trap is hiding inside it and forgetting your own work.',
          "$np element tends to enter yours like a quiet teacher. Even colors you used to suppress can come out near $n — keeping one personal space anyway helps.",
          'You are on the receiving end of generating (相生). Time with $n tends to raise your floor — so bringing something only you can give keeps the lane running both ways.',
          "$n tends to carry the element you were short on. Closeness makes the gap visible, and over a season you may start noticing $np voice inside your own.",
          "Steady relief is the headline. $n tends to hold the line when you cannot, and that is real care — showing it back with a 'thanks to you' $n can actually hear keeps the bond level.",
        ],
        'iOvr': [
          'You overcome (相剋) $n — an overcoming line. You tend to lead naturally and read $np weak spots like a coach — but a notch sharper tone can read as control, so intent and delivery have to match.',
          "Your $myEl tends to edit $np $ptEl. That is useful when $n asks for direction, costlier when it shows up as default — 'how about this' tends to land far better than 'do this'.",
          "An overcoming (相剋) bond. Handled well, $n tends to grow beside you; handled poorly, $n tends to hold opinions back. Asking 'what do you think?' often is the single habit that keeps the line honest.",
          "Your call tends to settle the room. That is useful — but if you settle every call, $n loses color. Following $n on one real decision a week tends to steady the bond.",
          'You tend to see the weak point first. The strength is sharp and the cost is sharp too — pairing each critique with a real spot of praise keeps the giving line from tilting.',
          'A strong-over-soft pairing. Closeness here tends to depend on you measuring your tone — the moment that goes unnoticed, $n tends to hold back.',
          'You bring the structure — standards, lines, decisions. Building in regular asks keeps $np own voice visible alongside yours.',
          'A coach line. Handled well, $n tends to show their steadier side beside you; handled badly, $n tends to fade. The pivot is whether you also champion $np strengths out loud.',
        ],
        'tOvr': [
          "$np $ptEl overcomes (相剋) your $myEl — an overcoming line toward you. Closeness here tends to ask you to keep your color when $n speaks heavily; handled well, both sides tend to toughen.",
          "$np one word can move your day. $n is soft most of the time, but a sharper line tends to land harder than $n knows — telling $n 'that one was heavy' keeps it honest.",
          "The friction here tends to live in tone. $n often speaks plainly and means well; you may receive it a few notches louder. Both sides practice — $n softens, you stand.",
          "You're on the receiving end of overcoming (相剋). Holding one decision a week that is purely yours tends to keep the line of who-you-are bright.",
          "$np presence tends to sharpen your edges. Handled well you tend to toughen; handled badly you tend to hold opinions back — catching that slide early and naming it helps.",
          'A challenging match with high payoff. Time tends to do much of the work — $np strong tone becomes familiar — but the early phase rewards explicit tone agreements.',
          "$n tends to name the things you wish you had said. That is useful when you take it, harder when it arrives at the wrong moment — asking for one timing rule makes the rest easier.",
          'Receiving the stronger current. The bond tends to firm up once you trust that $np force is direction, not pressure — until then, holding the small claims of self helps.',
        ],
        'neut': [
          "No direct 生剋 between your $myEl and $np $ptEl — a neutral line. The interaction is mild, neither spark nor clash, so closeness here tends to grow by choice rather than by pull.",
          "A quiet pairing. With $n there is no urgency and no friction — well suited to slow trust, and easy to forget about when life gets loud, so a standing check-in helps.",
          'A neutral line. The two of you tend to click softly and drift softly. A standing weekly check-in tends to keep the line warm; without one, distance is easy to let widen.',
          "$n is the kind of person a neutral line can keep close for a long time — as long as one of you keeps reaching first. The pull here is not automatic.",
          "Comfortable but mild. With $n the room tends to stay calm and the tone even — building small rituals on purpose is what gives the bond its depth.",
          'No direct stem-branch anchor between you, but plenty in the choices. Closeness here tends to be a discipline of small signals rather than a magnetic accident.',
          "$n sits in a quiet zone relative to your day pillar. No clash means no warning bells; no spark means you light it. A monthly plan together tends to do that work.",
          'A neutral match. The bond neither pushes nor pulls — it tends to be only as deep as the attention you give it, so a habit serves it better than a single moment.',
        ],
      };
      final summaryPool = summaryPoolsEn[elBranchKey] ?? summaryPoolsEn['neut']!;
      summary.write(summaryPool[pick('summary-en', summaryPool.length)]);

      if (elPairEn.isNotEmpty) {
        summary.write(' $elPairEn');
      }
      if (sameDay) {
        const sameDayPool = [
          ' You also share the same day pillar — a mirror bond, where one of you tends to recognize the other quickly.',
          ' A shared day pillar runs underneath everything; what one of you notices tends to read familiar to the other soon after.',
        ];
        summary.write(sameDayPool[pick('summary-sameDay-en', sameDayPool.length)]);
      } else if (sameBranch) {
        final sameBranchPool = [
          ' A shared day branch ($myJi) — life rhythm tends to align here.',
          ' Sharing the $myJi branch tends to sync season, body, and pace without much effort.',
        ];
        summary.write(sameBranchPool[pick('summary-sameBranch-en', sameBranchPool.length)]);
      }
    }

    // ── [2] attract — 끌리는 지점 ─────────────────────────────────────────────
    // R100 sprint 3 — 6 branch × 4+ variant pool, summary 와 독립 salt 사용.
    final attract = StringBuffer();
    String attractBranchKey;
    if (isGanHap) {
      attractBranchKey = 'ganHap';
    } else if (isJiHap6) {
      attractBranchKey = 'jiHap6';
    } else if (isJiSamhap) {
      attractBranchKey = 'jiSamhap';
    } else if (myEl == ptEl) {
      attractBranchKey = 'sameEl';
    } else if (iGenerate || theyGenerate) {
      attractBranchKey = 'gen';
    } else {
      attractBranchKey = 'neut';
    }
    if (useKo) {
      final attractPoolsKo = <String, List<String>>{
        'ganHap': [
          '천간 오합($myGan·$ptGan) — 두 사주에서 가장 강하게 걸리는 끌림 자리 중 하나예요. $pSubj 처음 봤을 때부터 자석 같은 결이고, 한 번 가까워지면 떨어지기 어렵게 느껴지기 쉬운 사이.\n\n합이 강한 만큼 한쪽이 자기 색을 잃기 쉬워요. 처음엔 깊게 통하는 느낌이 강하게 와도, 시간이 흐를수록 각자의 페이스를 의식적으로 지키는 게 더 중요해져요.',
          '$myGan·$ptGan 천간합이 맺힌 자리. $pName${withWith(pName)} 함께 있을 때 시간이 빨리 가고, 다른 사람과 있을 때보다 자기다워지는 느낌이 자주 와요.\n\n천간합은 \'서로 보완하고 싶은 자리\'를 자극해서 만남이 자연스럽게 이어져요. 다만 합이 깊은 만큼 변형도 같이 와요. 자기 자리 한 가지는 따로 챙겨두세요.',
          '오합(五合) 중 하나인 $myGan·$ptGan 짝. 친구·연인·동업자 — 어느 자리에 두어도 결이 단단해지는 만능 합이에요.\n\n끌림이 강한 만큼 \'경계 없는 사이\'로 흐를 위험도 있어요. $pName${withWith(pName)} 함께해도 자기 페이스 한 자리는 의식적으로 지키는 결이 필요해요.',
          '천간합이 있는 사이는 첫 만남부터 \'어디서 본 사람\' 느낌이 오기 쉬워요. $pTop 거의 처음부터 편하고, 시간이 지날수록 서로의 결이 자연스럽게 섞이기 쉬운 자리.\n\n잘 다루면 오래 가기 좋은 자리예요. 다만 너무 빠르게 섞이면 한쪽 색이 묻히기 쉬워요. 한 분기에 한 번은 자기만의 결을 점검하는 자리가 좋아요.',
        ],
        'jiHap6': [
          '지지 육합($myJi·$ptJi) — 일상 호흡이 자연스럽게 맞는 결. $pName${withWith(pName)} 같이 살거나 같이 일할 때 가장 빛나는 합이에요.\n\n거창한 이벤트보다 \'같이 밥 먹기, 같이 산책\' 같은 작은 매일이 결을 단단하게 만들어요. 둘이 \'평범한 하루\'를 자주 보내면 자연스럽게 깊어져요.',
          '$myJi·$ptJi 육합. 의식하지 않아도 페이스가 합쳐지는 자리예요. $pSubj 한 공간에 있을 때 둘만의 루틴이 자연스럽게 생기는 결.\n\n같이 사는 자리, 같이 일하는 자리에 가장 어울려요. 떨어져 있을 때보다 가까이 있을 때 효력이 큰 합.',
          '육합이 있는 사이는 \'일상의 합\'이에요. $pName${withWith(pName)} 같은 공간에 있는 시간이 늘수록 결이 깊어져요.\n\n외부 이벤트가 결을 만드는 게 아니라 둘만의 작은 의식 — 매일 밤 인사, 주 1회 산책 — 이 결을 만들어요.',
          '$myJi·$ptJi 합 — 안방의 합이에요. $pTop 너랑 같은 공간에서 같은 호흡으로 살아도 어색하지 않은 자리.\n\n생활 합인 만큼 외부 자극이 약하면 잔잔하게 흘러요. 새 자극을 만드는 결정 한 가지를 분기에 한 번 가져오면 좋아요.',
        ],
        'jiSamhap': [
          '지지 삼합 일부($myJi·$ptJi) — 같은 목표를 향해 움직일 때 시너지가 가장 잘 나오는 결. $pName${withWith(pName)} 함께 프로젝트 하나 만드는 자리가 가장 잘 맞아요.\n\n평소엔 잔잔하다가도 공통 미션이 생기면 시너지가 폭발해요. 분기에 한 번 \'둘이 함께하는 프로젝트\' 한 가지를 만들어두면 결이 단단해져요.',
          '삼합은 \'목표 합\'. $pSubj 너랑 같은 방향으로 움직일 때 결과가 자연스럽게 따라와요.\n\n같이 하는 일이 없으면 결이 잔잔해지지만, 큰 일이 생기면 누구보다 단단해지는 자리. 둘만의 \'다음 시즌 목표\' 한 줄 합의가 결을 키워요.',
          '$myJi·$ptJi 삼합 partial — 결과를 같이 만든 경험이 관계를 두텁게 해요. $pName${withWith(pName)} 여행 한 번, 가게 하나 만들어가는 자리가 잘 맞아요.\n\n혼자 할 때보다 둘이 할 때 결과가 또렷한 결이라, 의식적으로 \'같이 하는 일\' 한 가지를 두는 결이 핵심.',
          '삼합 결은 활동 합. $pTop 너랑 \'같이 움직이는 자리\'가 가장 빛나요. 운동·창작·창업 — 어떤 자리든 공통 목표가 있으면 시너지 폭발.\n\n반대로 둘 다 정적인 자리에 머물면 결이 잘 안 살아요. 같이 움직이는 결정 하나가 핵심.',
        ],
        'sameEl': [
          '오행 비화(比和) — 같은 결이라 첫인상이 익숙해요. $pName${withWith(pName)} 함께할 때 말투·취향·결정 속도가 빠르게 맞아져요.\n\n비화는 \'동기\' 결이라 친구·동료·형제 자리에 가장 잘 어울려요. 끌림이 강하기보다 편함이 큰 결.',
          '같은 $myEl 결끼리 — 굳이 잘 보이려 안 해도 편한 자리. $pSubj 자기다운 표현이 가장 잘 나오는 사람이 될 수 있어요.\n\n다만 비화는 시작이 자연스럽게 일어나지 않을 수 있어요. 한 명이 먼저 신호 보내는 룰이 필요해요.',
          '비화는 \'동기 매력\'. $pName${withWith(pName)} 한 자리에 있는 시간만으로 신뢰가 쌓이는 결이에요.\n\n첫 자극이 약한 대신 시간이 갈수록 결이 진해져요. 평생 곁에 두기에는 가장 안정적인 결 중 하나.',
          '같은 결끼리는 \'같이 있는 자체가 매력\'. $pTop 너랑 같은 톤으로 사는 사람을 만난다는 게 흔치 않아요.\n\n다만 모두 비슷하면 새로움이 약하니, 가끔 한 명이 다른 자리·다른 색을 가져오는 결이 결을 살아 있게 해요.',
        ],
        'gen': [
          '오행 상생(相生) — 한 사람이 다른 사람을 자라게 하는 결. 받는 쪽은 보호받는 느낌이, 주는 쪽은 만들어낸 변화에서 보람이 와요. $pName${withWith(pName)} 시간이 갈수록 깊어지는 사이.\n\n한쪽으로 흐르는 결이라 받는 쪽도 자기 자리를 만들어두는 게 좋아요. 시간이 지나면서 역할이 바뀌는 자리가 생기면 결이 더 단단해져요.',
          '상생 결은 \'성장 매력\'. $pSubj 곁에서 한 단계씩 자기 결을 찾는 모습이 가장 큰 끌림이에요.\n\n같이 보낸 1년이 지나면 받는 쪽이 눈에 띄게 자라있고, 주는 쪽도 자부심을 느껴요. 시즌 단위로 결을 볼 수 있는 사이.',
          '$myEl·$ptEl 상생 — 한 명이 가르치고 한 명이 배우는 자리가 자연스럽게 만들어지는 결. $pName${withWith(pName)} 한 자리에 있으면 두 사람 모두 변해요.\n\n주의할 자리는 균형. 한쪽이 평생 주는 자리면 결이 무너져요. \'받는 쪽도 다른 자리에선 주는 쪽\' 으로 만드는 결이 길게 가게 해요.',
          '상생은 키우는 자리·자라는 자리가 분명한 합. $pTop 자기 결이 다른 사람 곁에서 잘 자라는 사람 중 하나일 수 있어요.\n\n시간이 쌓일수록 천천히 깊어지는 결이라, 조급해하지 말고 1년 단위로 봐도 늦지 않아요.',
        ],
        'neut': [
          '판단을 강요하지 않는 잔잔한 편안함이 매력이에요. $pName${withWith(pName)} 강한 끌림은 없지만 한 번 가까워지면 부담 없이 오래 가는 결.\n\n중립의 사이는 \'편안한 공존\'이 가장 큰 매력. 서로 자리를 침범 안 하고, 자기 페이스 유지하면서 같이 있는 자리.',
          '중립 결의 매력은 \'부담 없음\'. 부담 없이 만나고 헤어지고 다시 만나는 결이라, $pTop 평생 곁에 두기 가장 편한 결 중 하나예요.\n\n다만 자연스럽게 가까워지지 않으니 한 명이 먼저 신호 보내는 룰이 필요해요.',
          '$pSubj 너랑 강한 합도 강한 충도 없는 자리. 처음엔 자극이 약해 보이지만 시간이 지나면 \'없으면 허전한\' 자리에 천천히 자리잡아요.\n\n중립 결은 의식적인 한 걸음이 깊이를 만들어요. 정기 약속 하나가 결을 길게 가져가요.',
          '중립 자리는 의식적인 정성이 매력. $pName${withWith(pName)} 자연스럽게 끌리진 않지만 의식적으로 다가가는 결이 \'단단한 깊이\'를 만들어요.\n\n잔잔한 결끼리는 자기 색을 안 잃어도 되는 게 강점. 자기 페이스 그대로 가까워질 수 있는 자리.',
        ],
      };
      final attractPool = attractPoolsKo[attractBranchKey] ?? attractPoolsKo['neut']!;
      attract.write(attractPool[pick('attract-ko', attractPool.length)]);

      if (complementary) {
        const complementaryPool = [
          '\n\n게다가 한 사람이 많이 가진 오행이 다른 사람이 부족한 자리를 채워주는 보완 짝이에요. 두 사주가 만나면 결정·건강·돈 쪽 결이 한쪽으로 안 쏠리고 균형이 잡히기 쉬운 자리.',
          '\n\n오행 보완 신호까지 추가로 걸려 있어요. 평소 부족하다 느끼던 자리가 곁에 있을 때 자연스럽게 채워지는 \'완성\' 결.',
        ];
        attract.write(complementaryPool[pick('attract-complement-ko', complementaryPool.length)]);
      }
      if (elPairKo.isNotEmpty) {
        attract.write('\n\n$elPairKo');
      }
      if (stPairKo.isNotEmpty) {
        attract.write('\n\n$stPairKo');
      }
      if (brPairKo.isNotEmpty) {
        attract.write('\n\n$brPairKo');
      }
    } else {
      final n = pNameEn;
      final np = pPoss;
      final attractPoolsEn = <String, List<String>>{
        'ganHap': [
          'A heavenly stem union ($myGan·$ptGan) with $n — a strong pull. It tends to read magnetic early, and once close, easy to feel hard to separate.',
          "A stem union ($myGan·$ptGan). $np presence tends to complete something you didn't know was unfinished — and a pull this strong can blur individual color, so keeping one personal lane outside the bond helps.",
          "A $myGan·$ptGan five-union. Time tends to run fast beside $n, and you may sound more like yourself than you do with most people. Keeping one personal lane outside the bond on purpose helps.",
          'A $myGan·$ptGan stem union — a pull strong enough to feel sudden. Friend, partner, business — the bond tends to hold its shape across most of them. Guarding your own pace as the years stack keeps it healthy.',
        ],
        'jiHap6': [
          "A six harmony ($myJi·$ptJi) with $n. Daily breath tends to sync without much effort — it fits living or working together and reads brightest when you share space.",
          "$myJi·$ptJi is a 'home union' — small daily acts (shared meals, walks, cleaning) tend to build this bond more than big events do.",
          'A branch six-union. $np rhythm and yours tend to overlap in the everyday, so routine tends to become the love language.',
          "A $myJi·$ptJi union — closeness here tends to build the more time you share a space with $n. Presence tends to concentrate it; distance tends to dilute it.",
        ],
        'jiSamhap': [
          "A triad partial ($myJi·$ptJi) — $n and you tend to click hardest around a shared goal. Running a project, planning a trip, or building something together tends to thicken the bond.",
          'A branch triad fragment. Quiet on idle days, and lively when a real mission shows up — keeping one shared project alive each quarter suits it.',
          'A branch triad partial with $n. The pull tends to be mission-shaped, so common objectives tend to make the bond unmistakable.',
          "A $myJi·$ptJi triad piece. Movement together (sports, travel, work) tends to bring out the best of the bond; static settings tend to dull it.",
        ],
        'sameEl': [
          'A same-element match with $n — the first impression tends to read already familiar, and tone, taste, and decision speed tend to sync fast. Comfort tends to run highest in shared space.',
          'A 比和 (same-element) match. The attraction here tends to be ease rather than spark — trust tends to come early, and novelty rewards intent.',
          "Sharing $myEl with $n tends to make 'no need to explain' the love language. The flip side: starting something often rewards one of you sending the first signal.",
          'A same-element bond. With $n the version of you that comes out tends to be the unguarded one — closeness here tends to build in quiet repetition.',
        ],
        'gen': [
          'A generating (相生) bond with $n — one element quietly feeds the other. The receiver tends to feel protected; the giver tends to find meaning. Depth tends to compound when you tend it.',
          'A generating (相生) line. $n tends to shift around you, or you around $n — either way, this bond tends to run on season-by-season change.',
          "A $myEl·$ptEl generating (相生) match. The growth here tends to read clearer over a year than over a week — a long horizon fits measuring the love.",
          'A generating (相生) bond. Beside $n, new starts tend to go easier — building a reverse-flow ritual keeps the giver from running dry.',
        ],
        'neut': [
          "A quiet ease with $n that doesn't demand alignment. The pull is not strong, but a neutral line can run long once close.",
          "A neutral line with $n. Comfort tends to be the headline; depth here rewards being built on purpose, and a standing weekly check-in helps.",
          'No direct 生剋, just calm room. A neutral line tends to hold as long as someone keeps reaching first — gravity does not do the work here.',
          "$n sits in a quiet zone relative to your day pillar. No spark to chase, no clash to manage — only the small rituals you choose to make.",
        ],
      };
      final attractPool = attractPoolsEn[attractBranchKey] ?? attractPoolsEn['neut']!;
      attract.write(attractPool[pick('attract-en', attractPool.length)]);

      if (complementary) {
        const complementaryPool = [
          " The dominant element on one side tends to fill the deficit on the other — a complementary anchor that tends to show up most in how you make decisions together.",
          " A complementary anchor runs underneath: what one lacks, the other tends to hold. The bond tends to read as 'whole' early on.",
        ];
        attract.write(complementaryPool[pick('attract-complement-en', complementaryPool.length)]);
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

    // ── [3] friction — 부딪힘 ─────────────────────────────────────────────────
    // R100 sprint 3 — 5 branch × 4+ variant. 독립 salt friction-ko/en.
    final friction = StringBuffer();
    String frictionBranchKey;
    if (isClash) {
      frictionBranchKey = 'clash';
    } else if (isHyeong) {
      frictionBranchKey = 'hyeong';
    } else if (iOvercome || theyOvercome) {
      frictionBranchKey = 'overcome';
    } else if (myEl == ptEl) {
      frictionBranchKey = 'sameEl';
    } else {
      frictionBranchKey = 'mild';
    }
    if (useKo) {
      final frictionPoolsKo = <String, List<String>>{
        'clash': [
          '지지 충($myJi·$ptJi) — 두 글자가 정면으로 마주 보는 자리예요. $pName${withWith(pName)} 큰 결정(이사·여행·돈) 앞에서 의견이 엇갈리기 쉬워요. 평소엔 잘 맞다가도 \'이사 갈까\', \'여행 어디 갈래\' 같은 자리에서 방향이 다르게 나오기 쉬운 결.\n\n미리 룰을 정해두는 게 가장 큰 약이에요. \'돈 결정은 한 명, 여행 결정은 다른 한 명\' 식으로 영역을 나누면 부딪혀도 큰 다툼으로 잘 안 번져요. 충은 한 번 솔직하게 부딪히고 나면 오히려 가까워지기 쉬운 결이기도 해요.',
          '$myJi·$ptJi 일주 충(沖) — 글자끼리 정면으로 마주 보는 자리예요. 평소엔 부드럽다가도 큰 결정 앞에서 $pSubj 너랑 다른 방향을 가리키기 쉬워요.\n\n충은 부딪히면서 진심을 꺼내놓게 되는 결이라, 피하기보다 솔직하게 말하는 게 나아요. \'미리 영역 분담\' 한 줄 룰만 정해둬도 부딪힘이 큰 다툼으로 잘 안 번져요.',
          '충(沖)이 걸린 자리예요. 큰 결정 영역마다 누가 주도할지 미리 합의해두면 흔들릴 일이 줄어요. $pPossKo 결정 방식과 내 방식이 정반대로 가기 쉬운 자리거든요.\n\n충은 나쁘기만 한 게 아니에요. 솔직하게 부딪히고 진짜 마음을 꺼내놓게 되는 결이라, 룰만 잘 잡으면 오래 단단하게 가기 좋아요.',
          '$myJi·$ptJi 충. $pTop 너랑 \'밤·낮\'·\'동·서\' 같은 반대 자리에 있는 결. 평소엔 매력적인 차이지만 큰 결정 앞에서는 의식적으로 합의 룰이 필요해요.\n\n6개월에 한 번씩 \'영역 분담 룰 재조정\' 자리만 두어도 결이 길게 가요.',
        ],
        'hyeong': [
          '지지 형($myJi·$ptJi). 한 번씩 강한 한 마디가 $pName${withWith(pName)} 오갈 수 있고, 그 한 마디는 평소 누적된 작은 서운함에서 시작되기 쉬워요.\n\n작은 인정과 칭찬을 자주 챙겨주면 큰 다툼으로 잘 안 번지게 하는 데 도움돼요. \'잘했어\', \'고마워\', \'네 덕분이야\' — 하루 한 번씩 챙겨두면 작은 서운함이 큰 갈등으로 자라기 어려워요.',
          '$myJi·$ptJi 형(刑) 자리예요. 평소 잘 지내다가 한 번에 확 터지기 쉬운 결이라, 사소한 서운함을 그때그때 풀어주는 게 가장 큰 보약.\n\n다툼이 시작되면 \'화날 때 10분 자리 떨어지기\' 같은 룰이 필수예요. 한 박자 쉬는 결 한 번이 큰 충돌로 잘 안 번지게 하는 데 도움돼요.',
          '형 — 사소한 일이 갑자기 커지기 쉬운 결. $pSubj 평소엔 부드러운 만큼 한 번씩 크게 부딪힐 때 무게가 큰 자리.\n\n\'네 덕분이야\' 매일 한 마디면 누적이 잘 안 쌓여요. 다툼 자체는 자연스러운 결이라 \'다툼 후 24시간 안에 한 명이 손 내밀기\' 약속을 두면 결을 길게 가져가는 데 도움돼요.',
          '$myJi·$ptJi 三刑 partial. 작은 서운함이 누적되다가 한 번에 큰 한 마디로 터지기 쉬운 결. $pPossKo 톤이 평소보다 한 단계 높아지는 자리가 자주 올 수 있어요.\n\n평소에 \'고마워\' \'미안해\' 짧은 인정을 자주 챙기면 작은 서운함이 큰 갈등으로 자라기 어려워요.',
        ],
        'overcome': [
          '오행 상극이 있어서 말의 톤이 한 단계만 높아져도 통제처럼 느껴질 수 있어요. \'이렇게 해\'보다 \'이렇게 하는 게 어때, 왜냐면…\' 식으로 한 단계 낮추는 결이 핵심.\n\n상극은 평소엔 단단한 관계를 만들지만 톤 관리 못 하면 한쪽이 위축되기 쉬워요. \'내 톤이 너무 강했어?\' 한 번씩 묻는 결이 필수예요.',
          '$myEl·$ptEl 상극(相剋) 자리예요. 의도와 표현의 거리가 가장 중요한 사이라, 같은 말이라도 \'왜\'부터 짚어주면 잘 통해요.\n\n톤을 잘 다루면 둘 다 단단해지고, 톤이 세지면 한쪽이 점점 작아지기 쉬워요. $pName${withWith(pName)} 톤 차이를 인정하는 게 먼저예요.',
          '상극이 걸린 자리. 누르는 쪽은 자기 톤이 강한 줄 모르고, 눌리는 쪽은 점점 자기 색을 잃을 수 있어요. \'네 의견 듣고 싶어\' 한 번씩 권하는 결, \'네 말 무게가 컸어\' 한 번씩 전하는 결이 필수.\n\n시간이 지나면 익숙해지면서 단단해지는 결이지만 초반엔 의식적 룰이 핵심.',
          '$myEl→$ptEl 또는 $ptEl→$myEl 상극. $pPossKo 결이 강할 때 $pSubj 한 마디로 내 페이스가 흔들리는 자리가 자주 올 수 있어요.\n\n두 사람 모두 톤 한 단계 낮추는 연습이 필요해요. 자기 검열이 아니라 \'배려된 표현\' 자리. 잘 잡으면 오래 가기 좋은 자리예요.',
        ],
        'sameEl': [
          '결이 같아서 약한 자리도 겹쳐요. $pName${withWith(pName)} 함께 가라앉기 쉬운 자리라, 둘 중 한 명이 의식적으로 다른 행동을 골라주는 룰이 필요해요.\n\n비화 사이는 \'역할 분담\' 룰이 효과 커요. 둘 다 지친 날 한 명은 산책 한 명은 휴식, 자잘한 분담이 같이 가라앉는 날을 피하게 해줘요.',
          '같은 $myEl 결끼리는 약점도 동조해요. 같이 피곤한 날, 같이 결정 미루는 날이 자주 겹쳐요. $pSubj 자기 단점처럼 보이는 결도 사실은 \'결이 같아서 비치는\' 거리.\n\n그 차이를 의식하면 갈등이 줄어요. 거울이라 자기 단점 같아 보일 수 있다는 걸 둘 다 인지하는 결이 핵심.',
          '비화 자리의 충돌. 자극은 적지만 \'같이 가라앉기\'가 가장 큰 위험이에요. $pPossKo 일상이 흔들리는 날은 내가 반대로 움직이는 결, 내가 흔들리는 날은 $pSubj 반대로 움직이는 결이 결을 잡아줘요.\n\n같은 결끼리는 다툼보다 매너리즘이 위험. 새 자극을 의식적으로 만들면 결이 살아 있어요.',
          '같은 $myEl. 부딪힘 자체는 약해도 약점 동조가 강해요. 한 명이 가라앉으면 다른 명도 같이 가라앉는 자리. $pName${withWith(pName)} 평소에 \'다른 무게\' 한 가지를 정해두면 같이 가라앉는 날을 피할 수 있어요.',
        ],
        'mild': [
          '강한 부딪힘은 없지만, 적극적인 신호가 없으면 거리가 슬슬 벌어지기 쉬워요. $pName${withWith(pName)} 정기적으로 연락하는 약속 하나가 그걸 막아줘요.\n\n이런 결에선 다툼보다 \'서로 잊고 지내기\'가 더 큰 위험. \'우리 이번 주 한 번 보자\' 한 마디 먼저 보내는 자리를 자주 만들면 거리가 안 벌어져요.',
          '중립 결이라 충돌이 적은 만큼 깊이도 자연스럽게 안 생겨요. $pSubj \'특별히 갈등은 없는데 왜 멀어지지\' 느낌이 올 때, 그건 자연스러운 끌림이 없는 결이라서 그래요.\n\n의식적인 정성이 깊이를 만드는 사이. 한 명이 먼저 신호를 보내는 룰을 정해두면 결이 흔들리지 않아요.',
          '$pTop 자극도 충돌도 큰 자리가 아니에요. 잔잔한 결인 만큼 한 명이 신경 안 쓰면 자연스럽게 거리가 벌어지는 결.\n\n매주 정기 약속 하나, 매일 짧은 안부 한 마디 — 작은 의식이 결을 지켜요.',
          '직접 신호가 없는 중립. $pName${withWith(pName)} 부딪힘이 거의 없는 자리지만 그만큼 끌림도 약해요. 의식적으로 정성 들이는 결이 깊이를 만들어요.',
        ],
      };
      final frictionPool = frictionPoolsKo[frictionBranchKey] ?? frictionPoolsKo['mild']!;
      friction.write(frictionPool[pick('friction-ko', frictionPool.length)]);
      if (brPairKo.isNotEmpty) {
        friction.write('\n\n$brPairKo');
      }
      if (elPairKo.isNotEmpty) {
        friction.write('\n\n$elPairKo');
      }
    } else {
      final n = pNameEn;
      final np = pPoss;
      final frictionPoolsEn = <String, List<String>>{
        'clash': [
          "A branch clash ($myJi·$ptJi) with $n. Friction tends to show up in big calls — moves, money, travel. Agreeing on the rule first ('this kind of call goes your way') tends to keep small bumps from turning into fights.",
          "A $myJi·$ptJi clash. With $n the everyday tends to read calm, but choice points tend to fork. Pre-allocating decision domains ('travel — yours, money — mine') tends to steady the line.",
          "A clash on the day-branch. This kind of bond often eases after one honest collision — naming what is real to $n tends to help more than avoiding it.",
          "$myJi·$ptJi opposes. $np direction and yours tend to run on opposite axes (night/day, east/west, move/settle) — useful contrast in steady weather, harder in storms, so agreements help.",
        ],
        'hyeong': [
          "A branch punishment ($myJi·$ptJi). Sharp words can surface with $n, usually from small things piling up — a daily 'thanks' or 'good job' tends to keep the big blow-up away.",
          "A $myJi·$ptJi 三刑 partial. Quiet stretches and a sudden spike — catching the small things while they are small tends to keep the spike from building.",
          "Punishment branches. $n tends to speak plainly most days, then once in a while the volume can jump — a 'pause 10 minutes' rule for those moments helps.",
          "A $myJi·$ptJi punishment with $n. The structural fix tends to be daily acknowledgment — 'I saw what you did, thanks' — which helps keep most explosions from building.",
        ],
        'overcome': [
          "An overcoming line — a notch sharper tone can read as control. Leading with 'why' before 'what' helps; worked through, both sides tend to toughen.",
          "A $myEl·$ptEl overcoming line with $n. Softening imperatives by one degree ('how about…' instead of 'do this') tends to drop the friction fast.",
          "An overcoming (相剋) line. The stronger side often doesn't notice the weight, and the receiving side tends to hold back — asking each other 'was that too sharp?' regularly keeps the bond honest.",
          "An overcoming match. With time the louder voice tends to become familiar and the quieter one tends to stop shrinking — but the early phase rewards explicit tone agreements.",
        ],
        'sameEl': [
          "Sharing the same element with $n means sharing the same weak spots. When one of you dips, the other tends to follow — so one of you choosing a different move on those days helps.",
          "A 比和 (same-element) line. Fights tend to be rare, simultaneous slumps common — pre-allocating 'opposite-day rules' (one walks, one rests) helps.",
          "Same-element friction tends to be parallel sinking, not collision. $np low day and yours tend to arrive on the same calendar — asymmetry, not negotiation, is the cure.",
          "A $myEl·$myEl pair. A shadow you spot in $n is often one you carry too — recognizing 'that's element, not character' helps defuse most small fights.",
        ],
        'mild': [
          "No sharp clash with $n, but the gap can widen without small signals. Agreeing on who reaches out first when the chat goes quiet helps.",
          "A quiet, neutral line. The risk here tends to be being forgotten, not being hurt — a recurring check-in helps keep the bond warm.",
          "A mild interaction. Nothing pushes, nothing collides — whoever reaches out first does the real work of holding the line.",
          "$n and you share no direct stem-branch anchor. Distance tends to grow without small signals, and closeness tends to grow by choice — so choose, on a calendar.",
        ],
      };
      final frictionPool = frictionPoolsEn[frictionBranchKey] ?? frictionPoolsEn['mild']!;
      friction.write(frictionPool[pick('friction-en', frictionPool.length)]);
      if (brPairEn.isNotEmpty) {
        friction.write(' $brPairEn');
      }
      if (elPairEn.isNotEmpty) {
        friction.write(' $elPairEn');
      }
    }

    // ── [4] actions — 실천 (anchor 따라 5~7개 + 자세한 설명) ────────────────────
    final List<String> actions;
    // R100 sprint 3 — 각 slot 4+ variant pool, seed 분기로 같은 branch 안에서도 변별.
    String aPick(String slot, List<String> pool) =>
        pool[pick('actions-$slot', pool.length)];
    if (useKo) {
      // slot1 — 큰 자리 룰
      List<String> slot1;
      if (isClash) {
        slot1 = [
          '【큰 결정 룰 정하기】 이사·여행·돈·자녀 같은 큰 결정 영역마다 \'누가 주도\'할지 미리 합의해두세요. 한 줄 룰이면 충돌 빈도가 절반으로 줄어요.',
          '【영역 분담】 충이 있는 사이는 큰 결정에서 부딪혀요. \'돈 결정은 한 명, 여행 결정은 다른 한 명\' 식으로 미리 영역을 나누면 다툼이 안 와요.',
          '【6개월 재조정 룰】 충 자리의 룰은 한 번 정하고 끝이 아니에요. 6개월에 한 번 \'어느 자리가 잘 작동했고 어느 자리가 안 됐는지\' 재조정 자리를 두세요.',
          '【큰 결정 24시간 룰】 큰 자리 결정은 \'그 자리에서 답하지 말고 24시간 자고 다시 보기\' 룰을 추가하세요. 충 자리는 즉답이 가장 위험한 시점.',
        ];
      } else if (isGanHap || isJiHap6) {
        slot1 = [
          '【둘만의 시간 보호】 합이 있어서 자연스럽게 가까워지지만 외부 일정에 같이 휩쓸리기 쉬워요. 일주일에 한 번은 둘만 보내는 시간을 캘린더에 박아두세요.',
          '【자기 페이스 한 자리】 합이 강한 만큼 한쪽이 색을 잃기 쉬워요. 매주 한 자리는 \'나만의 시간\' 으로 두세요. 합이 깊을수록 자기 자리도 깊어야 결이 단단해져요.',
          '【주 1회 둘만 의식】 외부 약속이 들어와도 \'이 자리는 못 바꿔\' 라고 지킬 수 있는 한 시간을 약속해두세요. 합 결의 보약.',
          '【월 1회 둘만 외출】 합이 있는 결은 \'함께 보낸 시간\' 그 자체가 결을 키워요. 매달 1회 둘만 외출 자리를 캘린더에 박아두세요.',
        ];
      } else {
        slot1 = [
          '【의견 먼저 듣기】 매주 한 가지 결정은 $pPossKo 의견을 먼저 묻고 정해보세요. 작은 결정부터 시작해서 큰 결정으로 확장하는 결이에요.',
          '【$pName 의 결정 자리】 매주 한 번은 $pName${withWith(pName)} 결정 자리를 따라가보세요. \'내가 먼저\' 자리에서 \'$pName 먼저\' 자리로 바꿔보는 결.',
          '【먼저 묻기 의식】 결정을 내릴 때 \'$pSubj 어떻게 생각해?\' 한 번 묻는 결을 의식적으로 가져가세요. 의식적인 \'먼저 듣기\' 습관이 가장 큰 약.',
          '【공동 결정 노트】 한 주에 한 번, 둘이 같이 결정한 자리 한 가지를 노트에 남겨보세요. 같은 결정을 같이 해본 기록이 결을 단단하게 해요.',
        ];
      }
      // slot2 — 결 보완
      List<String> slot2;
      if (myEl == ptEl) {
        slot2 = [
          '【역할 분담 룰】 같은 결이라 약한 자리도 같이 와요. \'한 명이 산책 한 명이 휴식\', \'한 명이 결정 한 명이 따라가기\' 식 분담 룰을 미리 정해두세요.',
          '【반대로 움직이는 자리 하나】 둘 다 지친 날, $pSubj 산책 가면 나는 휴식. 반대로 내가 가라앉는 날 $pTop 다른 움직임. 동조 자리를 깨는 결이 핵심.',
          '【같은 일주 거울 룰】 비화 결끼리 단점이 거울처럼 비춰져요. \'$pName 의 단점은 내 단점이 아니야\' 자주 의식하면 갈등이 줄어요.',
          '【새 자극 분기에 한 번】 같은 결끼리는 정체가 위험. 분기에 한 번 \'새 자리·새 시도\' 한 가지를 가져오는 결이 결을 살아 있게 해요.',
        ];
      } else if (complementary) {
        slot2 = [
          '【보완 의식 챙기기】 서로 부족한 오행을 카드로 공유하고, 색·음식·장소·계절 중 하나로 작게 챙겨주세요.',
          '【$pName 부족 오행 한 가지】 $pPossKo 부족한 오행을 알아두고, 그 색·음식·장소 중 하나를 매주 한 번 챙겨주세요. 작은 챙김이 결을 키워요.',
          '【월 1회 보완 체크】 한 달에 한 번 둘이 \'요즘 부족한 자리\' 한 가지씩 말해보세요. 보완 결이 있는 사이는 말로 꺼내놓으면 자연스럽게 채워져요.',
          '【계절 보완 의식】 봄·여름·가을·겨울 각 계절마다 부족한 오행 자리 한 가지씩 챙겨주는 결. 보완 결의 핵심은 \'계절 단위 챙김\'.',
        ];
      } else {
        slot2 = [
          '【사주 같이 보기】 한 달에 한 번은 둘이 사주 8글자 같이 보면서 서로 어디가 강하고 어디가 약한지 확인해보세요.',
          '【$pPossKo 8글자 한 번 점검】 $pName${withWith(pName)} 사주 강한 자리·약한 자리를 한 번 같이 본 적이 있나요? 한 번이라도 같이 보면 결이 깊어져요.',
          '【월 1회 결 점검 자리】 한 달에 한 번 \'요즘 우리 결\' 자리 한 시간을 두세요. 잘 풀린 자리, 아쉬운 자리, 다음 달 한 가지 — 세 줄이면 충분해요.',
          '【객관적 기준 자리】 평소엔 안 보이던 자기 단점이 사주 8글자에는 객관적으로 보여요. 같이 점검하는 결이 평소엔 안 나오는 대화를 만들어줘요.',
        ];
      }
      // slot3 — 일상 의식
      List<String> slot3;
      if (isHyeong || isClash) {
        slot3 = [
          '【작은 인정 자주 챙기기】 \'잘했어\', \'고마워\', \'네 덕분이야\' 한 마디씩 자주 챙기세요. 큰 갈등은 작은 누적에서 시작돼요.',
          '【매일 한 마디 인정】 $pName 한테 매일 한 마디 인정을 챙기는 결. 평범한 자리에 \'네 덕분이야\' 한 마디씩 두면 작은 서운함이 큰 충돌로 자라기 어려워요.',
          '【화날 때 10분 자리 떨어지기】 다툼이 시작되면 한 박자 쉬는 룰을 미리 정해두세요. \'화날 때 10분 따로 있기\' 합의가 큰 충돌로 잘 안 번지게 하는 데 도움돼요.',
          '【사소한 서운함 그때그때 풀기】 형·충 결은 작은 서운함이 쌓이면 한 번에 터지기 쉬워요. 그때그때 \'요거 좀 서운했어\' 가벼운 한 마디가 누적을 막아줘요.',
        ];
      } else if (iGenerate || theyGenerate) {
        slot3 = [
          '【받는 쪽이 표현 챙기기】 받는 쪽이 한 번씩 \'덕분이야\' 말로 전해주세요. 침묵이면 주는 쪽이 지쳐요. 한 줄 톡 하나면 충분.',
          '【주는 쪽 자기 회복 자리】 주는 쪽이 한 달에 한 번 자기 회복 자리를 따로 두세요. $pName 한테 잘하느라 자기 자리 잃으면 결이 무너져요.',
          '【$pName 의 변화 자리 알아채기】 분기에 한 번, $pName 곁에서 자라난 자리 한 가지를 짚어주세요. 변화 알아챔이 가장 깊은 보답.',
          '【역할 바뀌는 자리 하나】 받는 쪽이 다른 자리에서 주는 쪽이 되는 결이 있으면 결이 단단해져요. 일주일에 한 자리는 받는 쪽이 챙기는 자리를 만드세요.',
        ];
      } else {
        slot3 = [
          '【작은 공동 루틴】 같이 한 가지 작은 루틴 만들기. 매일 밤 \'잘 자\' 한 마디, 주 1회 같이 산책, 매달 같이 보는 영화 한 편 — 자잘한 루틴이 깊이를 만들어요.',
          '【주 1회 둘만 약속】 중립 결은 \'잊혀짐\'이 위험. 매주 한 번 둘만의 약속을 캘린더에 박아두세요. 정기성이 결을 지켜요.',
          '【매일 짧은 안부】 매일 한 마디라도 안부 톡을 챙기는 결. $pName 한테 매일 한 줄이면 충분해요. 작은 정기성이 깊이를 만들어요.',
          '【매달 둘만의 자리】 한 달에 한 번은 외부 약속 없이 둘만 보내는 자리. 식사든, 산책이든, 영화든 — 매달 한 번 의식이면 결이 단단해져요.',
        ];
      }
      // slot4 — 다툼 룰 (항상 포함)
      final slot4 = <String>[
        '【다툼 후 24시간 룰】 어떤 사이든 다툼은 와요. \'다툰 후 24시간 안에 한 명이 먼저 손 내밀기\' 룰을 미리 정해두면 작은 다툼이 큰 단절로 안 갑니다.',
        '【먼저 손 내밀 사람 정하기】 다툼 자리에서 누가 먼저 사과할지 평소에 정해두는 결. 그 한 자리만 결정해두면 작은 다툼은 거의 사라져요.',
        '【다툰 다음 날 짧은 안부】 다툰 다음 날 짧은 안부 한 마디 — \'잘 잤어?\' 한 마디가 큰 단절을 막아요. 누가 먼저 보낼지 미리 합의해두세요.',
        '【감정 식힌 후 대화 재개】 격한 감정 자리에서는 대화를 미루는 결. 24시간 후 식은 머리로 다시 시작하는 룰을 미리 합의해두면 결이 안 무너져요.',
      ];
      // slot5 — 톤·점검
      List<String> slot5;
      if (iOvercome || theyOvercome) {
        slot5 = [
          '【톤 한 단계 낮추기 연습】 상극 결이라 톤이 자기도 모르게 강해질 수 있어요. \'이렇게 해\' → \'이렇게 하는 게 어때, 왜냐면…\' 식으로 한 단계 낮추는 연습.',
          '【내 톤 점검 한 번씩】 누르는 쪽은 자기 톤이 강한 줄 모르기 쉬워요. 일주일에 한 번 \'내 톤이 강했어?\' 묻는 결이 결을 잡아줘요.',
          '【$pPossKo 의견 먼저 묻기】 강한 결인 만큼 \'$pName 의견 듣고 싶어\' 한 번씩 권하는 결이 필수. 받는 쪽이 자기 색을 잃지 않게 해요.',
          '【배려된 표현 자리 하나】 같은 말을 한 단계 부드럽게 다시 말하는 연습. \'네 말 무게가 컸어\' 한 번씩 전하는 결이 두 사람 톤 거리를 줄여요.',
        ];
      } else {
        slot5 = [
          '【1년에 한 번 관계 점검】 매년 같은 날 (만난 날, 새해 첫날 등) 둘이 1년을 되돌아보면서 \'잘된 자리·아쉬운 자리·다음 해 목표\' 한 가지씩 적어보세요.',
          '【계절마다 결 점검】 봄·여름·가을·겨울 각 시작에 한 번씩 짧은 결 점검 자리. \'요즘 우리 어때?\' 한 시간이면 충분해요.',
          '【$pName${withWith(pName)} 연 1회 결 정리】 매년 한 번 \'우리 결의 강점·약점\' 한 줄씩 정리하는 결. 그 기록이 5년 후 결을 지켜요.',
          '【월 1회 짧은 결 자리】 한 달에 한 번 \'요즘 우리 한 줄\' 자리. 길게 안 해도 돼요. \'요즘 잘 가고 있는 자리·아쉬운 자리\' 한 줄씩이면 충분.',
        ];
      }
      actions = [
        aPick('slot1-ko', slot1),
        aPick('slot2-ko', slot2),
        aPick('slot3-ko', slot3),
        aPick('slot4-ko', slot4),
        aPick('slot5-ko', slot5),
      ];
    } else {
      final n = pNameEn;
      final np = pPoss;
      List<String> slot1;
      if (isClash) {
        slot1 = [
          'Pre-agree rules on big decisions (move, travel, money) — one line of consensus tends to keep things from escalating.',
          "Allocate decision domains in advance with $n ('travel — yours, money — mine'). Domain rules tend to keep clashes from escalating.",
          'Revisit the rule set every six months — static rules tend to grow brittle in clash pairs.',
          'For big calls, add a 24-hour-sleep-on-it rule. Snap answers tend to be the riskiest move in a clash bond.',
        ];
      } else if (isGanHap || isJiHap6) {
        slot1 = [
          'A stem/branch union means closeness comes naturally — protecting one weekly time slot for just the two of you helps.',
          "Strong unions can swallow personal pace. Keeping one solo hour per week tends to keep the bond healthier.",
          "Calendar one 'only us' ritual that outside plans cannot move — a union tends to do well with a reliable anchor.",
          "Book a monthly just-the-two-of-you outing. Time together tends to be what this bond runs on.",
        ];
      } else {
        slot1 = [
          'Once a week, let $n go first on one real decision.',
          "Ask $n 'what do you think?' before answering — the habit alone tends to reshape the dynamic.",
          'Keep a small shared decisions log — one line per week of a call you made together.',
          'Try a weekly hand-off: $n picks Saturday plans, you pick midweek. Small rotations tend to build trust faster than negotiation.',
        ];
      }
      List<String> slot2;
      if (myEl == ptEl) {
        slot2 = [
          'On the days you both feel low, one of you picks the opposite move.',
          "Pre-allocate 'opposite-day' rules with $n. One walks, the other rests; one decides, the other follows.",
          "Recognise that a flaw you see in $n is often the one you share. Naming it 'element, not character' tends to defuse a lot of the small fights.",
          'Bring one new stimulus per quarter — a different activity, a new place. Same-element pairs tend to go static without it.',
        ];
      } else if (complementary) {
        slot2 = [
          "Cover each other's weaker element — one small habit each (color, food, place).",
          "Learn $np missing element and weave it into one weekly gesture. Small care tends to carry a big resonance.",
          'Hold a monthly check on what each of you is short on right now. With $n, naming the gap tends to close it.',
          "Tune the complement to the season — a different missing-element gesture for spring, summer, fall, winter.",
        ];
      } else {
        slot2 = [
          'Once a month, sit down together and name where each of you runs strong and where each runs thin.',
          "Walk through each other's strong spots and thin spots together once — one honest sit-down tends to surface patterns hours of arguing cannot.",
          'Hold a monthly hour of relationship review — what worked, what stung, one focus for next month.',
          'Let an honest map of who runs strong where sit in the room as a neutral third reference — it tends to surface things neither of you would raise alone.',
        ];
      }
      List<String> slot3;
      if (isHyeong || isClash) {
        slot3 = [
          "A small 'thanks' or 'good job' every day — most big fights tend to start from small slights piling up.",
          "Send one acknowledgment to $n daily. The cumulative effect tends to outperform big gestures by a wide margin.",
          "When tension spikes, take a 10-minute pause. Walk out, breathe, come back — the single rule that tends to keep most explosions from building.",
          "Surface small disappointments early — one quick 'that one hurt a little' line tends to stop the silent stack.",
        ];
      } else if (iGenerate || theyGenerate) {
        slot3 = [
          "The one being supported says 'thanks' out loud once in a while — silent gratitude tends to burn the giver out.",
          "Whoever is giving — book a monthly recovery hour for yourself. Giving tends to run dry without it.",
          "Name one growth moment in $n every quarter. Being seen tends to be the deepest thank-you.",
          "Once a week, let the receiver give something small back. Two-way flow tends to keep the bond from tilting.",
        ];
      } else {
        slot3 = [
          'Build one small shared habit (a nightly text, a weekly walk).',
          "Set a recurring weekly meet with $n — neutral pairs tend to run on calendars, not gravity.",
          'A daily one-line check-in (even just a meme) tends to keep the line warm. Tiny rhythm tends to beat grand gestures here.',
          "Reserve one no-outside-plans evening per month for just the two of you. The smallest ritual tends to help the bond stay close.",
        ];
      }
      final slot4 = <String>[
        "Pre-decide a 24-hour rule: whoever notices first reaches out after a fight. Small fights tend to stay small that way.",
        "Agree in advance who apologizes first. With $n it doesn't have to be 'fair' — it helps if it's consistent.",
        "After a fight, send a short check-in the next day — 'sleep ok?' tends to carry more than the long talk that follows.",
        "Hot heads delay the talk. Pre-agreeing to wait 24 hours lets cool minds finish what fired words started.",
      ];
      List<String> slot5;
      if (iOvercome || theyOvercome) {
        slot5 = [
          "Practice softening one notch — 'do this' → 'how about this, because…'.",
          "Ask weekly: 'was my tone too sharp?' Overcoming pairs tend to need the question more than the answer.",
          "Invite $np opinion explicitly. The stronger voice making room is the single discipline that tends to protect the receiving side.",
          "Re-phrase one sentence per week into a softer version. Practising in calm water tends to make it land in storm water.",
        ];
      } else {
        slot5 = [
          "Once a year, review the relationship together — one strong point, one regret, one goal for next year.",
          "At each season change, hold a short 'how are we?' hour with $n. Four times a year tends to keep the bond clean.",
          "Write one line a year on the bond's strengths and weak spots. Five years of those lines tend to outline the shape of your story together.",
          "Once a month, swap one line on 'how we're doing'. Short rhythm tends to prevent long surprises.",
        ];
      }
      actions = [
        aPick('slot1-en', slot1),
        aPick('slot2-en', slot2),
        aPick('slot3-en', slot3),
        aPick('slot4-en', slot4),
        aPick('slot5-en', slot5),
      ];
    }

    // ── [5] loveMarriage — 연애·결혼·자녀 ─────────────────────────────────────
    // R100 sprint 3 — 6 love branch + 5 marriage + 3 children, 각 4+ variant.
    // 독립 salt love/marriage/children. 같은 element-relation 짝이라도 day60ji 짝이
    // 다르면 다른 본문이 나옴.
    final loveMarriage = StringBuffer();
    String loveBranchKey;
    if (isGanHap) {
      loveBranchKey = 'ganHap';
    } else if (isJiHap6 || isJiSamhap) {
      loveBranchKey = 'jiHap';
    } else if (isClash) {
      loveBranchKey = 'clash';
    } else if (iOvercome || theyOvercome) {
      loveBranchKey = 'overcome';
    } else if (myEl == ptEl) {
      loveBranchKey = 'sameEl';
    } else {
      loveBranchKey = 'neut';
    }
    String marriageBranchKey;
    if (isClash) {
      marriageBranchKey = 'clash';
    } else if (isHyeong) {
      marriageBranchKey = 'hyeong';
    } else if (iGenerate || theyGenerate || isGanHap || isJiHap6 || isJiSamhap) {
      marriageBranchKey = 'union';
    } else if (iOvercome || theyOvercome) {
      marriageBranchKey = 'overcome';
    } else {
      marriageBranchKey = 'neut';
    }
    String childrenBranchKey;
    if (myEl == ptEl || iGenerate || theyGenerate || isGanHap || isJiHap6 || isJiSamhap) {
      childrenBranchKey = 'harmonious';
    } else if (isClash || isHyeong || iOvercome || theyOvercome) {
      childrenBranchKey = 'frictioned';
    } else {
      childrenBranchKey = 'neut';
    }
    if (useKo) {
      // 연애
      final lovePoolsKo = <String, List<String>>{
        'ganHap': [
          '【연애】 천간합($myGan·$ptGan)이 걸린 사이예요. 두 사주가 가장 강하게 끌리는 연애 결이라, $pName${withWith(pName)} 처음부터 자연스럽게 가까워지기 쉬워요. 합이 강한 만큼 평소에 \'나만의 시간\' 한 자리는 꼭 챙겨두세요.',
          '【연애】 $myGan·$ptGan 천간합 — 자석처럼 끌리는 결이에요. 데이트가 길어지고 함께 있을 때 시간이 빨리 가기 쉬워요. 자기 페이스 한 자리만 지키면 오래 가기 좋은 사랑.',
          '【연애】 천간합 — 강하게 끌리기 쉬운 결이지만 합이 깊은 만큼 자기 색을 잃기 쉬워요. $pName${withWith(pName)} 가까워질수록 자기만의 자리 한 가지를 의식적으로 챙기세요.',
          '【연애】 천간합이 맺힌 결. 자연스러운 끌림이라 시작은 쉽지만, 깊어질수록 두 사람 결이 섞여서 \'내 자리\' 가 흐려질 위험이 있어요. 자기 자리 한 자리는 꼭.',
        ],
        'jiHap': [
          '【연애】 지지합이 있어서 일상에서 자연스럽게 가까워지는 결이에요. $pName${withWith(pName)} 데이트보다 같이 보내는 평범한 하루가 더 중요한 사이.',
          '【연애】 일상의 합. 거창한 이벤트보다 같이 영화 보고 같이 밥 먹고 같이 산책하는 자잘한 자리가 연애의 핵심이에요.',
          '【연애】 지지합 — 둘만의 루틴이 단단해질수록 깊이가 커져요. $pSubj 같이 있는 시간이 늘수록 결이 진해지는 사이.',
          '【연애】 지지합 연애. 외부 자극보다 둘만의 일상 자리가 가장 큰 매력. 데이트 횟수보다 \'같이 보낸 일상의 시간\' 이 결을 키워요.',
        ],
        'clash': [
          '【연애】 지지 충이 있어서 연애 자체는 강렬하지만 큰 결정 앞에서 자주 부딪히는 결이에요. $pName${withWith(pName)} 미리 룰을 정해두는 게 도움돼요.',
          '【연애】 충이 있는 연애는 자극이 큰 만큼 부딪힘도 큰 결. 한 번 크게 부딪히고 나면 오히려 깊어지는 사이라, 솔직하게 말하는 결이 더 중요해요.',
          '【연애】 $myJi·$ptJi 충 연애. 평소엔 매력적인 차이가 큰 결정 자리에서 충돌로 와요. \'어디 갈래\', \'언제 만날래\' 부터 미리 합의 자리를 만들어두세요.',
          '【연애】 충 결 연애의 매력은 \'다름이 만드는 자극\'. 다만 큰 결정 자리에서는 미리 룰을 정해두는 결이 결을 길게 가져가요.',
        ],
        'overcome': [
          '【연애】 상극 결이라 처음엔 자극이 강한 연애로 시작해요. 누르는 쪽이 결정하고 눌리는 쪽이 따라가는 자리가 자연스럽게 나오지만, 톤 관리 못 하면 한쪽이 위축돼요. \'$pPossKo 의견 어때\' 자주 묻는 결이 핵심.',
          '【연애】 상극 자리 연애. 강한 자극이 매력이지만 누르는 쪽 톤이 강하면 받는 쪽이 작아져요. 두 사람 모두 톤 한 단계 낮추는 연습이 평생 미션.',
          '【연애】 상극 결은 \'자라는 연애\'. $pName${withWith(pName)} 한쪽이 다른 쪽을 깎고 다듬는 결이라 잘 풀면 둘 다 단단해지지만 잘못 풀면 한쪽이 사라져요.',
          '【연애】 상극 — 자극이 큰 만큼 톤 관리가 핵심. \'네 말 무게가 컸어\' 자주 전하는 결이 연애를 길게 가져가요.',
        ],
        'sameEl': [
          '【연애】 같은 결이라 친구 같은 연애 결이에요. $pName${withWith(pName)} 처음 만났을 때부터 편안하고 굳이 잘 보이려 하지 않아도 자연스러운 사이.',
          '【연애】 비화 연애 — 강렬한 끌림보다 잔잔한 편안함이 매력. \'느낌 없는데 편한\' 단계가 가장 깊은 사랑일 수 있어요.',
          '【연애】 같은 $myEl 결의 연애는 \'동기 매력\'. 친구로 시작해서 자연스럽게 연인으로 자리잡는 결이 자주 와요.',
          '【연애】 비화 결 — 자극은 약해도 시간이 갈수록 진해지는 사랑. $pSubj 너랑 같은 톤으로 사는 사람을 만난다는 게 흔치 않은 자리.',
        ],
        'neut': [
          '【연애】 중립 결이라 자연스러운 끌림은 약하지만 의식적으로 가까워지면 부담 없이 오래 가는 연애 결이에요. $pName${withWith(pName)} 정기적인 데이트 약속이 핵심.',
          '【연애】 중립의 연애 — 한 명이 먼저 다가가는 룰이 필요하지만, 일단 가까워지면 잔잔하고 안정적인 결.',
          '【연애】 자극도 충돌도 큰 자리가 아니에요. $pTop 의식적으로 정성 들이는 결이 깊이를 만드는 사랑.',
          '【연애】 직접 신호가 없는 중립 결. 끌림이 약한 대신 \'편함이 가장 큰 매력\' — 평생 곁에 둘 사람.',
        ],
      };
      final lovePool = lovePoolsKo[loveBranchKey] ?? lovePoolsKo['neut']!;
      loveMarriage.write(lovePool[pick('love-ko', lovePool.length)]);
      loveMarriage.write('\n\n');

      // 결혼
      final marriagePoolsKo = <String, List<String>>{
        'clash': [
          '【결혼】 충(沖)이 걸린 사이는 결혼 후 큰 결정(주거지·자녀·금전) 앞에서 의견이 엇갈리기 쉬워요. 결혼 전에 \'영역 분담\' 룰을 미리 정해두면 그런 엇갈림이 큰 갈등으로 잘 안 번져요.',
          '【결혼】 충이 있어도 룰만 잘 세우면 오래 단단하게 가기 좋아요. $pName${withWith(pName)} 누가 어떤 결정 영역을 책임지는지 명시적으로 합의해두세요.',
          '【결혼】 충 결의 결혼은 \'명시적 영역 분담\' 결혼. 암묵적 합의는 위험해요. 결혼 전 한 번, 결혼 후 6개월마다 한 번 룰 점검 자리를 두세요.',
          '【결혼】 일주 충 — 결혼 후 큰 결정마다 부딪히기 쉬운 결이에요. 다만 충이 있을수록 \'규칙을 먼저 정해두는 부부\'가 흔들림이 적어요. 룰이 사랑을 받쳐줘요.',
        ],
        'hyeong': [
          '【결혼】 형(刑)이 걸린 사이는 평소엔 잘 지내다가 한 번씩 큰 한 마디가 터지기 쉬워요. \'사소한 서운함 그때그때 풀기\' 습관이 결혼 생활의 핵심.',
          '【결혼】 형 결혼 — 매일 한 마디 칭찬, 한 마디 고마움을 챙기면 큰 다툼으로 잘 안 번져요. 작은 인정을 자주 챙기는 게 결혼을 오래 가게 하는 약이에요.',
          '【결혼】 $pName${withWith(pName)} 결혼하면 \'화날 때 10분 자리 떨어지기\' 룰을 미리 약속해두세요. 한 박자 쉬는 결 한 번이 큰 충돌로 잘 안 번지게 하는 데 도움돼요.',
          '【결혼】 형 결 결혼은 잔잔한 일상 안에 누적이 위험. 매일 짧은 인정의 의식이 결혼 안에 자리잡으면 큰 파열은 거의 사라져요.',
        ],
        'union': [
          '【결혼】 결혼으로 가면 시간이 갈수록 단단해지기 좋은 결이에요. 합·상생이 걸린 사이는 결혼 생활이 천천히 깊어지는 결이라, 신혼 때보다 5년·10년 뒤에 더 잘 맞는 자리.',
          '【결혼】 합 결혼은 \'시간이 약\' 인 결혼. 매년 결혼 기념일에 한 해를 되돌아보는 의식 하나만 두어도 관계가 자연스럽게 단단해져요.',
          '【결혼】 $pName${withWith(pName)} 합·상생 결혼이라 \'평범한 매일\'이 결을 키워요. 거창한 이벤트 없이 일상이 단단한 결혼.',
          '【결혼】 결혼으로 가면 잘 풀리기 좋은 결이에요. 다만 합 결혼도 \'각자의 시간\' 자리 한 가지는 따로 챙겨야 결이 더 깊어져요.',
        ],
        'overcome': [
          '【결혼】 상극 사이의 결혼은 \'역할 분담이 명확한 결혼\' 으로 풀면 가장 잘 작동해요. 누가 결정 자리에 있는지, 누가 챙김 자리에 있는지 자연스럽게 정해지는 결.',
          '【결혼】 상극 결혼은 톤 관리가 평생 미션. \'서로 다르게 표현해도 사랑\'이라는 기본 약속이 결혼을 길게 가게 해요.',
          '【결혼】 상극 결혼 — 명확한 역할 자리를 미리 정해두면 오래 단단하게 가져가기 좋은 자리예요. $pName${withWith(pName)} 강점·약점 자리를 인정하고 시작하세요.',
          '【결혼】 상극 결 결혼은 한쪽이 결혼 안에서 작아지지 않게 \'배려된 표현\' 자리가 핵심. 톤 한 단계 낮추는 결혼 약속.',
        ],
        'neut': [
          '【결혼】 중립 결의 결혼은 \'편안한 동반자\' 모델로 풀면 잘 맞아요. 강한 합도 강한 충도 없는 사이라, 결혼 생활이 잔잔하게 흘러가기 쉬운 자리.',
          '【결혼】 둘만의 작은 루틴 (매주 데이트, 매달 짧은 여행, 매년 함께 보는 영화 list 등) 을 만들어두면 자연스럽게 깊이가 쌓여요.',
          '【결혼】 중립 결혼의 핵심은 \'정성\'. 자연스러운 끌림이 약한 만큼 의식적인 작은 자리들이 결혼을 단단하게 만들어요.',
          '【결혼】 잔잔한 결혼. $pName${withWith(pName)} 외부 자극보다 둘만의 의식이 결을 키워요. 매주, 매달, 매년 — 정기성이 결혼의 핵심.',
        ],
      };
      final marriagePool = marriagePoolsKo[marriageBranchKey] ?? marriagePoolsKo['neut']!;
      loveMarriage.write(marriagePool[pick('marriage-ko', marriagePool.length)]);
      loveMarriage.write('\n\n');

      // 자녀 — opening + branch
      const childrenOpenKo = [
        '【자녀】 자녀 결은 두 사람의 일주 조합보다 각자의 자녀궁(식상·관성 — 자녀를 가리키는 자리)이 더 크게 작용해요. ',
        '【자녀】 자녀 결은 두 사람 일주 조합만으로 결정되지 않아요. 각자의 자녀궁이 더 큰 영향을 가지지만, 두 사람 결이 자녀가 자라는 분위기를 만들어요. ',
        '【자녀】 자녀 운은 부모 두 사람 사주 조합보다 각자 자녀궁 자리가 큰 영향. 그래도 두 사람의 결이 자녀 자라는 분위기를 직접 만들어요. ',
      ];
      loveMarriage.write(childrenOpenKo[pick('children-open-ko', childrenOpenKo.length)]);
      final childrenPoolsKo = <String, List<String>>{
        'harmonious': [
          '두 사람이 화목한 결인 만큼 자녀에게 안정된 가정 분위기를 만들어주기 좋은 사이예요. 둘이 같은 방향으로 자녀를 키우면 자녀가 자기 결을 또렷이 가지는 결.',
          '합·상생 결의 부모는 자녀에게 안정감을 주기 가장 좋은 결. 의견이 갈릴 때도 한쪽이 먼저 한 발 양보하는 습관이 자녀에게 가장 큰 교육이에요.',
          '$pName${withWith(pName)} 합이 있는 부모. 같은 방향으로 키우면 자녀가 부모 두 사람의 결을 모두 흡수해서 단단한 자기 색을 가져요.',
          '화목한 결의 부모는 자녀가 \'양쪽 모두에게 사랑받는 안정감\' 을 자연스럽게 가져요. 부모의 합이 가정의 결을 만들어요.',
        ],
        'frictioned': [
          '두 사람 사이에 충·형·상극이 있는 만큼 자녀 교육 방향에서 의견이 자주 갈릴 수 있어요. 자녀 앞에서 의견 다르게 표현 안 하는 약속, 큰 결정은 자녀 없는 자리에서 먼저 합의하는 룰이 보약.',
          '충돌이 있는 부모는 자녀 앞에서 \'한 목소리\' 룰이 핵심. 자녀가 \'양쪽 모두에게 사랑받는다\' 확신만 있으면 부모 두 사람 결을 자기 안에서 통합해 더 단단해져요.',
          '$pName${withWith(pName)} 부모 결에 충·상극이 있어도 자녀 교육 방향만 합의되면 충분히 좋은 가정. 큰 결정은 자녀 없는 자리에서 미리 합의하는 결.',
          '충·형·상극이 있는 부모는 자녀 앞에서 다투지 않는 결이 핵심. 큰 결정은 자녀가 없는 자리에서 합의하고, 자녀 앞에선 합의된 결을 보여주세요.',
        ],
        'neut': [
          '두 사람이 중립 결이라 자녀 교육에서도 잔잔하게 합의하는 자리에 가요. 자녀에게 강한 방향성을 주기보다 자녀 스스로 자기 색을 찾도록 곁에서 지지해주는 결이 잘 맞아요.',
          '중립 결의 부모는 자녀에게 \'자기 색을 찾을 자유\' 를 주는 부모가 되기 쉬워요. 강한 방향 제시보다 곁에서 지지하는 결이 핵심.',
          '$pName${withWith(pName)} 중립 결 부모. 자녀가 부모의 결에 휩쓸리지 않고 자기 결을 찾는 결이라, 자녀의 자율성을 존중하는 부모가 되기 좋아요.',
          '잔잔한 결의 부모는 자녀에게 안정된 일상 자리를 주기 좋아요. 자녀가 부담 없이 자기 색을 찾는 가정.',
        ],
      };
      final childrenPool = childrenPoolsKo[childrenBranchKey] ?? childrenPoolsKo['neut']!;
      loveMarriage.write(childrenPool[pick('children-ko', childrenPool.length)]);
    } else {
      // EN — 각 분기 4+ variant. 'pickHeader' 로 LOVE/MARRIAGE/CHILDREN 묶음 변형도 추가.
      final n = pNameEn;
      // LOVE
      final lovePoolsEn = <String, List<String>>{
        'ganHap': [
          'A stem union with $n — a strong love anchor. It tends to read magnetic early, and easy to feel hard to separate once close. Protecting one personal time slot each week helps.',
          'A heavenly-stem union ($myGan·$ptGan). The pull tends to be strong enough to feel sudden — reserving one private hour weekly helps the bond from blurring your colors.',
          "A strong, hard-to-separate union. Time tends to bend around $n — savoring it while anchoring at least one solo lane outside the romance keeps it healthy.",
          'A 五合 stem union with $n. It tends to be easy to fall into and easy to dissolve into — each of you keeping one untouched lane tends to keep it healthy long-term.',
        ],
        'jiHap': [
          "A branch union with $n — closeness here tends to build in daily life, so routines tend to matter more than dates.",
          "A six harmony / triad. Living rhythms tend to align without trying, and the anchor tends to read brightest in shared space and shared time.",
          "A $myJi·$ptJi branch union. Cooking together, walking together, watching movies together — that tends to be the love language here, not events.",
          "A daily-life love. The smaller the moments you share with $n, the more this kind of bond tends to build.",
        ],
        'clash': [
          "A branch clash with $n — intense love with friction that tends to surface on small decisions. Pre-agreeing rules helps.",
          "A $myJi·$ptJi clash tends to bring sparks and sparks. Deciding in advance who calls which kind of shot tends to make the love easier to carry through the friction.",
          "A clash love tends to be real love with friction baked in. Honesty after collisions tends to ease the bond more than calm could.",
          "A branch clash with $n. Pre-allocated decision rules and a 24-hour wait on big calls tend to make the love easier to sustain.",
        ],
        'overcome': [
          "An overcoming bond with $n — it tends to start intense; one leads, one follows. Tone tends to matter most.",
          "A $myEl·$ptEl overcoming line. The dominant voice softening and the receiving voice staying tends to be the balance — 'how about…' tends to be the magic phrase.",
          "An overcoming (相剋) love. Useful coaching can drift into control — asking 'was that too sharp?' weekly keeps the line honest.",
          "A strong-over-soft love. This kind of bond tends to hold when the louder side practises restraint and the quieter side practises voice.",
        ],
        'sameEl': [
          "A same-element line with $n — a friend-like love that tends to lean on comfort over passion.",
          "A 比和 (same-element) love. Trust tends to come fast and spark slow — the 'no big feeling but very easy' phase is often the deepest part of this love.",
          "A $myEl·$myEl love. Conversations that don't need explaining, preferences that match without asking — that tends to be the bond.",
          "A same-element romance. Quiet on the outside, durable on the inside — closeness here tends to build through small repetition.",
        ],
        'neut': [
          "A neutral pairing with $n — the natural pull tends to be mild, so intentional closeness is what tends to build a durable love.",
          "No direct stem-branch anchor between you. A neutral love tends to grow by choice — recurring dates and small rituals do the work gravity will not.",
          "A mild interaction with $n. Comfort tends to be the headline and depth the project — if both of you decide to build, a neutral love can run long.",
          "A neutral bond — calm, dependable, easy to sustain. The risk here tends to be forgetting, and the cure tends to be a calendar.",
        ],
      };
      final lovePool = lovePoolsEn[loveBranchKey] ?? lovePoolsEn['neut']!;
      const loveHeaders = ['【LOVE】 ', '【ROMANCE】 ', '【LOVE / 戀】 '];
      loveMarriage.write(loveHeaders[pick('love-header-en', loveHeaders.length)]);
      loveMarriage.write(lovePool[pick('love-en', lovePool.length)]);
      loveMarriage.write('\n\n');

      // MARRIAGE
      final marriagePoolsEn = <String, List<String>>{
        'clash': [
          "As a marriage, a clash line tends to reward pre-agreed role-allocation rules with $n.",
          "A branch clash plus marriage rewards decision-domain rules first — once allocated, the friction tends to calm.",
          "With $n, a clash marriage tends to stay steady when you write down who handles what before the rings. Re-auditing every six months helps.",
          "Clash marriages tend to hold best with explicit, revisited rules — the rule set tends to be the anchor here.",
        ],
        'hyeong': [
          "As a marriage, a punishment line tends to reward daily acknowledgments that keep the big blow-up away with $n.",
          "A punishment-branch marriage tends to do well on small daily 'thanks' and one 'pause 10 minutes' rule — tiny habits, large peace.",
          "Schedule micro-recognition. Marriages with $myJi·$ptJi tend to do best when 'I saw what you did' is daily, not occasional.",
          "A marriage tends to do well when small slights never get to pile — with $n the rule is to surface the small and save the big.",
        ],
        'union': [
          "As a marriage, a union line tends to read steadier the more years you tend it with $n.",
          "A union / generating bond. The marriage tends to read steadier in year five than year one — protecting the small annual rituals helps.",
          "Time tends to be on your side. With $n a union marriage tends to read steadier in year ten than year one — keeping the simple anniversary review helps.",
          "As a marriage, a union bond tends to get steadier with years. Adding one private personal ritual each keeps it from blurring both colors.",
        ],
        'overcome': [
          "As a marriage, an overcoming line tends to work best with clear roles and a mutual 'we love differently' promise with $n.",
          "An overcoming marriage tends to hold when both partners practise tone — the stronger voice quiets, the softer voice stays.",
          "An overcoming (相剋) marriage with $n — it tends to hold, and even toughen, when explicit roles and explicit softening rules are in place.",
          "Marriages with 相剋 tend to hold when 'we express love differently and that is still love' is the founding agreement.",
        ],
        'neut': [
          "As a marriage, a neutral line tends to suit a comfortable-companion model — building small joint rituals with $n helps.",
          "A neutral marriage tends to run on calendars more than gravity — a weekly date, a monthly trip, a yearly ritual tend to be the bond.",
          "With $n a neutral marriage tends to be the small daily decisions to stay close — no grand currents, just steady ones.",
          "A companion marriage. Depth here tends to grow with attention and fade with neglect — choosing the calendar helps.",
        ],
      };
      final marriagePool = marriagePoolsEn[marriageBranchKey] ?? marriagePoolsEn['neut']!;
      const marriageHeaders = ['【MARRIAGE】 ', '【MARRIAGE / 婚】 ', '【MARRIAGE — LONG VIEW】 '];
      loveMarriage.write(marriageHeaders[pick('marriage-header-en', marriageHeaders.length)]);
      loveMarriage.write(marriagePool[pick('marriage-en', marriagePool.length)]);
      loveMarriage.write('\n\n');

      // CHILDREN
      const childrenOpenEn = [
        "A read on children leans more on each of you on your own than on the two of you as a pair — still, the bond you keep tends to shape the home's tone. ",
        "Children come through each of you individually more than through the combination. Even so, how you two tend the bond tends to frame the household. ",
        "Each of you carries the children read on your own more than as a pair — but the tone you two keep tends to set the temperature of the home. ",
      ];
      const childrenHeaders = ['【CHILDREN】 ', '【CHILDREN / 子】 ', '【FAMILY】 '];
      loveMarriage.write(childrenHeaders[pick('children-header-en', childrenHeaders.length)]);
      loveMarriage.write(childrenOpenEn[pick('children-open-en', childrenOpenEn.length)]);
      final childrenPoolsEn = <String, List<String>>{
        'harmonious': [
          "A harmonious bond with $n tends to make a steady home tone easier to keep — and a steady home tone tends to give children a calm room to grow in.",
          "Union / generating pairs tend to keep a warm room. When opinions split, the first to yield tends to model the steadier lesson for the home.",
          "$n and you tend to set a calm tone together. Keeping that calm tends to give children a steady relationship climate to grow up around.",
          "A harmonious bond — the home tends to run on agreement more than negotiation. Tending that ease tends to make the household feel settled.",
        ],
        'frictioned': [
          "A friction bond with $n tends to reward pre-agreeing big decisions away from the kids and aligning in front of them.",
          "A branch clash or 相剋 in the pair? Keeping 'one voice in front of you, two voices in private' as the rule tends to make the home feel steady to children.",
          "With a friction bond, what tends to steady a home is kids knowing they are loved by both — making that explicit, and often, tends to do that work.",
          "Pre-deciding school, money, and lifestyle calls away from the kids, then keeping a united front in front of them, tends to be the whole game here.",
        ],
        'neut': [
          "A quiet alignment with $n — letting kids find their own colors while both of you support them tends to suit a neutral bond.",
          "A neutral bond tends to give children space. Holding steady support with low directive pressure tends to let children find their own footing.",
          "$n and you tend to be calm parents. The strength tends to be autonomy, and intentional presence keeps the calm from sliding into absence.",
          "A companion-style parenting tone tends to give children a quiet floor to stand on — adding one shared family ritual tends to anchor it.",
        ],
      };
      final childrenPool = childrenPoolsEn[childrenBranchKey] ?? childrenPoolsEn['neut']!;
      loveMarriage.write(childrenPool[pick('children-en', childrenPool.length)]);
    }

    // R106 P4a-fix2 — 궁합 v5 톤 backstop 정규화. 단정·메타는 pool source 에서
    // 이미 전수 제거됨(P4a-fix2). 두 사주의 실제 관계 anchor(합·충·오행·일주)는
    // 그대로 두고, soften 은 만약을 위한 deterministic backstop 패스로만 남긴다
    // (presentation layer only — 계산값 변경 0). design 9 / 2 / 3.
    String v5(String s) => CompatV5Service.soften(s, useKo: useKo, shortName: ptName);
    return _CompatAnalysis(
      summary: v5(summary.toString()),
      attract: v5(attract.toString()),
      friction: v5(friction.toString()),
      loveMarriage: v5(loveMarriage.toString()),
      actions: actions.map(v5).toList(),
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

/// R100 sprint 4 — regression guard testing hook (compatibility_screen).
///
/// Wraps `_DetailSection._analyze()` so the regression test
/// (`test/r100_compat_repetition_guard_test.dart`) can exercise the real
/// 5-section variant pool composition (`summary` / `attract` / `friction` /
/// `loveMarriage` / `actions`) without rendering widgets.
///
/// 사용처: 테스트 한정. production 코드는 호출하지 않는다.
@visibleForTesting
class CompatAnalysisForTest {
  final String summary;
  final String attract;
  final String friction;
  final String loveMarriage;
  final List<String> actions;
  const CompatAnalysisForTest({
    required this.summary,
    required this.attract,
    required this.friction,
    required this.loveMarriage,
    required this.actions,
  });
}

@visibleForTesting
CompatAnalysisForTest analyzeCompatForTest({
  required SajuResult me,
  required SajuResult partner,
  required bool useKo,
  String? partnerName,
}) {
  final r = _DetailSection(
    me: me,
    partner: partner,
    partnerName: partnerName,
  )._analyze(me, partner, useKo, partnerName: partnerName);
  return CompatAnalysisForTest(
    summary: r.summary,
    attract: r.attract,
    friction: r.friction,
    loveMarriage: r.loveMarriage,
    actions: r.actions,
  );
}

/// R101 sprint 3 — public wrapper.
///
/// `_DetailSection` 은 widget 트리 안에서 5섹션 (`summary` / `attract` /
/// `friction` / `loveMarriage` / `actions`) 본문을 mount 한다. kpop_compat 의
/// detail dialog 가 같은 본문 엔진을 재사용할 수 있도록 동일 widget 을 그대로
/// 노출만 한다. 본문 합성 로직 (`_analyze`) 은 변경 0 — `analyzeCompatForTest`
/// public wrapper 와 동일한 코드 경로.
///
/// 사용자 mandate verbatim: "우리 궁합보는거 그대로 사용해서 설명나오게 해줘".
class CompatDetailSection extends StatelessWidget {
  final SajuResult me;
  final SajuResult partner;
  final String? partnerName;
  const CompatDetailSection({
    super.key,
    required this.me,
    required this.partner,
    this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    return _DetailSection(me: me, partner: partner, partnerName: partnerName);
  }
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
