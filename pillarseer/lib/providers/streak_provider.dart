// Pillar Seer — Streak provider.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/streak_service.dart';

class StreakState {
  final int current;
  final int longest;
  final bool celebrate; // 새 날 체크인 시 1회 true
  const StreakState({
    required this.current,
    required this.longest,
    this.celebrate = false,
  });
}

class StreakNotifier extends Notifier<StreakState> {
  @override
  StreakState build() {
    _load();
    return const StreakState(current: 0, longest: 0);
  }

  Future<void> _load() async {
    final r = await StreakService.read();
    state = StreakState(current: r.current, longest: r.longest);
  }

  Future<void> tick() async {
    final r = await StreakService.tick();
    state = StreakState(
      current: r.current,
      longest: r.longest,
      celebrate: r.isNewDay,
    );
  }
}

final streakProvider =
    NotifierProvider<StreakNotifier, StreakState>(StreakNotifier.new);
