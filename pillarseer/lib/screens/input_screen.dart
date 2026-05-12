import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLunar = false;
  bool _unknownTime = false;
  Gender? _gender;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _selectedDate != null &&
      (_selectedTime != null || _unknownTime) &&
      !_isLoading;

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
                    _TapField(
                      value: _selectedDate == null
                          ? '—'
                          : _formatDate(_selectedDate!),
                      placeholder: _selectedDate == null,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 28),
                    _FieldLabel(text: l.inputTime),
                    _TapField(
                      value: _unknownTime
                          ? l.inputUnknownTime
                          : (_selectedTime?.format(context) ?? '—'),
                      placeholder: _selectedTime == null && !_unknownTime,
                      onTap: _unknownTime ? null : _pickTime,
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
                            onChanged: (v) => setState(() {
                              _unknownTime = v ?? false;
                              if (_unknownTime) _selectedTime = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l.inputUnknownTime,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 3,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _FieldLabel(text: l.inputBirthCity),
                    TextFormField(
                      controller: _cityController,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                      cursorColor: AppColors.ink,
                      decoration: _underlineDeco(hint: l.inputBirthCityHelper),
                    ),
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
                      onChanged: (i) => setState(() => _gender =
                          i == 0
                              ? Gender.male
                              : (i == 1 ? Gender.female : Gender.other)),
                    ),
                    const SizedBox(height: 40),
                    _PrimaryCta(
                      label: l.inputFindMyDestiny.toUpperCase(),
                      enabled: _canSubmit,
                      loading: _isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        l.inputFreeFourPillar.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          letterSpacing: 4,
                          color: AppColors.taupe,
                          fontWeight: FontWeight.w500,
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

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.ink,
            onPrimary: AppColors.bg,
            surface: AppColors.bg,
            onSurface: AppColors.ink,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.bg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.ink,
            onPrimary: AppColors.bg,
            surface: AppColors.bg,
            onSurface: AppColors.ink,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.bg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) return;
    if (_selectedTime == null && !_unknownTime) return;

    final l = AppL10n.of(context);
    setState(() => _isLoading = true);

    try {
      final svc = SajuService();
      final hour = _unknownTime ? 0 : (_selectedTime?.hour ?? 0);
      final minute = _unknownTime ? 0 : (_selectedTime?.minute ?? 0);
      final sajuOpts = ref.read(sajuSettingsProvider);
      final result = await svc.calculateSaju(
        year: _selectedDate!.year,
        month: _selectedDate!.month,
        day: _selectedDate!.day,
        hour: hour,
        minute: minute,
        isLunar: _isLunar,
        isMale: _gender == Gender.female ? false : true,
        unknownTime: _unknownTime,
        useLateNightZasi: sajuOpts.useLateNightZasi,
        applyTrueSunTime: sajuOpts.applyTrueSunTime,
        birthCity: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
      );

      ref.read(sajuResultProvider.notifier).set(result);
      ref.read(userBirthInfoProvider.notifier).set(UserBirthInfo(
            name: _nameController.text.trim(),
            birthDate: _selectedDate!,
            birthHour: hour,
            birthMinute: minute,
            birthCity: _cityController.text.trim(),
            isLunar: _isLunar,
            unknownTime: _unknownTime,
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
            children: [
              Text(
                'P I L L A R    S E E R',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 5,
                  color: AppColors.ink,
                ),
              ),
              Text(
                useKo ? '사주 입력 · 新' : 'NEW READING',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                  color: AppColors.inkLight,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR  CHART · 命  譜',
          style: GoogleFonts.inter(
            fontSize: 9,
            letterSpacing: 5,
            fontWeight: FontWeight.w500,
            color: AppColors.taupe,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l.inputTitle,
          style: GoogleFonts.notoSerifKr(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
            height: 1.2,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Four pillars, true-solar-time, solar terms and DST. '
          '입춘 기준의 절기력으로 사주를 정밀하게 풉니다.',
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            color: AppColors.inkLight,
            height: 1.7,
            letterSpacing: 0.3,
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

class _TapField extends StatelessWidget {
  final String value;
  final bool placeholder;
  final VoidCallback? onTap;
  const _TapField({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: placeholder
                      ? AppColors.taupe.withValues(alpha: 0.6)
                      : AppColors.ink,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.expand_more,
                  size: 18,
                  color: AppColors.taupe.withValues(alpha: 0.7)),
          ],
        ),
      ),
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
                    child: Text(
                      options[i].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 4,
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
            : Text(label),
      ),
    );
  }
}
