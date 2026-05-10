import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/saju_result.dart';
import '../models/daily_fortune.dart';
import '../services/daily_service.dart';

/// Home (Today's Energy) — mockup 04번. 매일 첫 진입점.
///
/// 풍자: 사용자 사주 + 오늘 일진 → 종합점수 + 4 카테고리 + Lucky 정보 + Bottom Nav 5탭.
class HomeScreen extends StatelessWidget {
  final SajuResult userSaju;

  const HomeScreen({super.key, required this.userSaju});

  @override
  Widget build(BuildContext context) {
    final fortune = DailyService().calculate(userSaju);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Column(
            children: [
              _buildHeader(context),
              _buildDate(context, fortune.date),
              const SizedBox(height: 12),
              _buildMoonDeco(),
              _buildScoreCircle(context, fortune.totalScore),
              _buildQuote(context, fortune.quote),
              _buildCategoryGrid(context, fortune),
              _buildLuckyCard(context, fortune),
              _buildPromoCard(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good evening,',
                style: TextStyle(fontSize: 12, color: AppColors.moonlightGray, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 2),
              Text(
                '${userSaju.dayMasterName}  ✦',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ghostlyWhite,
                ),
              ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none, size: 22, color: AppColors.moonlightGray),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.celestialGold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDate(BuildContext context, DateTime date) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        '${weekdays[date.weekday - 1]} · ${months[date.month - 1]} ${date.day}, ${date.year}',
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.moonlightGray,
          letterSpacing: 2.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMoonDeco() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '✦  ✦  ✦',
        style: TextStyle(fontSize: 12, color: AppColors.celestialGold, letterSpacing: 8),
      ),
    );
  }

  Widget _buildScoreCircle(BuildContext context, int score) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.celestialGold.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7],
        ),
        border: Border.all(color: AppColors.celestialGold.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.celestialGold.withValues(alpha: 0.2),
            blurRadius: 30,
          ),
        ],
      ),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: '$score',
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: AppColors.celestialGold,
              height: 1,
            ),
            children: const [
              TextSpan(
                text: '\n/100',
                style: TextStyle(fontSize: 13, color: AppColors.moonlightGray, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 600.ms).fadeIn();
  }

  Widget _buildQuote(BuildContext context, String quote) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 0, 36, 18),
      child: Text(
        '"$quote"',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.ghostlyWhite,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildCategoryGrid(BuildContext context, DailyFortune f) {
    final cats = [
      {'icon': '💝', 'name': 'Love', 'score': f.loveScore},
      {'icon': '💼', 'name': 'Work', 'score': f.workScore},
      {'icon': '💰', 'name': 'Wealth', 'score': f.wealthScore},
      {'icon': '⚡', 'name': 'Energy', 'score': f.energyScore},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: cats.map((c) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.spiritIndigo.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.celestialGold.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(c['icon'] as String, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(
                    '${c['score']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.celestialGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (c['name'] as String).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.moonlightGray,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLuckyCard(BuildContext context, DailyFortune f) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.spiritIndigo.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.celestialGold.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _luckyRow('🎨  Lucky Color', f.luckyColor),
          _luckyRow('🔢  Lucky Number', '${f.luckyNumber}'),
          _luckyRow('🧭  Lucky Direction', f.luckyDirection),
        ],
      ),
    );
  }

  Widget _luckyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.moonlightGray)),
          Text(value,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.celestialGold,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.celestialGold.withValues(alpha: 0.15),
            AppColors.spiritIndigo.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(color: AppColors.celestialGold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'LIMITED',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.celestialGold,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Your 2026 Annual Reading",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ghostlyWhite,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Discover the 144 hexagrams\nthat shape your year ahead.',
            style: TextStyle(fontSize: 11, color: AppColors.moonlightGray, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int activeIdx) {
    final items = [
      {'icon': '✦', 'name': 'Home'},
      {'icon': '柱', 'name': 'Reading'},
      {'icon': '📜', 'name': 'Reports'},
      {'icon': '🌙', 'name': 'Discover'},
      {'icon': '○', 'name': 'Profile'},
    ];
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.cosmicBlack.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColors.celestialGold.withValues(alpha: 0.15))),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isActive = i == activeIdx;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['icon'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    color: isActive ? AppColors.celestialGold : AppColors.moonlightGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (item['name'] as String).toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.celestialGold : AppColors.moonlightGray,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
