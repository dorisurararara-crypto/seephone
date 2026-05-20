import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/world_cities.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/saju_service.dart';
import '../providers/saju_provider.dart';
import '../providers/saju_settings_provider.dart';

enum Gender { male, female, other }

class InputScreen extends ConsumerStatefulWidget {
  const InputScreen({super.key});

  @override
  ConsumerState<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends ConsumerState<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  // R91 사용자 mandate — 입력 화면 최초 진입 시 커서가 "이름"으로 가야 함.
  // 이전엔 YYYY autofocus 였어서 사용자가 "생년월일에 커서가 가 있음" 불만 제기.
  final _nameFocus = FocusNode();

  // Round 71 사용자 불만 #1 — 달력/휠 UI 제거. 4 TextField (YYYY/MM/DD/HHMM).
  final _yearCtl = TextEditingController();
  final _monthCtl = TextEditingController();
  final _dayCtl = TextEditingController();
  final _timeCtl = TextEditingController();
  final _yearFocus = FocusNode();
  final _monthFocus = FocusNode();
  final _dayFocus = FocusNode();
  final _timeFocus = FocusNode();
  // R103 sprint 3 — mandate "시간치면 자동으로 태어난 지역으로 안넘어가 / 태어난지역 끝났으면
  // 키보드가 닫혀야하고" verbatim 직발. HHMM 4자 도달 → _cityFocus.requestFocus() chain +
  // city TextFormField 에 focusNode + textInputAction.done + onFieldSubmitted unfocus wire.
  final _cityFocus = FocusNode();
  // raw text → 파생값. submit 시 _selectedDate / _selectedTime 채움.
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _dateError;
  String? _timeError;
  bool _isLunar = false;
  bool _unknownTime = false;
  Gender? _gender;
  // Round 82 sprint 9 — Gender.other 계산 처리 (외부 review P0 #6).
  // "기타" 선택 시 사용자에게 보조 모달로 "남 기준 / 여 기준" 명시 선택을 받아 저장.
  // null 이면 _gender == Gender.other 여도 silent male 처리 0 — 제출 가드가 다시 모달 띄움.
  bool? _calculationIsMaleForOther;
  bool _isLoading = false;
  // R87 sprint 3 — 해외 출생지 자동완성. _cityController.text 입력 시
  // WorldCities.search + 한국 도시 핵심 list union 결과를 chip 으로 노출.
  // _citySelectedLabel 와 controller.text 가 다르면 query 모드.
  String _cityQuery = '';
  String? _citySelectedLabel;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _nameFocus.dispose();
    _yearCtl.dispose();
    _monthCtl.dispose();
    _dayCtl.dispose();
    _timeCtl.dispose();
    _yearFocus.dispose();
    _monthFocus.dispose();
    _dayFocus.dispose();
    _timeFocus.dispose();
    _cityFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _selectedDate != null &&
      (_selectedTime != null || _unknownTime) &&
      _gender != null &&
      // Round 82 sprint 9 — Gender.other 면 계산 기준도 명시 선택해야 제출 가능.
      // silent male fallback 0 mandate (외부 review P0 #6).
      (_gender != Gender.other || _calculationIsMaleForOther != null) &&
      _dateError == null &&
      _timeError == null &&
      !_isLoading;

  /// 윤년 포함 월별 일수. 1900~2100 범위.
  int _daysInMonth(int year, int month) {
    if (month == 2) {
      final leap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return leap ? 29 : 28;
    }
    const month31 = {1, 3, 5, 7, 8, 10, 12};
    return month31.contains(month) ? 31 : 30;
  }

  /// YYYY/MM/DD 각각의 raw text 가 다 차면 DateTime 검증.
  void _recomputeDate() {
    final yt = _yearCtl.text;
    final mt = _monthCtl.text;
    final dt = _dayCtl.text;
    if (yt.length != 4 || mt.isEmpty || dt.isEmpty) {
      setState(() {
        _selectedDate = null;
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
        _selectedDate = null;
        _dateError = '숫자만 적어줘.';
      });
      return;
    }
    if (y < 1900 || y > nowYear) {
      setState(() {
        _selectedDate = null;
        _dateError = '태어난 해는 1900~$nowYear 사이로 적어줘.';
      });
      return;
    }
    if (m < 1 || m > 12) {
      setState(() {
        _selectedDate = null;
        _dateError = '월은 1~12 중에 골라줘.';
      });
      return;
    }
    final maxDay = _daysInMonth(y, m);
    if (d < 1 || d > maxDay) {
      setState(() {
        _selectedDate = null;
        _dateError = '$m월은 $maxDay일까지 있어 — 그 안에서 골라줘.';
      });
      return;
    }
    setState(() {
      _selectedDate = DateTime(y, m, d);
      _dateError = null;
    });
  }

