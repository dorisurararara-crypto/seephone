import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/saju_service.dart';
import '../providers/saju_provider.dart';

class InputScreen extends ConsumerStatefulWidget {
  const InputScreen({super.key});

  @override
  ConsumerState<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends ConsumerState<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // 글로벌 K-pop 팬 대상이라 서울 default 제거. 사용자가 직접 입력.
  final _cityController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 0);
  bool _isLunar = false;
  bool _unknownTime = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty && _selectedDate != null && !_isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ENTER YOUR FATE'),
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
                decoration: const InputDecoration(
                  labelText: 'Name / Nickname',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
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
                          ? 'Select Birthday'
                          : DateFormat.yMMMd().format(_selectedDate!)),
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
                                initialTime: _selectedTime,
                              );
                              if (picked != null) {
                                setState(() => _selectedTime = picked);
                              }
                            },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                          _unknownTime ? 'Unknown' : _selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _unknownTime,
                    onChanged: (v) => setState(() => _unknownTime = v ?? false),
                  ),
                  const Text(
                    "I don't know my birth time",
                    style: TextStyle(fontSize: 13, color: AppColors.moonlightGray),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Birth City (optional)',
                  hintText: 'e.g. Seoul, South Korea',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  helperText: 'For your records — timezone hook coming soon',
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Calendar:'),
                  ChoiceChip(
                    label: const Text('Solar'),
                    selected: !_isLunar,
                    // 선택 해제는 무시 — Solar/Lunar 둘 중 하나는 항상 선택돼 있어야 함.
                    onSelected: (val) {
                      if (val) setState(() => _isLunar = false);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Lunar (soon)'),
                    selected: _isLunar,
                    onSelected: null, // 음력 변환 미지원 — 비활성화
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
                      fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: AppColors.cosmicBlack, strokeWidth: 2.5),
                      )
                    : const Text('✨ Find My Destiny ✨'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Free 4-pillar reading. No login required.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.fadedSilver),
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

    setState(() => _isLoading = true);

    try {
      final svc = SajuService();
      // unknownTime 일 때 hour/minute 은 0 으로 전달 — 어차피 saju_service 가 hourPillar 를 만들지 않음.
      final hour = _unknownTime ? 0 : _selectedTime.hour;
      final minute = _unknownTime ? 0 : _selectedTime.minute;
      final result = await svc.calculateSaju(
        year: _selectedDate!.year,
        month: _selectedDate!.month,
        day: _selectedDate!.day,
        hour: hour,
        minute: minute,
        isLunar: _isLunar,
        isMale: true, // gender 미사용 (향후 대운 방향 결정에 활용 예정)
        unknownTime: _unknownTime,
      );

      // 전역 상태에 저장 (router extra 의존 제거)
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
          const SnackBar(
            content: Text("We couldn't read the stars. Please check your inputs and try again."),
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
