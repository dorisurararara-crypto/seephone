import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/saju_service.dart';
import '../providers/saju_provider.dart';

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
      body: Stack(
        children: [
          // === 별자리 배경 ===
          const _StarField(),
          // === 한자 watermark ===
          const Positioned(
            top: -40,
            left: -30,
            child: _HanWatermark(text: '柱'),
          ),
          const Positioned(
            bottom: -80,
            right: -30,
            child: _HanWatermark(text: '命'),
          ),
          // === 본 content ===
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(l: l),
                    const SizedBox(height: 20),
                    _IconField(
                      icon: Icons.person_outline,
                      label: l.inputName,
                      child: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.ghostlyWhite,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.inputErrorNameRequired
                            : null,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    _IconField(
                      icon: Icons.calendar_today_outlined,
                      label: l.inputBirthday,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _selectedDate ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          initialDatePickerMode: DatePickerMode.year,
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.celestialGold,
                                onPrimary: AppColors.cosmicBlack,
                                surface: AppColors.midnightPurple,
                                onSurface: AppColors.ghostlyWhite,
                              ),
                              dialogTheme: const DialogThemeData(
                                backgroundColor: AppColors.cosmicBlack,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Text(
                        _selectedDate == null
                            ? (l.inputBirthday)
                            : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedDate == null
                              ? AppColors.fadedSilver
                              : AppColors.ghostlyWhite,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _IconField(
                      icon: Icons.access_time,
                      label: l.inputTime,
                      onTap: _unknownTime
                          ? null
                          : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime ??
                                    const TimeOfDay(hour: 12, minute: 0),
                              );
                              if (picked != null) {
                                setState(() => _selectedTime = picked);
                              }
                            },
                      child: Text(
                        _unknownTime
                            ? l.inputUnknownTime
                            : (_selectedTime?.format(context) ?? '—'),
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedTime == null && !_unknownTime
                              ? AppColors.fadedSilver
                              : AppColors.ghostlyWhite,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 0, 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _unknownTime,
                              activeColor: AppColors.celestialGold,
                              checkColor: AppColors.cosmicBlack,
                              onChanged: (v) => setState(() {
                                _unknownTime = v ?? false;
                                if (_unknownTime) _selectedTime = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.inputUnknownTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.moonlightGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _IconField(
                      icon: Icons.location_on_outlined,
                      label: l.inputBirthCity,
                      sub: l.inputBirthCityHelper,
                      child: TextFormField(
                        controller: _cityController,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.ghostlyWhite,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ChipRow(
                      label: l.inputCalendar,
                      chips: [
                        _ChipData(l.inputSolar, !_isLunar,
                            (v) => setState(() => _isLunar = !v)),
                        _ChipData(l.inputLunar, _isLunar,
                            (v) => setState(() => _isLunar = v)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ChipRow(
                      label: l.inputGender,
                      chips: [
                        _ChipData(l.inputGenderMale, _gender == Gender.male,
                            (v) => setState(
                                () => _gender = v ? Gender.male : null)),
                        _ChipData(l.inputGenderFemale,
                            _gender == Gender.female,
                            (v) => setState(
                                () => _gender = v ? Gender.female : null)),
                        _ChipData(l.inputGenderOther, _gender == Gender.other,
                            (v) => setState(
                                () => _gender = v ? Gender.other : null)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SubmitButton(
                      label: l.inputFindMyDestiny,
                      enabled: _canSubmit,
                      loading: _isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.inputFreeFourPillar,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.fadedSilver),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      final result = await svc.calculateSaju(
        year: _selectedDate!.year,
        month: _selectedDate!.month,
        day: _selectedDate!.day,
        hour: hour,
        minute: minute,
        isLunar: _isLunar,
        isMale: _gender == Gender.female ? false : true,
        unknownTime: _unknownTime,
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
            backgroundColor: AppColors.fireRed,
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

class _Header extends StatelessWidget {
  final AppL10n l;
  const _Header({required this.l});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          '運命入力',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.celestialGold.withValues(alpha: 0.7),
            letterSpacing: 4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.inputTitle,
          style: const TextStyle(
            fontSize: 18,
            color: AppColors.ghostlyWhite,
            letterSpacing: 6,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                  height: 1,
                  color: AppColors.celestialGold.withValues(alpha: 0.2)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '✦',
                style: TextStyle(
                    color: AppColors.celestialGold, fontSize: 14),
              ),
            ),
            Expanded(
              child: Container(
                  height: 1,
                  color: AppColors.celestialGold.withValues(alpha: 0.2)),
            ),
          ],
        ),
      ],
    );
  }
}

class _IconField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final Widget child;
  final VoidCallback? onTap;

  const _IconField({
    required this.icon,
    required this.label,
    required this.child,
    this.sub,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tappable = onTap != null;
    final body = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.spiritIndigo.withValues(alpha: 0.15),
        border:
            Border.all(color: AppColors.celestialGold.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.celestialGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.celestialGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.celestialGold,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                child,
                if (sub != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    sub!,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.fadedSilver,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (tappable)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.chevron_right,
                  size: 18, color: AppColors.moonlightGray),
            ),
        ],
      ),
    );

    if (tappable) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: body,
      );
    }
    return body;
  }
}

class _ChipData {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  const _ChipData(this.label, this.selected, this.onSelected);
}

class _ChipRow extends StatelessWidget {
  final String label;
  final List<_ChipData> chips;
  const _ChipRow({required this.label, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.moonlightGray)),
          ...chips.map((c) => ChoiceChip(
                label: Text(c.label),
                selected: c.selected,
                onSelected: c.onSelected,
                labelStyle: TextStyle(
                    fontSize: 11,
                    color: c.selected
                        ? AppColors.celestialGold
                        : AppColors.ghostlyWhite),
                backgroundColor:
                    AppColors.celestialGold.withValues(alpha: 0.08),
                selectedColor:
                    AppColors.celestialGold.withValues(alpha: 0.22),
                side: BorderSide(
                    color: c.selected
                        ? AppColors.celestialGold
                        : AppColors.celestialGold.withValues(alpha: 0.2)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;
  const _SubmitButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.celestialGold.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.celestialGold,
          foregroundColor: AppColors.cosmicBlack,
          disabledBackgroundColor:
              AppColors.celestialGold.withValues(alpha: 0.25),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: AppColors.cosmicBlack, strokeWidth: 2.5),
              )
            : Text('✦  $label  ✦'),
      ),
    );
  }
}

class _HanWatermark extends StatelessWidget {
  final String text;
  const _HanWatermark({required this.text});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 220,
          fontWeight: FontWeight.w900,
          color: AppColors.celestialGold.withValues(alpha: 0.03),
        ),
      ),
    );
  }
}

class _StarField extends StatelessWidget {
  const _StarField();

  // 별 좌표 (정규화: 0~1). 각 별의 (x, y, size, opacity).
  static const _stars = <List<double>>[
    [0.10, 0.08, 2.0, 0.7],
    [0.85, 0.12, 3.0, 0.6],
    [0.22, 0.22, 2.5, 0.8],
    [0.78, 0.30, 2.0, 0.5],
    [0.05, 0.45, 3.0, 0.7],
    [0.92, 0.50, 2.0, 0.6],
    [0.15, 0.65, 2.5, 0.5],
    [0.80, 0.72, 3.0, 0.7],
    [0.50, 0.05, 2.0, 0.6],
    [0.45, 0.88, 2.5, 0.5],
    [0.30, 0.45, 1.8, 0.4],
    [0.65, 0.55, 2.0, 0.5],
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: Stack(
        children: _stars.map((s) {
          return Positioned(
            left: size.width * s[0],
            top: size.height * s[1],
            child: Container(
              width: s[2],
              height: s[2],
              decoration: BoxDecoration(
                color:
                    AppColors.celestialGold.withValues(alpha: s[3]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        AppColors.celestialGold.withValues(alpha: 0.5 * s[3]),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