  /// Round 83 sprint 4 (P1-B) — 자시 학파 helper 노출 조건.
  ///
  /// HHMM 의 HH 영역이 23 또는 00 (자시 = 23:00~01:00) 일 때만 helper widget mount.
  /// 그 외 (HH 미입력 / 01~22 / `_unknownTime=true`) mount 0.
  ///
  /// 사용자 mandate (R83 spec §2 #B): 23시 출생자는 학파에 따라 일주가 달라질 수 있다는
  /// 즉시 안내 + 정자시/야자시 학파 선택지를 input 안에 인라인 노출 (Settings 숨김 X).
  bool get _isZasiHourEntered {
    if (_unknownTime) return false;
    final raw = _timeCtl.text;
    if (raw.length < 2) return false;
    final hh = int.tryParse(raw.substring(0, 2));
    if (hh == null) return false;
    return hh == 23 || hh == 0;
  }

  /// HHMM (4자리 24h) → TimeOfDay.
  /// 1~3 자리 중에는 error 안 보여줌 (UX — 입력 중 빨간 에러 X).
  /// 4 자리 도달했을 때만 검증해서 error / 성공.
  void _recomputeTime() {
    if (_unknownTime) {
      setState(() {
        _selectedTime = null;
        _timeError = null;
      });
      return;
    }
    final raw = _timeCtl.text;
    if (raw.length < 4) {
      // 입력 중 — error 숨김, submit 만 막음.
      setState(() {
        _selectedTime = null;
        _timeError = null;
      });
      return;
    }
    final h = int.tryParse(raw.substring(0, 2));
    final m = int.tryParse(raw.substring(2, 4));
    if (h == null || m == null) {
      setState(() {
        _selectedTime = null;
        _timeError = '숫자만 적어줘.';
      });
      return;
    }
    if (h < 0 || h > 23) {
      setState(() {
        _selectedTime = null;
        _timeError = '시는 00~23 안에서 적어줘.';
      });
      return;
    }
    if (m < 0 || m > 59) {
      setState(() {
        _selectedTime = null;
        _timeError = '분은 00~59 안에서 적어줘.';
      });
      return;
    }
    setState(() {
      _selectedTime = TimeOfDay(hour: h, minute: m);
      _timeError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // 한자 watermark — 한쪽 코너, 매우 옅게
          Positioned(
            top: -60,
            right: -40,
            child: IgnorePointer(
              child: Text(
                '命',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 280,
                  fontWeight: FontWeight.w300,
                  color: AppColors.line.withValues(alpha: 0.35),
                  height: 0.9,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AppBar(l: l),
                    const SizedBox(height: 32),
                    _HeroBlock(l: l),
                    const SizedBox(height: 36),
                    _FieldLabel(text: l.inputName),
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      autofocus: true,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: AppColors.ink,
                      ),
                      cursorColor: AppColors.ink,
                      decoration: _underlineDeco(hint: l.inputName),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.inputErrorNameRequired
                          : null,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 28),
                    _FieldLabel(text: l.inputBirthday),
                    // Round 71 사용자 불만 #1 — 달력 dialog 제거. YYYY / MM / DD 숫자 입력.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _NumberField(
                            controller: _yearCtl,
                            focusNode: _yearFocus,
                            hint: 'YYYY',
                            maxLen: 4,
                            onLengthReached: () => _monthFocus.requestFocus(),
                            onChanged: (_) => _recomputeDate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _NumberField(
                            controller: _monthCtl,
                            focusNode: _monthFocus,
                            hint: 'MM',
                            maxLen: 2,
                            onLengthReached: () => _dayFocus.requestFocus(),
                            onChanged: (_) => _recomputeDate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _NumberField(
                            controller: _dayCtl,
                            focusNode: _dayFocus,
                            hint: 'DD',
                            maxLen: 2,
                            onLengthReached: () {
                              if (!_unknownTime) _timeFocus.requestFocus();
                            },
                            onChanged: (_) => _recomputeDate(),
                          ),
                        ),
                      ],
                    ),
                    if (_dateError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _dateError!,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: AppColors.fireRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _FieldLabel(text: l.inputTime),
                    _NumberField(
                      controller: _timeCtl,
                      focusNode: _timeFocus,
                      hint: 'HHMM (예: 0830)',
                      maxLen: 4,
                      enabled: !_unknownTime,
                      onChanged: (_) => _recomputeTime(),
                      // R103 sprint 3 — 사용자 mandate "시간치면 자동으로 태어난 지역으로
                      // 안넘어가" 직발. HHMM 4자 입력 완료 시 city TextFormField 로 focus 이동.
                      onLengthReached: () => _cityFocus.requestFocus(),
                    ),
                    if (_timeError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _timeError!,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: AppColors.fireRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    // Round 83 sprint 4 (P1-B) — 자시 학파 helper mount.
                    // HH ∈ {23, 00} && !_unknownTime 일 때만 mount.
                    // Settings 으로 숨기지 않고 input 안 인라인 — 사용자 mandate (외부 reviewer
                    // P0 #4) 의 "즉시 안내 + 학파 선택지 input 안에 노출".
                    if (_isZasiHourEntered)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _ZasiHelperBlock(l: l),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _unknownTime,
                            activeColor: AppColors.ink,
                            checkColor: AppColors.bg,
                            side: const BorderSide(color: AppColors.taupe),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            onChanged: (v) {
                              setState(() {
                                _unknownTime = v ?? false;
                                if (_unknownTime) {
                                  _selectedTime = null;
                                  _timeCtl.clear();
                                  _timeError = null;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l.inputUnknownTime,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _FieldLabel(text: l.inputBirthCity),
                    TextFormField(
                      controller: _cityController,
                      // R103 sprint 3 — 사용자 mandate "태어난지역 끝났으면 키보드가 닫혀야" 직발.
                      // focusNode + textInputAction.done + onFieldSubmitted unfocus 3종 wire
                      // (iOS Done 키 / Android ✓ 키 모두 1차로 keyboard dismiss).
                      focusNode: _cityFocus,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                      cursorColor: AppColors.ink,
                      decoration: _underlineDeco(hint: l.inputBirthCityHelper),
                      onChanged: (v) {
                        setState(() {
                          _cityQuery = v;
                          if (_citySelectedLabel != null &&
                              v != _citySelectedLabel) {
                            _citySelectedLabel = null;
                          }
                        });
                      },
                    ),
                    // R87 sprint 3 — 자동완성 chip bar. 한국·해외 도시 union.
                    // tap 으로 controller.text 채움 + 국가 helper 표시.
                    if (_cityQuery.trim().isNotEmpty &&
                        _citySelectedLabel != _cityController.text) ...[
                      const SizedBox(height: 10),
                      _CitySuggestionBar(
                        query: _cityQuery,
                        useKo: Localizations.maybeLocaleOf(context)
                                    ?.languageCode ==
                                'ko' ||
                            Localizations.maybeLocaleOf(context) == null,
                        onPick: (label) {
                          setState(() {
                            _cityController.text = label;
                            _citySelectedLabel = label;
                            _cityQuery = label;
                          });
                          // 키보드 dismiss 위해 unfocus.
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    _SegmentPicker(
                      label: l.inputCalendar,
                      options: [l.inputSolar, l.inputLunar],
                      selectedIndex: _isLunar ? 1 : 0,
                      onChanged: (i) => setState(() => _isLunar = i == 1),
                    ),
                    const SizedBox(height: 22),
                    _SegmentPicker(
                      label: l.inputGender,
                      options: [
                        l.inputGenderMale,
                        l.inputGenderFemale,
                        l.inputGenderOther,
                      ],
                      selectedIndex: _gender == null
                          ? -1
                          : (_gender == Gender.male
                              ? 0
                              : (_gender == Gender.female ? 1 : 2)),
                      onChanged: (i) {
                        if (i == 0) {
                          setState(() {
                            _gender = Gender.male;
                            _calculationIsMaleForOther = null;
                          });
                        } else if (i == 1) {
                          setState(() {
                            _gender = Gender.female;
                            _calculationIsMaleForOther = null;
                          });
                        } else {
                          // Round 82 sprint 9 — Gender.other 선택 시 보조 모달 mount.
                          // silent male 처리 X — 사용자 명시 선택만 수용 (외부 review P0 #6).
                          setState(() => _gender = Gender.other);
                          _askOtherGenderCalcBasis();
                        }
                      },
                    ),
                    // Round 82 sprint 9 — Gender.other 선택 후 계산 기준 명시 store 시
                    // 사용자에게 현재 적용된 기준을 1줄 배지로 보여줌 (silent 가 silent 가 아님).
                    if (_gender == Gender.other &&
                        _calculationIsMaleForOther != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _OtherGenderCalcBadge(
                          label: _calculationIsMaleForOther == true
                              ? l.inputGenderOtherCalcMaleBadge
                              : l.inputGenderOtherCalcFemaleBadge,
                          onTap: _askOtherGenderCalcBasis,
                        ),
                      ),
                    const SizedBox(height: 40),
                    _PrimaryCta(
                      label: l.inputFindMyDestiny,
                      enabled: _canSubmit,
                      loading: _isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        l.inputFreeFourPillar,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          letterSpacing: 0.2,
                          color: AppColors.taupe,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _underlineDeco({String? hint}) => InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        hintText: hint,
        hintStyle: GoogleFonts.notoSerifKr(
          fontSize: 18,
          color: AppColors.taupe.withValues(alpha: 0.6),
        ),
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.ink, width: 1.2),
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 10,
          letterSpacing: 1,
          color: AppColors.fireRed,
        ),
      );

  /// Round 82 sprint 9 — Gender.other 보조 모달 (외부 review P0 #6).
  ///
  /// 사주 대운 계산은 남양여음 (양남 = 순행 / 음남 = 역행) 기반이라 male/female 둘 중 하나의
  /// boolean 이 필수. "기타" 선택 사용자에게 silent male 처리 X — 명시 선택 받음.
  /// 사용자가 모달 취소·dismiss 시 _gender 가 Gender.other 인 채로 _calculationIsMaleForOther
  /// 가 null 로 남아, _canSubmit + _submit 가드가 막아 silent fallback 0.
  Future<void> _askOtherGenderCalcBasis() async {
    final l = AppL10n.of(context);
    final choice = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.inputGenderOtherModalTitle,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.inputGenderOtherModalBody,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.inkLight,
                  ),
                ),
                const SizedBox(height: 18),
                _OtherGenderChoiceButton(
                  label: l.inputGenderOtherModalMale,
                  onTap: () => Navigator.of(sheetCtx).pop(true),
                ),
                const SizedBox(height: 8),
                _OtherGenderChoiceButton(
                  label: l.inputGenderOtherModalFemale,
                  onTap: () => Navigator.of(sheetCtx).pop(false),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(sheetCtx).pop(null),
                  child: Text(
                    l.inputGenderOtherModalCancel,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.taupe,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (choice == null) {
      // 취소·dismiss — silent male 처리 0 mandate. _gender 를 null 로 되돌려
      // 사용자가 segmented picker 에서 다시 골라야 진행 가능.
      setState(() {
        _gender = null;
        _calculationIsMaleForOther = null;
      });
    } else {
      setState(() => _calculationIsMaleForOther = choice);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) return;
    if (_selectedTime == null && !_unknownTime) return;
    // Round 77 sprint 6 — 성별 가드. 미선택 시 자동 isMale: true 적용 금지.
    if (_gender == null) {
      final useKo =
          (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(useKo ? '성별 골라줘 — 사주 계산에 꼭 필요해.' : 'Pick a gender to continue.'),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Round 82 sprint 9 — Gender.other 가드. silent male 처리 0 (외부 review P0 #6).
    // _calculationIsMaleForOther 미선택 시 모달 다시 띄우고 return.
    if (_gender == Gender.other && _calculationIsMaleForOther == null) {
      _askOtherGenderCalcBasis();
      return;
    }

    final l = AppL10n.of(context);
    setState(() => _isLoading = true);

    try {
      final svc = SajuService();
      final hour = _unknownTime ? 0 : (_selectedTime?.hour ?? 0);
      final minute = _unknownTime ? 0 : (_selectedTime?.minute ?? 0);
      final sajuOpts = ref.read(sajuSettingsProvider);
      // Round 82 sprint 9 — silent truthy fallback 제거 (외부 review P0 #6).
      // Gender.male → isMale=true / Gender.female → isMale=false / Gender.other → 사용자가
      // 보조 모달로 명시 선택한 _calculationIsMaleForOther 사용 (위 가드에서 non-null 보장).
      final bool isMale;
      switch (_gender!) {
        case Gender.male:
          isMale = true;
          break;
        case Gender.female:
          isMale = false;
          break;
        case Gender.other:
          isMale = _calculationIsMaleForOther!;
          break;
      }
      final result = await svc.calculateSaju(
        year: _selectedDate!.year,
        month: _selectedDate!.month,
        day: _selectedDate!.day,
        hour: hour,
        minute: minute,
        isLunar: _isLunar,
        isMale: isMale,
        unknownTime: _unknownTime,
        useLateNightZasi: sajuOpts.useLateNightZasi,
        applyTrueSunTime: sajuOpts.applyTrueSunTime,
        birthCity: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
      );

      // Round 82 sprint 9 — 원본 성별 보존 (외부 review P0 #6 fix 2).
      // Gender.other 사용자는 isMale 이 보조 모달로 결정된 계산 기준일 뿐이라,
      // 원본 의도는 UserBirthInfo.gender 에 별도 store. K-POP 궁합 등 후속 surface 에서
      // "기타" 사용자를 silent 로 남/여 중 하나로 분류하지 않게 함.
      final UserGender userGender;
      switch (_gender!) {
        case Gender.male:
          userGender = UserGender.male;
          break;
        case Gender.female:
          userGender = UserGender.female;
          break;
        case Gender.other:
          userGender = UserGender.other;
          break;
      }
      ref.read(sajuResultProvider.notifier).set(result);
      ref.read(userBirthInfoProvider.notifier).set(UserBirthInfo(
            name: _nameController.text.trim(),
            birthDate: _selectedDate!,
            birthHour: hour,
            birthMinute: minute,
            birthCity: _cityController.text.trim(),
            isLunar: _isLunar,
            unknownTime: _unknownTime,
            isMale: isMale,
            gender: userGender,
          ));

      if (mounted) {
        context.go('/result');
      }
    } catch (e, st) {
      debugPrint('calculateSaju failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.inputErrorTimeRequired),
            backgroundColor: AppColors.ink,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _AppBar extends StatelessWidget {
  final AppL10n l;
  const _AppBar({required this.l});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 한국어 메인 라벨 (notoSerifKr 16pt).
                  Text(
                    useKo ? '사주 입력' : 'New Reading',
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                      color: AppColors.ink,
                    ),
                  ),
                  // 영문 sub-line — 9pt 회색 (메인은 한국어).
                  Text(
                    'PILLAR SEER',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: AppColors.taupe.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  useKo ? '새로 보기' : 'NEW',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: AppColors.inkLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: AppColors.line),
        ],
      ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  final AppL10n l;
  const _HeroBlock({required this.l});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.inputTitle,
          style: GoogleFonts.notoSerifKr(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            letterSpacing: 0,
            height: 1.2,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        // 영문/한자 sub-line — letter-spacing 2, 9pt 회색. 메인 라벨은 한국어.
        Text(
          'YOUR CHART',
          style: GoogleFonts.inter(
            fontSize: 9,
            letterSpacing: 2,
            fontWeight: FontWeight.w400,
            color: AppColors.taupe.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 16),
        // MZ 친구 톤 한국어 단독. 기술어(진태양시·절기·DST) 제거.
        Text(
          useKo
              ? '생일·태어난 시간만 알려줘. 30초면 끝나.'
              : "Just your birth date and time. Takes 30 seconds.",
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            color: AppColors.inkLight,
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    // Round 77 sprint 6 — 한국어 메인 자연문 라벨. UPPERCASE + letterSpacing 4 제거.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.notoSerifKr(
          fontSize: 12,
          letterSpacing: 0.2,
          fontWeight: FontWeight.w500,
          color: AppColors.taupe,
        ),
      ),
    );
  }
}

/// Round 71 사용자 불만 #1 — 숫자 직접 입력용 underline TextField.
/// keyboardType=number, digitsOnly, maxLen 도달 시 다음 focusNode 로 이동.
class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final int maxLen;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onLengthReached;
  const _NumberField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.maxLen,
    this.enabled = true,
    this.onChanged,
    this.onLengthReached,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLen),
      ],
      style: GoogleFonts.notoSerifKr(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: enabled ? AppColors.ink : AppColors.taupe.withValues(alpha: 0.5),
        letterSpacing: 0.8,
      ),
      cursorColor: AppColors.ink,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        hintText: hint,
        hintStyle: GoogleFonts.notoSerifKr(
          fontSize: 16,
          color: AppColors.taupe.withValues(alpha: 0.6),
        ),
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.ink, width: 1.2),
        ),
        disabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.line),
        ),
      ),
      onChanged: (v) {
        onChanged?.call(v);
        if (v.length == maxLen && onLengthReached != null) {
          onLengthReached!();
        }
      },
    );
  }
}

class _SegmentPicker extends StatelessWidget {
  final String label;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _SegmentPicker({
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.line),
              bottom: BorderSide(color: AppColors.line),
            ),
          ),
          child: Row(
            children: List.generate(options.length, (i) {
              final selected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.ink : Colors.transparent,
                      border: i < options.length - 1
                          ? const Border(
                              right:
                                  BorderSide(color: AppColors.line, width: 1),
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    // Round 77 sprint 6 — 한국어 자연문 segment. UPPERCASE + letterSpacing 4 제거.
                    child: Text(
                      options[i],
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w500,
                        color: selected ? AppColors.bg : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;
  const _PrimaryCta({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.bg,
          disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.35),
          disabledForegroundColor: AppColors.bg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: GoogleFonts.notoSerifKr(
            fontSize: 14,
            letterSpacing: 0.4,
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
            : Text(label),
      ),
    );
  }
}

/// Round 82 sprint 9 — Gender.other 보조 모달 선택 버튼 (외부 review P0 #6).
class _OtherGenderChoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OtherGenderChoiceButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: ValueKey('other-gender-choice-$label'),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink, width: 1.0),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

/// Round 83 sprint 4 (P1-B) — 23시 자시 학파 helper block.
///
/// HHMM 의 HH 가 23 또는 00 이면 자동 mount 되어 다음을 1번에 보여줘요:
///   1) 자시 어휘 + 학파 차이 1줄 풀이 (M5 mandate: 도메인 어휘 옆 1줄 평이).
///   2) 30분 boundary 1줄 (23:00–23:29 / 23:30–00:59 학파별 차이).
///   3) 학파 선택 인라인 옵션 2개 — 정자시 (기본) / 야자시.
///
/// 옵션 탭 시 `sajuSettingsProvider.useLateNightZasi` state 토글 — settings_screen
/// 의 `_LateNightZasiSwitch` 와 single-source. 사용자가 input 화면을 떠나지 않고도
/// 학파를 즉석에서 바꿀 수 있어요 (사용자 mandate: Settings 으로 숨기지 X).
class _ZasiHelperBlock extends ConsumerWidget {
  final AppL10n l;
  const _ZasiHelperBlock({required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opts = ref.watch(sajuSettingsProvider);
    final useLate = opts.useLateNightZasi;
    return Container(
      key: const ValueKey('zasi-helper-block'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.04),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.inputZasiHelperTitle,
            style: GoogleFonts.notoSerifKr(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.inputZasiHelperBody,
            style: GoogleFonts.notoSansKr(
              fontSize: 12.5,
              color: AppColors.inkLight,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.inputZasiHelperBoundary,
            style: GoogleFonts.notoSansKr(
              fontSize: 11.5,
              color: AppColors.taupe,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          _ZasiOptionTile(
            keyId: 'zasi-option-early',
            label: l.inputZasiOptionEarly,
            selected: !useLate,
            onTap: () => ref
                .read(sajuSettingsProvider.notifier)
                .setUseLateNightZasi(false),
          ),
          const SizedBox(height: 8),
          _ZasiOptionTile(
            keyId: 'zasi-option-late',
            label: l.inputZasiOptionLate,
            selected: useLate,
            onTap: () => ref
                .read(sajuSettingsProvider.notifier)
                .setUseLateNightZasi(true),
          ),
        ],
      ),
    );
  }
}

/// Round 83 sprint 4 (P1-B) — 자시 학파 inline 옵션 tile.
class _ZasiOptionTile extends StatelessWidget {
  final String keyId;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ZasiOptionTile({
    required this.keyId,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey(keyId),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.line,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 16,
              color: selected ? AppColors.bg : AppColors.taupe,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.bg : AppColors.ink,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round 82 sprint 9 — Gender.other 선택 후 적용된 계산 기준 배지 (외부 review P0 #6).
/// silent 가 silent 가 아님을 사용자가 한눈에 보도록 1줄 surfacing.
class _OtherGenderCalcBadge extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OtherGenderCalcBadge({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('other-gender-calc-badge'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit_outlined,
                size: 14, color: AppColors.ink.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

/// R87 sprint 3 — 출생지 자동완성 chip bar.
/// 한국 핵심 도시 12개 + WorldCities (해외 ~150) union 검색.
/// 한국 도시: 단순 label (예: "서울"). 해외 도시: "도쿄 · 일본" label.
class _CitySuggestionBar extends StatelessWidget {
  final String query;
  final bool useKo;
  final void Function(String label) onPick;
  const _CitySuggestionBar({
    required this.query,
    required this.useKo,
    required this.onPick,
  });

  // 한국 핵심 도시 (검색 union). manseryeok_service._cityLongitudes 가
  // 진태양시 보정에 사용하는 한국 도시 풀과 겹침.
  static const List<_KrCity> _krCities = [
    _KrCity('서울', 'Seoul'),
    _KrCity('인천', 'Incheon'),
    _KrCity('부산', 'Busan'),
    _KrCity('대구', 'Daegu'),
    _KrCity('대전', 'Daejeon'),
    _KrCity('광주', 'Gwangju'),
    _KrCity('울산', 'Ulsan'),
    _KrCity('수원', 'Suwon'),
    _KrCity('창원', 'Changwon'),
    _KrCity('제주', 'Jeju'),
    _KrCity('전주', 'Jeonju'),
    _KrCity('청주', 'Cheongju'),
    _KrCity('포항', 'Pohang'),
    _KrCity('춘천', 'Chuncheon'),
    _KrCity('강릉', 'Gangneung'),
    _KrCity('천안', 'Cheonan'),
    _KrCity('성남', 'Seongnam'),
    _KrCity('고양', 'Goyang'),
    _KrCity('안산', 'Ansan'),
    _KrCity('부천', 'Bucheon'),
  ];

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final krHits = _krCities
        .where((c) =>
            c.ko.toLowerCase().contains(q) ||
            c.en.toLowerCase().contains(q))
        .take(6)
        .toList();
    final worldHits = WorldCities.search(query, limit: 8);
    if (krHits.isEmpty && worldHits.isEmpty) {
      return Padding(
        key: const Key('city_suggestion_empty'),
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          useKo ? '일치하는 도시가 없어요 — 그냥 적어도 돼요.' : 'No match — you can keep typing.',
          style: GoogleFonts.notoSansKr(
            fontSize: 11.5,
            color: AppColors.taupe,
            height: 1.5,
          ),
        ),
      );
    }
    return SizedBox(
      key: const Key('city_suggestion_bar'),
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final kr in krHits)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CityChip(
                label: useKo ? kr.ko : kr.en,
                onTap: () => onPick(useKo ? kr.ko : kr.en),
                isKr: true,
              ),
            ),
          for (final w in worldHits)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CityChip(
                label: w.labeled(useKo),
                onTap: () => onPick(useKo ? w.ko : w.en),
                isKr: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _KrCity {
  final String ko;
  final String en;
  const _KrCity(this.ko, this.en);
}

class _CityChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isKr;
  const _CityChip({
    required this.label,
    required this.onTap,
    required this.isKr,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isKr ? AppColors.paper : AppColors.bg,
          border: Border.all(
            color: isKr ? AppColors.ink : AppColors.line,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
