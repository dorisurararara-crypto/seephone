import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.inputTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l.inputName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.inputErrorNameRequired
                    : null,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null
                          ? l.inputBirthday
                          : DateFormat.yMMMd(locale.toString())
                              .format(_selectedDate!)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _unknownTime
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
                      icon: const Icon(Icons.access_time),
                      label: Text(_unknownTime
                          ? l.inputUnknownTime
                          : (_selectedTime?.format(context) ?? l.inputTime)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _unknownTime,
                    onChanged: (v) => setState(() {
                      _unknownTime = v ?? false;
                      if (_unknownTime) _selectedTime = null;
                    }),
                  ),
                  Expanded(
                    child: Text(
                      l.inputUnknownTime,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.moonlightGray),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: l.inputBirthCity,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                  helperText: l.inputBirthCityHelper,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l.inputCalendar),
                  ChoiceChip(
                    label: Text(l.inputSolar),
                    selected: !_isLunar,
                    onSelected: (val) {
                      if (val) setState(() => _isLunar = false);
                    },
                  ),
                  ChoiceChip(
                    label: Text(l.inputLunar),
                    selected: _isLunar,
                    onSelected: null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l.inputGender),
                  ChoiceChip(
                    label: Text(l.inputGenderMale),
                    selected: _gender == Gender.male,
                    onSelected: (v) => setState(
                        () => _gender = v ? Gender.male : null),
                  ),
                  ChoiceChip(
                    label: Text(l.inputGenderFemale),
                    selected: _gender == Gender.female,
                    onSelected: (v) => setState(
                        () => _gender = v ? Gender.female : null),
                  ),
                  ChoiceChip(
                    label: Text(l.inputGenderOther),
                    selected: _gender == Gender.other,
                    onSelected: (v) => setState(
                        () => _gender = v ? Gender.other : null),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.celestialGold,
                  foregroundColor: AppColors.cosmicBlack,
                  disabledBackgroundColor:
                      AppColors.celestialGold.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: AppColors.cosmicBlack, strokeWidth: 2.5),
                      )
                    : Text('✨ ${l.inputFindMyDestiny} ✨'),
              ),
              const SizedBox(height: 12),
              Text(
                l.inputFreeFourPillar,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.fadedSilver),
              ),
            ],
          ),
        ),
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
