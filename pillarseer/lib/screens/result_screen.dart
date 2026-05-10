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
        title: const Text('YOUR LIFE PATH'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _buildPillarGrid(context),
            const SizedBox(height: 32),
            _buildDayMasterCard(context),
            const SizedBox(height: 24),
            _buildElementsBar(context),
            const SizedBox(height: 24),
            _buildCategoryGrid(context),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.lock_open),
              label: const Text('Unlock Full Reading'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.celestialGold,
                foregroundColor: AppColors.midnightPurple,
                minimumSize: const Size(double.infinity, 56),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share, color: AppColors.moonlightGray),
              label: const Text('Share to Story', style: TextStyle(color: AppColors.moonlightGray)),
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
        _buildPillarItem(context, 'Year', result.yearPillar),
        _buildPillarItem(context, 'Month', result.monthPillar),
        _buildPillarItem(context, 'Day', result.dayPillar),
        _buildPillarItem(context, 'Hour', result.hourPillar),
      ],
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPillarItem(BuildContext context, String label, Pillar? pillar) {
    final isNull = pillar == null;
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.moonlightGray,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.midnightPurple.withValues(alpha:0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.celestialGold.withValues(alpha:0.3)),
          ),
          child: Column(
            children: [
              Text(
                isNull ? '?' : pillar.chunGan,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.celestialGold),
              ),
              const SizedBox(height: 2),
              Text(
                isNull ? '?' : pillar.jiJi,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ghostlyWhite),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayMasterCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.celestialGold.withValues(alpha:0.15), AppColors.spiritIndigo.withValues(alpha:0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.celestialGold.withValues(alpha:0.5)),
      ),
      child: Column(
        children: [
          Text(
            '${result.dayMasterName} (${result.day60ji})',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.celestialGold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result.summary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppColors.ghostlyWhite,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 500.ms, duration: 500.ms);
  }

  Widget _buildElementsBar(BuildContext context) {
    final el = result.elements;
    return Column(
      children: [
        _elementRow('🌳', 'Wood', el.wood),
        _elementRow('🔥', 'Fire', el.fire),
        _elementRow('🏔️', 'Earth', el.earth),
        _elementRow('⚙️', 'Metal', el.metal),
        _elementRow('💧', 'Water', el.water),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _elementRow(String icon, String name, int pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(name, style: const TextStyle(fontSize: 11, color: AppColors.moonlightGray)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 6,
                backgroundColor: AppColors.spiritIndigo.withValues(alpha:0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.celestialGold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: AppColors.ghostlyWhite, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final cats = [
      {'icon': '💪', 'title': 'Strength', 'key': 'personality', 'locked': false},
      {'icon': '💝', 'title': 'Love', 'key': 'love', 'locked': false},
      {'icon': '💼', 'title': 'Career', 'key': 'career', 'locked': true},
      {'icon': '💰', 'title': 'Wealth', 'key': 'money', 'locked': true},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: cats.map((c) {
        final locked = c['locked'] as bool;
        final reading = result.categoryReadings[c['key']] ?? '';
        return Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.spiritIndigo.withValues(alpha:locked ? 0.05 : 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.celestialGold.withValues(alpha:locked ? 0.1 : 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c['icon'] as String, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    (c['title'] as String).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: locked
                          ? AppColors.ghostlyWhite.withValues(alpha:0.5)
                          : AppColors.ghostlyWhite,
                    ),
                  ),
                  if (!locked) ...[
                    const SizedBox(height: 6),
                    Text(
                      reading,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9, color: AppColors.moonlightGray, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            if (locked)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.lock, size: 14, color: AppColors.celestialGold),
              ),
          ],
        );
      }).toList(),
    ).animate().fadeIn(delay: 1.seconds);
  }
}
