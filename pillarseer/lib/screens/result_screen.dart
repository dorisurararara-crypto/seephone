import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/saju_result.dart';

class ResultScreen extends StatelessWidget {
  final SajuResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOUR DESTINY'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildPillarGrid(context),
            const SizedBox(height: 40),
            _buildSummaryCard(context),
            const SizedBox(height: 24),
            ...result.details.map((detail) => _buildDetailCard(context, detail)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share),
              label: const Text('Share My Path'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.spiritIndigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarGrid(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPillarItem(context, 'Hour', result.hourPillar),
        _buildPillarItem(context, 'Day', result.dayPillar),
        _buildPillarItem(context, 'Month', result.monthPillar),
        _buildPillarItem(context, 'Year', result.yearPillar),
      ],
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPillarItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.moonlightGray),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.midnightPurple,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.celestialGold.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                value[0],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.celestialGold),
              ),
              Text(
                value[1],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ghostlyWhite),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.midnightPurple, AppColors.spiritIndigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.celestialGold.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.celestialGold),
          const SizedBox(height: 12),
          Text(
            result.summary,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 500.ms, duration: 500.ms);
  }

  Widget _buildDetailCard(BuildContext context, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        color: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.star_outline, size: 20, color: AppColors.moonlightGray),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  detail,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 1.seconds);
  }
}
