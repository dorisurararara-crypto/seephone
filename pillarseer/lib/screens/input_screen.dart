import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/saju_service.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController(text: 'Seoul, South Korea');
  DateTime _selectedDate = DateTime(1996, 4, 15);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 30);
  bool _isLunar = false;
  bool _isMale = true;
  bool _isLoading = false;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name / Nickname',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text('${_selectedDate.year}.${_selectedDate.month}.${_selectedDate.day}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (picked != null) {
                        setState(() => _selectedTime = picked);
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Birth City',
                hintText: 'e.g. Seoul, South Korea',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                helperText: 'Used for timezone correction',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Calendar: '),
                ChoiceChip(
                  label: const Text('Solar'),
                  selected: !_isLunar,
                  onSelected: (val) => setState(() => _isLunar = !val),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Lunar'),
                  selected: _isLunar,
                  onSelected: (val) => setState(() => _isLunar = val),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Gender: '),
                ChoiceChip(
                  label: const Text('Male'),
                  selected: _isMale,
                  onSelected: (val) => setState(() => _isMale = val),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Female'),
                  selected: !_isMale,
                  onSelected: (val) => setState(() => _isMale = !val),
                ),
              ],
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.celestialGold,
                foregroundColor: AppColors.cosmicBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: AppColors.cosmicBlack)
                : const Text('✨ Find My Destiny ✨'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    setState(() => _isLoading = true);
    
    final sajuService = SajuService();
    final result = await sajuService.calculateSaju(
      year: _selectedDate.year,
      month: _selectedDate.month,
      day: _selectedDate.day,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      isLunar: _isLunar,
      isMale: _isMale,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      context.push('/result', extra: result);
    }
  }
}
