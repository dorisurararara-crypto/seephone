import 'package:flutter/material.dart';
import 'app.dart';
import 'services/today_event_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Round 77 sprint 2 — today_event_pool.json (90 entries) 1회 로드.
  // 실패해도 silent (TodayEventService 내부 try/catch). home/result 의 ko 본문이
  // pool entry 를 우선 사용, 미스 시 6분기 fallback.
  await TodayEventService.ensurePoolLoaded();
  runApp(const PillarSeerApp());
}
